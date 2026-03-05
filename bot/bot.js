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
    llama_url: process.env.LLAMA_API || 'http://localhost:8080/v1/chat/completions'
};

async function sincronizarDatos() {
    try {
        console.log("📥 Sincronizando memoria local con Sheets...");
        const response = await axios.get(`${CONFIG.url_sheets}?accion=leerTodo`);
        if (response.data) {
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data, null, 2));
            console.log("✅ Memoria local actualizada.");
            return response.data;
        }
    } catch (error) {
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            console.log("📂 Cargando memoria local (Offline).");
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return null;
}

async function procesarConIA(texto, datos) {
    try {
        const empresa = JSON.stringify(datos.empresa || {});
        const productos = JSON.stringify(datos.productos || []);
        const promptSystem = `Eres un vendedor experto. Empresa: ${empresa}. Productos: ${productos}. Responde brevemente al cliente: ${texto}`;

        const res = await axios.post(CONFIG.llama_url, {
            messages: [
                { role: "system", content: "Eres un asistente de ventas amable." },
                { role: "user", content: promptSystem }
            ],
            temperature: 0.7
        });

        return res.data.choices[0].message.content;
    } catch (e) {
        console.error("❌ Error Llama.cpp:", e.message);
        return "Gracias por escribir. En un momento un asesor te atenderá.";
    }
}

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
        if (up.connection === 'open') console.log('✅ BOT EN LÍNEA (Llama.cpp)');
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
            console.log(`📤 Respuesta enviada.`);
        }
    });
}

iniciarBot().catch(err => console.error("Error:", err));
