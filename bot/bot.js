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

// Configuración cargada desde el instalador (.env)
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    carpeta_sesion: 'sesion_whatsapp'
}; [cite: 4, 79]

if (!fs.existsSync(CONFIG.carpeta_sesion)) {
    fs.mkdirSync(CONFIG.carpeta_sesion);
}

function pedirNumeroManual() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
        console.log('\n====================================');
        console.log('📱 CONFIGURACIÓN INICIAL');
        console.log('====================================');
        rl.question('📱 Introduce tu número (sin +): ', (numero) => {
            rl.close();
            resolve(numero.trim());
        });
    });
} [cite: 1, 2]

async function iniciarWhatsApp() {
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

    // Lógica de Pairing Code automática
    if (!sock.authState.creds.registered) {
        let numero = CONFIG.numero_telefono; [cite: 4]
        
        if (!numero) {
            numero = await pedirNumeroManual();
        }

        console.log(`\n🔄 Solicitando código para ${numero}...\n`);
        
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
                console.log('\n====================================');
                console.log('🔐 CÓDIGO DE VINCULACIÓN');
                console.log('====================================');
                console.log(`   ${codigo}`);
                console.log('====================================\n');
                console.log('1. Abre WhatsApp');
                console.log('2. Dispositivos vinculados > Vincular con número');
                console.log('3. Ingresa el código\n');
            } catch (error) {
                console.log('❌ Error:', error.message);
            }
        }, 3000); [cite: 5, 6]
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect.error instanceof Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (shouldReconnect) iniciarWhatsApp();
        } else if (connection === 'open') {
            console.log('\n✅ ¡Conexión establecida!');
        }
    });
}

iniciarWhatsApp().catch(err => console.error("Error global:", err));
