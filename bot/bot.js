require('dotenv').config();
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    DisconnectReason, 
    fetchLatestBaileysVersion, 
    makeCacheableSignalKeyStore 
} = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const pino = require('pino');
const readline = require('readline');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

// Configuración inicial basada en tus archivos
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    carpeta_sesion: 'sesion_whatsapp',
    modelo_ia: process.env.OLLAMA_MODEL || 'llama3.2:1b'
};

// Crear carpeta de sesión si no existe
if (!fs.existsSync(CONFIG.carpeta_sesion)) {
    fs.mkdirSync(CONFIG.carpeta_sesion);
}

// Función para pedir número si no existe en .env
function pedirNumeroSilencioso() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
        console.log('\n====================================');
        console.log('📱 CONFIGURACIÓN DE NÚMERO');
        console.log('====================================');
        rl.question('📱 Introduce tu número (ej: 5215512345678): ', (numero) => {
            rl.close();
            resolve(numero.trim());
        });
    });
}

async function iniciarWhatsApp() {
    const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        printQRInTerminal: false, // Desactivado para usar Pairing Code
        auth: {
            creds: state.creds,
            keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' })),
        },
        logger: pino({ level: 'silent' }),
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // LÓGICA DE EMPAREJAMIENTO (PAIRING CODE)
    if (!sock.authState.creds.registered) {
        let numero = CONFIG.numero_telefono;
        
        if (!numero) {
            numero = await pedirNumeroSilencioso();
        }

        console.log(`\n🔄 Solicitando código de vinculación para: ${numero}...`);
        
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
                console.log('\n====================================');
                console.log('🔐 CÓDIGO DE VINCULACIÓN:');
                console.log(`      ${codigo}`);
                console.log('====================================');
                console.log('1. Abre WhatsApp en tu celular');
                console.log('2. Dispositivos vinculados > Vincular con número');
                console.log('3. Ingresa el código de arriba\n');
            } catch (error) {
                console.error('❌ Error al generar pairing code:', error.message);
            }
        }, 3000);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect.error instanceof Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (shouldReconnect) iniciarWhatsApp();
        } else if (connection === 'open') {
            console.log('\n✅ ¡WhatsApp conectado exitosamente!');
            console.log('🔗 Conectado a Sheets:', CONFIG.url_sheets);
        }
    });

    // Escuchar mensajes
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;
        const msg = messages[0];
        if (!msg.message || msg.key.fromMe) return;

        const jid = msg.key.remoteJid;
        const texto = msg.message.conversation || msg.message.extendedTextMessage?.text;

        if (texto) {
            console.log(`📩 Mensaje de ${jid}: ${texto}`);
            // Aquí puedes integrar la llamada a axios para tu Google Sheets
        }
    });
}

iniciarWhatsApp().catch(err => console.error("Error global:", err));
