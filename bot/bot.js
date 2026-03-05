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
const fs = require('fs');
const path = require('path');
const axios = require('axios');

// Configuración cargada desde el .env que creó el instalador
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    carpeta_sesion: 'sesion_whatsapp'
};

// Asegurar que exista la carpeta de sesión
if (!fs.existsSync(CONFIG.carpeta_sesion)) {
    fs.mkdirSync(CONFIG.carpeta_sesion);
}

async function iniciarWhatsApp() {
    const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        printQRInTerminal: false, // Usaremos Pairing Code
        auth: {
            creds: state.creds,
            keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' })),
        },
        logger: pino({ level: 'silent' }),
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // LÓGICA DE EMPAREJAMIENTO AUTOMÁTICO
    if (!sock.authState.creds.registered) {
        const numero = CONFIG.numero_telefono;
        
        if (!numero) {
            console.log('❌ Error: No hay número de teléfono en el archivo .env');
            process.exit(1);
        }

        console.log(`\n🔄 Solicitando código de vinculación para: ${numero}...`);
        
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
                console.log('\n====================================');
                console.log('🔐 TU CÓDIGO DE VINCULACIÓN ES:');
                console.log(`      >  ${codigo}  <`);
                console.log('====================================');
                console.log('1. Abre WhatsApp en tu celular.');
                console.log('2. Ve a Dispositivos vinculados > Vincular con número.');
                console.log('3. Escribe el código de arriba.\n');
            } catch (error) {
                console.error('❌ Error al generar el código:', error.message);
            }
        }, 3000);
    }

    // Guardar credenciales cuando se actualicen
    sock.ev.on('creds.update', saveCreds);

    // Manejo de conexión
    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'close') {
            const debeReconectar = (lastDisconnect.error instanceof Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (debeReconectar) {
                console.log('🔄 Reconectando...');
                iniciarWhatsApp();
            }
        } else if (connection === 'open') {
            console.log('\n✅ ¡BOT CONECTADO Y LISTO!');
            console.log('🔗 Sincronizado con Sheets:', CONFIG.url_sheets);
        }
    });

    // Escuchar mensajes entrantes
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;
        const msg = messages[0];
        if (!msg.message || msg.key.fromMe) return;

        const jid = msg.key.remoteJid;
        const textoEscrito = msg.message.conversation || msg.message.extendedTextMessage?.text;

        if (textoEscrito) {
            console.log(`📩 Mensaje de [${jid}]: ${textoEscrito}`);
            
            // Ejemplo de respuesta automática para probar conexión
            if (textoEscrito.toLowerCase() === 'hola') {
                await sock.sendMessage(jid, { text: '¡Hola! Estoy procesando tu solicitud con mi sistema de ventas.' });
            }
        }
    });
}

// Arrancar el proceso
iniciarWhatsApp().catch(err => console.error("Error crítico:", err));
