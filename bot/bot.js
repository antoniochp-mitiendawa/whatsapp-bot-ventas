require('dotenv').config();
const fs = require('fs');
const axios = require('axios');
const path = require('path');

// ============================================
// CONFIGURACIÓN
// ============================================
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    archivo_memoria: 'datos_tienda.json',
    carpeta_logs: './logs'
};

// Crear carpeta de logs si no existe
if (!fs.existsSync(CONFIG.carpeta_logs)) {
    fs.mkdirSync(CONFIG.carpeta_logs, { recursive: true });
}

// ============================================
// FUNCIÓN PARA GUARDAR LOG
// ============================================
function guardarLog(texto) {
    const fecha = new Date().toISOString().split('T')[0];
    const logFile = path.join(CONFIG.carpeta_logs, `${fecha}.log`);
    const hora = new Date().toLocaleTimeString();
    const linea = `[${hora}] ${texto}`;
    
    fs.appendFileSync(logFile, linea + '\n');
    console.log(`📝 ${texto}`);
}

// ============================================
// FUNCIÓN PARA SINCRONIZAR DATOS CON GOOGLE SHEETS
// ============================================
async function sincronizarDatos() {
    try {
        console.log("📥 Sincronizando con Google Sheets...");
        
        // Usar la acción obtener_todo de la Web App
        const response = await axios.get(`${CONFIG.url_sheets}?accion=obtener_todo`);
        
        if (response.data && response.data.status === 'success') {
            const data = response.data.data;
            
            // Guardar en archivo local
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(data, null, 2));
            
            console.log("✅ Datos sincronizados correctamente");
            console.log(`   • Empresa: ${data.empresa?.nombre || 'No configurada'}`);
            console.log(`   • Productos: ${data.productos?.length || 0}`);
            console.log(`   • Asesores: ${data.asesores?.length || 0}`);
            
            return data;
        } else {
            console.log("⚠️ Error en respuesta:", response.data?.mensaje || 'Respuesta vacía');
        }
    } catch (error) {
        console.log("⚠️ Error conectando con Sheets, usando caché local:", error.message);
        
        // Si falla, intentar cargar desde archivo local
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return null;
}

// ============================================
// FUNCIÓN PARA OBTENER DATOS LOCALES (SIN CONSULTAR SHEETS)
// ============================================
function obtenerDatosLocales() {
    try {
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    } catch (error) {
        guardarLog(`Error leyendo caché local: ${error.message}`);
    }
    return { empresa: {}, productos: [], asesores: [] };
}

// ============================================
// FUNCIÓN PARA ASIGNAR ASESOR (rotación)
// ============================================
async function asignarAsesor() {
    const datos = obtenerDatosLocales();
    
    if (!datos.asesores || datos.asesores.length === 0) {
        return null;
    }
    
    // Filtrar asesores activos
    const activos = datos.asesores.filter(a => a.Activo === 'SI');
    if (activos.length === 0) return null;
    
    // Ordenar por los que menos atendidos tienen hoy
    activos.sort((a, b) => (a['Atendidos Hoy'] || 0) - (b['Atendidos Hoy'] || 0));
    const asesor = activos[0];
    
    // Actualizar conteo en Google Sheets (opcional)
    try {
        await axios.get(`${CONFIG.url_sheets}?accion=actualizar_asesor&id=${asesor.ID}&atendidos=${(asesor['Atendidos Hoy'] || 0) + 1}`);
    } catch (e) {
        guardarLog(`⚠️ No se pudo actualizar conteo de asesor: ${e.message}`);
    }
    
    return asesor;
}

// ============================================
// FUNCIÓN PRINCIPAL - SOLO SINCRONIZACIÓN
// ============================================
async function iniciar() {
    console.log("======================================");
    console.log("🤖 BOT DE VENTAS - GESTOR DE DATOS");
    console.log("======================================");
    
    // Sincronizar datos al iniciar
    const datos = await sincronizarDatos();
    
    if (!datos) {
        console.log("❌ No se pudieron cargar los datos. Verifica tu URL de Sheets.");
        process.exit(1);
    }
    
    console.log("\n✅ Datos locales actualizados");
    console.log("📁 Archivo: datos_tienda.json");
    console.log("\n📝 El bot de WhatsApp (Baileys.cpp) usará estos datos localmente.");
    console.log("📱 Para iniciar el bot con Baileys.cpp, ejecuta:");
    console.log("   cd ~/whatsapp-bot-ventas/Baileys.cpp");
    console.log("   yarn example");
    console.log("\n🔄 Este script se actualizará automáticamente con Sheets");
    console.log("   cada vez que lo ejecutes.");
    console.log("======================================\n");
    
    // Programar actualización cada 12 horas (opcional)
    // Esto requeriría node-cron, pero por ahora lo dejamos manual
}

// ============================================
// MANEJO DE CIERRE
// ============================================
process.on('SIGINT', () => {
    console.log('\n\n👋 Cerrando gestor de datos...');
    process.exit(0);
});

// ============================================
// INICIAR
// ============================================
iniciar().catch(error => {
    console.log('❌ Error fatal:', error);
});
