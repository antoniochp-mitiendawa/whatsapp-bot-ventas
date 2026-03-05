require('dotenv').config();
const { default: makeWASocket, useMultiFileAuthState, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const pino = require('pino');
const fs = require('fs');
const axios = require('axios'); // Librería para hablar con Google

const CONFIG = {
    url_sheets: process.env.URL_SHEETS,
    numero_telefono: process.env.PAIRING_NUMBER,
    archivo_datos: 'datos_tienda.json' // AQUÍ SE GUARDARÁ TODO
};

// --- FUNCIÓN PARA DESCARGAR Y GUARDAR LOCALMENTE ---
async function actualizarDatosLocales() {
    try {
        console.log("📥 Consultando Google Sheets por primera vez...");
        // Pedimos a la URL de Google que nos de todos los datos
        const respuesta = await axios.get(CONFIG.url_sheets + "?accion=leerTodo");
        
        if (respuesta.data) {
            // Guardamos la información en el archivo local datos_tienda.json
            fs.writeFileSync(CONFIG.archivo_datos, JSON.stringify(respuesta.data, null, 2));
            console.log("✅ Memoria local actualizada. Datos guardados en:", CONFIG.archivo_datos);
            return respuesta.data;
        }
    } catch (error) {
        console.error("❌ Error al consultar Google Sheets:", error.message);
        // Si falla, intentamos leer lo que ya teníamos guardado antes
        if (fs.existsSync(CONFIG.archivo_datos)) {
            console.log("⚠️ Usando copia local antigua para continuar.");
            return JSON.parse(fs.readFileSync(CONFIG.archivo_datos));
        }
    }
    return null;
}

// --- FUNCIÓN PRINCIPAL DEL BOT ---
async function iniciarWhatsApp() {
    // 1. Antes de conectar a WhatsApp, llenamos la memoria local
    const datosTienda = await actualizarDatosLocales();
    
    if (!datosTienda) {
        console.log("❌ No se pudieron obtener datos. Revisa tu URL de Google Sheets.");
        // No detenemos el bot, pero avisamos.
    }

    const { state, saveCreds } = await useMultiFileAuthState('sesion_whatsapp');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        printQRInTerminal: false,
        auth: state,
        logger: pino({ level: 'silent' }),
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // Lógica de Pairing Code
    if (!sock.authState.creds.registered) {
        const numero = CONFIG.numero_telefono;
        setTimeout(async () => {
            try {
                const codigo = await sock.requestPairingCode(numero);
                console.log("\n🔐 TU CÓDIGO DE VINCULACIÓN: " + codigo + "\n");
            } catch (e) { console.error("Error al pedir código", e); }
        }, 3000);
    }

    sock.ev.on('creds.update', saveCreds);
    sock.ev.on('connection.update', (up) => {
        if (up.connection === 'open') console.log('\n✅ BOT CONECTADO Y CON DATOS LOCALES');
        if (up.connection === 'close') iniciarWhatsApp();
    });
}

iniciarWhatsApp();
