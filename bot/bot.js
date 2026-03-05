require('dotenv').config();
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    DisconnectReason, 
    fetchLatestBaileysVersion, 
    makeCacheableSignalKeyStore 
} = require('@whiskeysockets/baileys');
const pino = require('pino');
const fs = require('fs');
const axios = require('axios');
const { Boom } = require('@hapi/boom');

const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    archivo_memoria: 'datos_tienda.json',
    carpeta_sesion: 'sesion_whatsapp',
    ollama_url: 'http://localhost:11434/api/generate',
    modelo: 'llama3.2:1b'
};

// ============================================
// FUNCIÓN CORREGIDA PARA SINCRONIZAR DATOS
// ============================================
async function sincronizarDatos() {
    try {
        console.log("📥 Sincronizando con Google Sheets...");
        
        // Usar la acción correcta: obtener_todo (existe en tu Web App)
        const response = await axios.get(`${CONFIG.url_sheets}?accion=obtener_todo`);
        
        if (response.data && response.data.status === 'success') {
            // Guardar en archivo local
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data.data, null, 2));
            console.log("✅ Datos sincronizados correctamente");
            console.log(`   • Empresa: ${response.data.data.empresa?.nombre || 'No configurada'}`);
            console.log(`   • Productos: ${response.data.data.productos?.length || 0}`);
            console.log(`   • Asesores: ${response.data.data.asesores?.length || 0}`);
            return response.data.data;
        } else {
            console.log("⚠️ Error en respuesta:", response.data?.mensaje || 'Respuesta vacía');
        }
    } catch (error) {
        console.log("⚠️ Error conectando con Sheets, usando caché local:", error.message);
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return null;
}

// ============================================
// FUNCIÓN CORREGIDA PARA PROCESAR CON IA
// ============================================
async function procesarConIA(texto, datos) {
    try {
        // Construir prompt con TODA la información de la hoja
        let prompt = "Eres un asistente de ventas profesional y amable.\n\n";
        
        // INFORMACIÓN DE LA EMPRESA
        if (datos.empresa) {
            prompt += "=== INFORMACIÓN DE LA EMPRESA ===\n";
            for (let [key, value] of Object.entries(datos.empresa)) {
                if (value && key !== 'prompt_sistema') {
                    prompt += `${key}: ${value}\n`;
                }
            }
            prompt += "\n";
        }
        
        // PROMPT DE SISTEMA (personalizado)
        if (datos.empresa?.prompt_sistema) {
            prompt += `=== INSTRUCCIONES ESPECIALES ===\n${datos.empresa.prompt_sistema}\n\n`;
        }
        
        // PRODUCTOS DISPONIBLES
        if (datos.productos && datos.productos.length > 0) {
            prompt += "=== PRODUCTOS DISPONIBLES ===\n";
            datos.productos.forEach(p => {
                if (p.Activo === 'SI') {
                    prompt += `• ${p.Nombre} (${p.Categoría}): ${p.Precio} | Stock: ${p.Stock}\n`;
                    if (p.Descripción) prompt += `  Descripción: ${p.Descripción}\n`;
                }
            });
            prompt += "\n";
        }
        
        // ASESORES HUMANOS
        if (datos.asesores && datos.asesores.length > 0) {
            const activos = datos.asesores.filter(a => a.Activo === 'SI');
            prompt += `=== ASESORES HUMANOS ===\n`;
            prompt += `Tenemos ${activos.length} asesores disponibles.\n`;
            prompt += `Si el cliente solicita hablar con un humano, responde: "${datos.empresa?.mensaje_asignacion || 'Te contactaré con un asesor en breve'}"\n\n`;
        }
        
        // REGLAS DE RESPUESTA
        prompt += "=== REGLAS DE RESPUESTA ===\n";
        prompt += "1. Sé amable y profesional\n";
        prompt += "2. Si preguntan por productos, menciona precio y disponibilidad\n";
        prompt += "3. Si piden un asesor, ofrece contactar a uno humano\n";
        prompt += "4. Si hay quejas, deriva al gerente\n";
        prompt += "5. Responde en el mismo idioma del cliente\n";
        prompt += "6. Mantén respuestas breves (máximo 3 oraciones)\n\n";
        
        prompt += `=== CONVERSACIÓN ===\n`;
        prompt += `Cliente: ${texto}\n`;
        prompt += `Asistente: `;

        // Consultar Ollama
        const res = await axios.post(CONFIG.ollama_url, {
            model: CONFIG.modelo,
            prompt: prompt,
            stream: false,
            options: {
                temperature: 0.7,
                max_tokens: 250
            }
        });
        
        return res.data.response;
    } catch (e) {
        console.log("❌ Error en IA:", e.message);
        return "Lo siento, tengo problemas técnicos. Un asesor humano te atenderá en breve.";
    }
}

