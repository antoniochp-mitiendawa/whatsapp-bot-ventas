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

// --- CONFIGURACIÓN ---
const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    archivo_memoria: 'datos_tienda.json',
    carpeta_sesion: 'sesion_whatsapp'
};

// --- PASO 1: LA MEMORIA LOCAL ---
// Esta función descarga todo de Sheets y lo guarda en el teléfono
async function sincronizarMemoriaLocal() {
    try {
        console.log("📥 [Sincronizador] Consultando Google Sheets...");
        
        // Llamamos a la URL de Google Sheets con el parámetro accion=leerTodo
        const response = await axios.get(`${CONFIG.url_sheets}?accion=leerTodo`);
        
        if (response.data) {
            // Guardamos físicamente el archivo en Termux
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(response.data, null, 2));
            console.log("✅ [Sincronizador] Memoria local creada con éxito.");
            return response.data;
        }
    } catch (error) {
        console.log("⚠️ [Sincronizador] No se pudo conectar a Sheets. Buscando copia local...");
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            const datosLocales = JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
            console.log("📂 [Sincronizador] Copia local encontrada y cargada.");
            return datosLocales;
        } else {
            console.log("❌ [Sincronizador] Error: No hay datos locales ni conexión.");
            return null;
        }
    }
}

// --- CONEXIÓN A WHATSAPP ---
async function iniciarWhatsApp() {
    // LLAMADA AL PASO 1: Antes de cualquier cosa, cargamos los datos
    const memoriaLocal = await sincronizarMemoriaLocal();

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
        const numero = CONFIG.numero_telefono;
        if (!numero) {
            console.log("❌ Error: PAIRING_NUMBER no definido en el instalador.");
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
            console.log('\n✅ BOT CONECTADO');
            console.log('📊 DATOS CARGADOS:', memoriaLocal ? 'SI' : 'NO');
        } else if (connection === 'close') {
            const error = new Boom(lastDisconnect?.error)?.output?.statusCode;
            if (error !== DisconnectReason.loggedOut) iniciarWhatsApp();
        }
    });

    // ESCUCHA DE MENSAJES (Aquí conectaremos a Ollama en el siguiente paso)
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;
        const msg = messages[0];
        if (!msg.message || msg.key.fromMe) return;

        console.log("📩 Mensaje recibido. Procesando con memoria local...");
        // AQUÍ IRÁ LA LÓGICA DE OLLAMA EN EL PASO 2
    });
}

iniciarWhatsApp().catch(err => console.error("Error global:", err));
