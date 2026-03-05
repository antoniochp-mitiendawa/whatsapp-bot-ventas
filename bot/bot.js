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
const { exec } = require('child_process');

const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    archivo_memoria: 'datos_tienda.json',
    carpeta_sesion: 'sesion_whatsapp',
    llama_url: 'http://localhost:8080/v1/chat/completions',
    path_llama: '../../../../llama.cpp/build/bin/llama-server',
    path_model: '../../../../llama.cpp/models/model.gguf'
};

// --- AUTO-REPARACIÓN DE IA ---
async function asegurarIA() {
    try {
        await axios.get('http://localhost:8080/health', { timeout: 2000 });
        return true;
    } catch (e) {
        console.log("⚠️ Iniciando cerebro de IA local... (espera 15 seg)");
        exec(`nohup ${CONFIG.path_llama} -m ${CONFIG.path_model} --port 8080 --threads 4 > llama_auto.log 2>&1 &`);
        return false;
    }
}

async function sincronizarDatos() {
    try {
        const response = await axios.get(`${CONFIG.url_sheets}?accion=leerTodo`, { timeout: 5000 });
        if (response.data) {
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data, null, 2));
            return response.data;
        }
    } catch (error) {
        if (fs.existsSync(CONFIG.archivo_memoria)) return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
    }
    return null;
}

async function procesarConIA(texto, datos) {
    try {
        // Verificación rápida antes de preguntar
        await axios.get('http://localhost:8080/health', { timeout: 1000 });
        
        const prompt = `Empresa: ${JSON.stringify(datos.empresa)}. Productos: ${JSON.stringify(datos.productos)}. Responde brevemente a: ${texto}`;
        const res = await axios.post(CONFIG.llama_url, {
            messages: [{ role: "system", content: "Eres un vendedor amable." }, { role: "user", content: prompt }],
            temperature: 0.7
        }, { timeout: 30000 });

        return res.data.choices[0].message.content;
    } catch (e) {
        return "Estamos procesando muchas solicitudes. Un asesor humano te ayudará en breve.";
    }
}

async function iniciarBot() {
    await asegurarIA();
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
        browser: ["Ubuntu", "Chrome", "20.0.04"],
        patchMessageBeforeSending: (message) => {
            const requiresPatch = !!(message.buttonsMessage || message.templateMessage || message.listMessage);
            if (requiresPatch) {
                message = { viewOnceMessage: { message: { messageContextInfo: { deviceListMetadata: {}, deviceListMetadataVersion: 2 }, ...message } } };
            }
            return message;
        }
    });

    if (!sock.authState.creds.registered) {
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(CONFIG.numero_telefono);
                console.log('\n🔐 CÓDIGO: ' + codigo + '\n');
            } catch (e) {}
        }, 5000);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (up) => {
        const { connection, lastDisconnect } = up;
        if (connection === 'open') console.log('✅ BOT EN LÍNEA');
        if (connection === 'close') {
            const code = new Boom(lastDisconnect?.error)?.output?.statusCode;
            // Si el error es "No sessions" o similar, reiniciamos limpio
            if (code !== DisconnectReason.loggedOut) {
                console.log("🔄 Reiniciando conexión por seguridad...");
                setTimeout(() => iniciarBot(), 5000);
            }
        }
    });

    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify' || !messages[0].message || messages[0].key.fromMe) return;
        
        const jid = messages[0].key.remoteJid;
        
        // REGLA: Ignorar grupos para evitar el error "No sessions" y saturación
        if (jid.endsWith('@g.us')) return;

        const msgText = messages[0].message.conversation || messages[0].message.extendedTextMessage?.text;

        if (msgText && memoriaLocal) {
            console.log(`📩 Mensaje privado de ${jid}: ${msgText}`);
            const respuesta = await procesarConIA(msgText, memoriaLocal);
            await sock.sendMessage(jid, { text: respuesta });
        }
    });
}

iniciarBot().catch(err => {
    console.log("⚠️ Error detectado, reiniciando...");
    setTimeout(() => iniciarBot(), 5000);
});