// ============================================
// FUNCIÓN PARA ASIGNAR ASESOR (rotación)
// ============================================
async function asignarAsesor(datos) {
    if (!datos.asesores) return null;
    
    const activos = datos.asesores.filter(a => a.Activo === 'SI');
    if (activos.length === 0) return null;
    
    // Buscar el que menos atendidos tiene hoy
    activos.sort((a, b) => (a['Atendidos Hoy'] || 0) - (b['Atendidos Hoy'] || 0));
    const asesor = activos[0];
    
    // Actualizar conteo (aquí podrías llamar a la Web App para actualizar)
    try {
        await axios.get(`${CONFIG.url_sheets}?accion=actualizar_asesor&id=${asesor.ID}&atendidos=${(asesor['Atendidos Hoy'] || 0) + 1}`);
    } catch (e) {
        console.log("⚠️ No se pudo actualizar conteo de asesor");
    }
    
    return asesor;
}

// ============================================
// FUNCIÓN PRINCIPAL
// ============================================
async function iniciarBot() {
    console.log("======================================");
    console.log("🤖 BOT DE VENTAS CON IA");
    console.log("======================================");
    
    // Sincronizar datos al iniciar
    const memoriaLocal = await sincronizarDatos();
    
    if (!memoriaLocal) {
        console.log("❌ No se pudieron cargar los datos. Verifica tu URL de Sheets.");
        process.exit(1);
    }

    const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        printQRInTerminal: false,
        auth: {
            creds: state.creds,
            keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' })),
        },
        logger: pino({ level: 'silent' }),
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // Si es primera vez, mostrar código de vinculación
    if (!sock.authState.creds.registered) {
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(CONFIG.numero_telefono);
                console.log('\n======================================');
                console.log('🔐 CÓDIGO DE VINCULACIÓN');
                console.log('======================================');
                console.log(`   ${codigo}`);
                console.log('======================================\n');
                console.log('1. Abre WhatsApp en tu teléfono');
                console.log('2. Ve a 3 puntos → Dispositivos vinculados');
                console.log('3. Toca "Vincular con número de teléfono"');
                console.log('4. Ingresa el código de arriba\n');
            } catch (error) {
                console.log('❌ Error generando código:', error.message);
            }
        }, 3000);
    }

    // Guardar credenciales
    sock.ev.on('creds.update', saveCreds);

    // Manejar conexión
    sock.ev.on('connection.update', (up) => {
        if (up.connection === 'open') {
            console.log('\n✅ BOT EN LÍNEA - LISTO PARA ATENDER');
            console.log('======================================\n');
        }
        if (up.connection === 'close') {
            const shouldReconnect = new Boom(up.lastDisconnect?.error)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (shouldReconnect) {
                console.log('🔄 Reconectando...');
                iniciarBot();
            } else {
                console.log('🚫 Sesión cerrada. Borra la carpeta sesion_whatsapp');
            }
        }
    });

    // Procesar mensajes entrantes
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify' || !messages[0].message || messages[0].key.fromMe) return;
        
        const jid = messages[0].key.remoteJid;
        // Ignorar mensajes de grupos
        if (jid.includes('@g.us')) return;
        
        const msgText = messages[0].message.conversation || 
                       messages[0].message.extendedTextMessage?.text || 
                       '';

        if (msgText && memoriaLocal) {
            console.log(`\n📩 Mensaje de ${jid.split('@')[0]}: "${msgText}"`);
            
            // Detectar si pide asesor
            const textoLower = msgText.toLowerCase();
            if (textoLower.includes('asesor') || textoLower.includes('humano') || textoLower.includes('persona')) {
                const asesor = await asignarAsesor(memoriaLocal);
                if (asesor) {
                    const mensaje = memoriaLocal.empresa?.mensaje_asignacion || 'Te contactaré con un asesor';
                    const mensajeFinal = mensaje.replace('{nombre}', asesor.Nombre).replace('{telefono}', asesor.Teléfono);
                    await sock.sendMessage(jid, { text: mensajeFinal });
                    console.log(`✅ Asesor asignado: ${asesor.Nombre}`);
                    return;
                }
            }
            
            // Procesar con IA
            console.log("🤔 Procesando con IA...");
            const respuesta = await procesarConIA(msgText, memoriaLocal);
            await sock.sendMessage(jid, { text: respuesta });
            console.log(`✅ Respuesta enviada`);
        }
    });
}

// Iniciar el bot
iniciarBot().catch(error => {
    console.log('❌ Error fatal:', error);
});
