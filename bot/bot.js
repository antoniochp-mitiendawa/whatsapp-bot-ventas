require('dotenv').config();
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { exec } = require('child_process');
const readline = require('readline');
const pino = require('pino');

// ============================================
// CONFIGURACIÓN
// ============================================
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    carpeta_sesion: './sesion_whatsapp',
    archivo_memoria: './datos_tienda.json',
    carpeta_logs: './logs',
    modelo_path: '../llama.cpp/models/tinyllama-1.1b-chat.Q4_K_M.gguf',
    llama_cpp_path: '../llama.cpp'
};

// Crear carpetas necesarias
if (!fs.existsSync(CONFIG.carpeta_sesion)) fs.mkdirSync(CONFIG.carpeta_sesion);
if (!fs.existsSync(CONFIG.carpeta_logs)) fs.mkdirSync(CONFIG.carpeta_logs);

// ============================================
// FUNCIÓN PARA GUARDAR LOGS
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
// FUNCIÓN PARA SINCRONIZAR DATOS CON SHEETS
// ============================================
async function sincronizarDatos() {
    try {
        guardarLog("📥 Sincronizando con Google Sheets...");
        const response = await axios.get(`${CONFIG.url_sheets}?accion=obtener_todo`);
        
        if (response.data && response.data.status === 'success') {
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data.data, null, 2));
            guardarLog("✅ Datos sincronizados correctamente");
            return response.data.data;
        }
    } catch (error) {
        guardarLog(`⚠️ Error conectando con Sheets: ${error.message}`);
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return { empresa: {}, productos: [], asesores: [] };
}

// ============================================
// FUNCIÓN PARA CONSTRUIR PROMPT CON DATOS LOCALES
// ============================================
function construirPrompt(texto, datos) {
    let prompt = "Eres un asistente de ventas amable y profesional. Responde de forma breve y útil.\n\n";
    
    if (datos.empresa) {
        prompt += "=== INFORMACIÓN DE LA EMPRESA ===\n";
        for (let [key, value] of Object.entries(datos.empresa)) {
            if (value && key !== 'prompt_sistema') {
                prompt += `${key}: ${value}\n`;
            }
        }
        prompt += "\n";
    }
    
    if (datos.empresa?.prompt_sistema) {
        prompt += `=== INSTRUCCIONES ESPECIALES ===\n${datos.empresa.prompt_sistema}\n\n`;
    }
    
    if (datos.productos && datos.productos.length > 0) {
        prompt += "=== PRODUCTOS DISPONIBLES ===\n";
        datos.productos.forEach(p => {
            if (p.Activo === 'SI') {
                prompt += `• ${p.Nombre}: ${p.Precio} | Stock: ${p.Stock}\n`;
                if (p.Descripción) prompt += `  Descripción: ${p.Descripción}\n`;
            }
        });
        prompt += "\n";
    }
    
    prompt += `=== CONVERSACIÓN ===\n`;
    prompt += `Cliente: ${texto}\n`;
    prompt += `Asistente: `;
    
    return prompt;
}

// ============================================
// FUNCIÓN PARA CONSULTAR TINYLLAMA
// ============================================
async function consultarTinyLlama(prompt) {
    return new Promise((resolve, reject) => {
        const comando = `cd ${CONFIG.llama_cpp_path} && ./main -m ${CONFIG.modelo_path} -f /tmp/prompt.txt -n 150 --temp 0.7 --ctx-size 512 --repeat-penalty 1.1`;
        
        fs.writeFileSync('/tmp/prompt.txt', prompt);
        
        exec(comando, { timeout: 30000 }, (error, stdout, stderr) => {
            if (error) {
                reject(error);
            } else {
                // Extraer la respuesta (eliminar el prompt)
                const respuesta = stdout.replace(prompt, '').trim().split('\n')[0];
                resolve(respuesta || "Lo siento, no pude procesar tu solicitud.");
            }
        });
    });
}

// ============================================
// FUNCIÓN PARA ASIGNAR ASESOR
// ============================================
async function asignarAsesor(datos) {
    if (!datos.asesores) return null;
    
    const activos = datos.asesores.filter(a => a.Activo === 'SI');
    if (activos.length === 0) return null;
    
    activos.sort((a, b) => (a['Atendidos Hoy'] || 0) - (b['Atendidos Hoy'] || 0));
    const asesor = activos[0];
    
    try {
        await axios.get(`${CONFIG.url_sheets}?accion=actualizar_asesor&id=${asesor.ID}&atendidos=${(asesor['Atendidos Hoy'] || 0) + 1}`);
    } catch (e) {
        guardarLog(`⚠️ No se pudo actualizar conteo de asesor`);
    }
    
    return asesor;
}

