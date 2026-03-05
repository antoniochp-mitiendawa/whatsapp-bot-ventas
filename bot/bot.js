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

// --- FUNCIÓN DE CARGA ÚNICA DE DATOS ---
async function sincronizarDatos() {
    try {
        console.log("📥 Accediendo a Google Sheets...");
        const response = await axios.get(`${CONFIG.url_sheets}?accion=leerTodo`);
        if (response.data) {
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data, null, 2));
            console.log("✅ Datos guardados en memoria local.");
            return response.data;
        }
    } catch (error) {
        console.log("⚠️ Error de conexión. Intentando usar memoria local...");
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return null;
}

// --- FUNCIÓN PARA HABLAR CON OLLAMA ---
async function procesarConIA(texto, datos) {
    try {
        const contexto = `Empresa: ${JSON.stringify(datos.empresa)}. Productos: ${JSON.stringify(datos.productos)}.`;
        const prompt = `Eres un vendedor. Datos: ${contexto}. Cliente dice: ${texto}. Responde brevemente.`;

        const res = await axios.post(CONFIG.ollama_url, {
            model: CONFIG.modelo,
            prompt: prompt,
            stream: false
        });
        return res.data.response;
    } catch (e) {
        return "Gracias por contactarnos. Un asesor humano te atenderá en breve.";
    }
}

// --- CONEXIÓN WHATSAPP ---
async function iniciarBot() {
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

    if (!sock.authState.creds.registered) {
        setTimeout(async () => {
            const codigo = await sock.requestPairingCode(CONFIG.numero_telefono);
            console.log('\n====================================');
            console.log('🔐 CÓDIGO DE VINCULACIÓN: ' + codigo);
            console.log('====================================\n');
        }, 3000);
    }

    sock.ev.on('creds.update', saveCreds);
    sock.ev.on('connection.update', (up) => {
        if (up.connection === 'open') console.log('✅ BOT EN LÍNEA');
        if (up.connection === 'close') {
            if (new Boom(up.lastDisconnect?.error)?.output?.statusCode !== DisconnectReason.loggedOut) iniciarBot();
        }
    });

    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify' || !messages[0].message || messages[0].key.fromMe) return;
        const jid = messages[0].key.remoteJid;
        const msgText = messages[0].message.conversation || messages[0].message.extendedTextMessage?.text;

        if (msgText && memoriaLocal) {
            console.log(`📩 De ${jid}: ${msgText}`);
            const respuesta = await procesarConIA(msgText, memoriaLocal);
            await sock.sendMessage(jid, { text: respuesta });
        }
    });
}

iniciarBot().catch(err => console.error("Error:", err));
