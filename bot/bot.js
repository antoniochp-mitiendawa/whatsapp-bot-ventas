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

// ============================================
// CONFIGURACIÓN GLOBAL
// ============================================
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    archivo_memoria: 'datos_tienda.json',
    carpeta_sesion: 'sesion_whatsapp',
    ollama_url: 'http://localhost:11434/api/generate',
    modelo: process.env.OLLAMA_MODEL || 'llama3.2:1b'
};

// ============================================
// SISTEMA DE MEMORIA LOCAL (SHEETS)
// ============================================
async function sincronizarDatos() {
    try {
        console.log("📥 Descargando configuración desde Google Sheets...");
        const response = await axios.get(`${CONFIG.url_sheets}?accion=leerTodo`);
        
        if (response.data) {
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data, null, 2));
            console.log("✅ Datos guardados localmente en datos_tienda.json");
            return response.data;
        }
    } catch (error) {
        console.log("⚠️ No se pudo conectar a Sheets. Intentando cargar memoria local...");
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
        console.error("❌ Error: No hay datos disponibles (ni remotos ni locales).");
        return null;
    }
}

// ============================================
// CEREBRO DEL BOT (OLLAMA IA)
// ============================================
async function obtenerRespuestaIA(mensajeCliente, datos) {
    try {
        // Preparamos el contexto con los datos locales
        const empresa = JSON.stringify(datos.empresa || {});
        const productos = JSON.stringify(datos.productos || []);
        
        const promptSystem = `Eres un vendedor experto de la siguiente empresa: ${empresa}. 
        Tus productos son: ${productos}.
        Reglas:
        1. Responde de forma breve y amable.
        2. Usa solo la información proporcionada.
        3. Si el cliente pregunta algo que no está aquí, di que un asesor humano le ayudará pronto.
        Cliente dice: ${mensajeCliente}`;

        const res = await axios.post(CONFIG.ollama_url, {
            model: CONFIG.modelo,
            prompt: promptSystem,
            stream: false
        });

        return res.data.response;
    } catch (e) {
        console.error("❌ Error en Ollama:", e.message);
        return "Gracias por escribir. En un momento un asesor te atenderá personalmente.";
    }
}

// ============================================
// CONEXIÓN PRINCIPAL WHATSAPP
// ============================================
async function iniciarBot() {
    // 1. CARGA DE DATOS ÚNICA AL INICIO
    const memoriaLocal = await sincronizarDatos();

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

    // Vincular por Pairing Code si no hay sesión
    if (!sock.authState.creds.registered) {
        const numero = CONFIG.numero_telefono;
        if (!numero) {
            console.log("❌ Error: No se encontró el número de teléfono en el .env");
            return;
        }

        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
                console.log('\n====================================');
                console.log('🔐 TU CÓDIGO DE VINCULACIÓN:');
                console.log(`      ${codigo}`);
                console.log('====================================\n');
            } catch (err) {
                console.log("❌ Error al generar código:", err.message);
            }
        }, 3000);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'open') {
            console.log('\n✅ BOT CONECTADO Y LISTO PARA VENDER');
        } else if (connection === 'close') {
            const error = new Boom(lastDisconnect?.error)?.output?.statusCode;
            if (error !== DisconnectReason.loggedOut) iniciarBot();
        }
    });

    // ============================================
    // ESCUCHA Y RESPUESTA DE MENSAJES
    // ============================================
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;
        const msg = messages[0];
        if (!msg.message || msg.key.fromMe) return;

        const jid = msg.key.remoteJid;
        const textoCliente = msg.message.conversation || msg.message.extendedTextMessage?.text;

        if (textoCliente && memoriaLocal) {
            console.log(`📩 Mensaje de ${jid}: ${textoCliente}`);
            
            // Procesar con IA usando los datos que cargamos al inicio
            const respuesta = await obtenerRespuestaIA(textoCliente, memoriaLocal);
            
            // Enviar respuesta
            await sock.sendMessage(jid, { text: respuesta });
            console.log(`📤 Respuesta enviada con éxito.`);
        }
    });
}

iniciarBot().catch(err => console.error("Error crítico:", err));