// ============================================
// FUNCIÓN PARA PEDIR NÚMERO (PRIMERA VEZ)
// ============================================
function pedirNumero() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    
    return new Promise((resolve) => {
        console.log('\n======================================');
        console.log('📱 CONFIGURACIÓN INICIAL - PRIMERA VEZ');
        console.log('======================================');
        console.log(`Número configurado en .env: ${CONFIG.numero_telefono}`);
        console.log('Si deseas usar otro número, escríbelo ahora.');
        console.log('Presiona Enter para usar el configurado.');
        console.log('======================================\n');
        
        rl.question('📱 NÚMERO (con código de país, sin +): ', (numero) => {
            rl.close();
            if (numero.trim() === '') {
                resolve(CONFIG.numero_telefono);
            } else {
                resolve(numero.trim());
            }
        });
    });
}

// ============================================
// FUNCIÓN PRINCIPAL
// ============================================
async function iniciarBot() {
    console.log('======================================');
    console.log('🤖 BOT DE VENTAS CON TINYLLAMA');
    console.log('======================================\n');

    // Sincronizar datos al iniciar
    const datosLocales = await sincronizarDatos();

    const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        auth: state,
        printQRInTerminal: false, // Importante: NO QR
        logger: pino({ level: 'silent' }),
        browser: ["Bot Ventas", "Chrome", "1.0.0"],
        syncFullHistory: false
    });

    // Si es primera vez, usar pairing
    if (!sock.authState.creds.registered) {
        const numero = await pedirNumero();
        
        console.log(`\n🔄 Solicitando código para ${numero}...\n`);
        
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
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

    // Evento de conexión
    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === 'open') {
            console.log('\n✅ BOT CONECTADO - LISTO PARA ATENDER');
            console.log('======================================\n');
            guardarLog('Conexión exitosa');
        }

        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect?.error instanceof Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (shouldReconnect) {
                guardarLog('🔄 Reconectando...');
                setTimeout(() => iniciarBot(), 5000);
            } else {
                guardarLog('🚫 Sesión cerrada. Borra la carpeta sesion_whatsapp');
            }
        }
    });

    // Guardar credenciales
    sock.ev.on('creds.update', saveCreds);

    // Procesar mensajes
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify' || !messages[0].message || messages[0].key.fromMe) return;
        
        const jid = messages[0].key.remoteJid;
        if (jid.includes('@g.us')) return; // Ignorar grupos
        
        const texto = messages[0].message.conversation || 
                     messages[0].message.extendedTextMessage?.text || '';
        
        if (!texto) return;

        guardarLog(`📩 Mensaje de ${jid.split('@')[0]}: "${texto}"`);

        // Verificar si pide asesor
        const textoLower = texto.toLowerCase();
        if (textoLower.includes('asesor') || textoLower.includes('humano') || textoLower.includes('persona')) {
            const asesor = await asignarAsesor(datosLocales);
            if (asesor) {
                const mensaje = datosLocales.empresa?.mensaje_asignacion || 'Te contactaré con un asesor en breve.';
                const mensajeFinal = mensaje.replace('{nombre}', asesor.Nombre || '').replace('{telefono}', asesor.Teléfono || '');
                await sock.sendMessage(jid, { text: mensajeFinal });
                guardarLog(`✅ Asesor asignado: ${asesor.Nombre}`);
                return;
            }
        }

        // Procesar con TinyLlama
        guardarLog("🤔 Procesando con IA...");
        
        try {
            const prompt = construirPrompt(texto, datosLocales);
            const respuesta = await consultarTinyLlama(prompt);
            
            await sock.sendMessage(jid, { text: respuesta });
            guardarLog(`✅ Respuesta enviada: "${respuesta.substring(0, 50)}..."`);
        } catch (error) {
            guardarLog(`❌ Error en IA: ${error.message}`);
            await sock.sendMessage(jid, { 
                text: 'Lo siento, tengo problemas técnicos. Un asesor humano te atenderá en breve.' 
            });
        }
    });

    console.log('\n📝 Bot listo para recibir mensajes');
    console.log('Presiona CTRL+C para salir\n');
}

// ============================================
// MANEJO DE CIERRE
// ============================================
process.on('SIGINT', () => {
    console.log('\n\n👋 Cerrando bot...');
    guardarLog('Bot cerrado manualmente');
    process.exit(0);
});

// ============================================
// INICIAR
// ============================================
iniciarBot().catch(error => {
    console.log('❌ Error fatal:', error);
    guardarLog(`Error fatal: ${error.message}`);
});
