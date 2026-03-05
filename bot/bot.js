// ============================================
// BOT DE VENTAS PARA WHATSAPP
// Versión: 1.0 - Google Sheets + Ollama
// ============================================

const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const fs = require('fs-extra');
const path = require('path');
const axios = require('axios');
const cron = require('node-cron');
const readline = require('readline');
const pino = require('pino');
require('dotenv').config();

// ============================================
// CONFIGURACIÓN
// ============================================
const CONFIG = {
    carpeta_sesion: './sesion_whatsapp',
    archivo_url: '../url_sheets.txt',
    carpeta_logs: './logs',
    carpeta_multimedia: '/storage/emulated/0/WhatsAppBot',
    tiempo_typing: 2000,
    numero_admin: process.env.WHATSAPP_NUMBER || ''
};

// Crear carpetas necesarias
fs.ensureDirSync(CONFIG.carpeta_logs);
fs.ensureDirSync(CONFIG.carpeta_sesion);
fs.ensureDirSync(CONFIG.carpeta_multimedia);

// ============================================
// LEER URL DE GOOGLE SHEETS
// ============================================
function leerURL() {
    try {
        if (fs.existsSync(CONFIG.archivo_url)) {
            const url = fs.readFileSync(CONFIG.archivo_url, 'utf8').trim();
            console.log('✅ URL de Google Sheets cargada');
            return url;
        }
        console.error('❌ Archivo url_sheets.txt no encontrado');
        return null;
    } catch (error) {
        console.error('❌ Error leyendo URL:', error.message);
        return null;
    }
}

// ============================================
// GUARDAR LOG LOCAL
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
// SIMULAR QUE ESTÁ ESCRIBIENDO
// ============================================
async function simularTyping(sock, id_destino) {
    try {
        await sock.sendPresenceUpdate('composing', id_destino);
        await new Promise(resolve => setTimeout(resolve, CONFIG.tiempo_typing));
        await sock.sendPresenceUpdate('paused', id_destino);
    } catch (error) {}
}

// ============================================
// OBTENER DATOS DE GOOGLE SHEETS
// ============================================
async function obtenerDatosSheets(url) {
    try {
        const response = await axios.get(url);
        return response.data;
    } catch (error) {
        guardarLog(`❌ Error consultando Sheets: ${error.message}`);
        return null;
    }
}

// ============================================
// CONSULTAR OLLAMA
// ============================================
async function consultarOllama(prompt, contexto) {
    try {
        const response = await axios.post('http://localhost:11434/api/generate', {
            model: 'llama3.2:1b',
            prompt: `${contexto}\n\nCliente: ${prompt}\nAsistente:`,
            stream: false,
            options: {
                temperature: 0.7,
                max_tokens: 200
            }
        });
        
        return response.data.response;
    } catch (error) {
        guardarLog(`❌ Error consultando Ollama: ${error.message}`);
        return "Lo siento, no puedo procesar tu solicitud en este momento.";
    }
}

// ============================================
// PEDIR NÚMERO DE TELÉFONO
// ============================================
function pedirNumero() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        rl.question('📱 Introduce tu número (con código de país, sin +): ', (numero) => {
            rl.close();
            resolve(numero.trim());
        });
    });
}

// ============================================
// INICIAR WHATSAPP
// ============================================
async function iniciarWhatsApp() {
    console.log('====================================');
    console.log('🤖 BOT DE VENTAS v1.0');
    console.log('📊 Google Sheets + Ollama');
    console.log('====================================\n');

    const url_sheets = leerURL();
    if (!url_sheets) {
        console.log('❌ No hay URL. Crea archivo url_sheets.txt');
        return;
    }

    try {
        const { version } = await fetchLatestBaileysVersion();
        const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);

        const sock = makeWASocket({
            version,
            auth: state,
            logger: pino({ level: 'silent' }),
            printQRInTerminal: false,
            browser: ['Bot Ventas', 'Chrome', '1.0.0'],
            syncFullHistory: false,
            keepAliveIntervalMs: 25000
        });

        // Primera vez - solicitar código
        if (!sock.authState.creds.registered) {
            console.log('\n📱 PRIMERA CONFIGURACIÓN\n');
            const numero = CONFIG.numero_admin || await pedirNumero();
            
            setTimeout(async () => {
                try {
                    const codigo = await sock.requestPairingCode(numero);
                    console.log('\n====================================');
                    console.log('🔐 CÓDIGO DE VINCULACIÓN:', codigo);
                    console.log('====================================');
                    console.log('1. Abre WhatsApp');
                    console.log('2. 3 puntos → Dispositivos vinculados');
                    console.log('3. Vincular con número');
                    console.log('4. Ingresa el código\n');
                } catch (error) {
                    console.log('❌ Error generando código');
                }
            }, 2000);
        }

        // Evento de conexión
        sock.ev.on('connection.update', (update) => {
            const { connection, lastDisconnect } = update;

            if (connection === 'open') {
                console.log('\n✅ CONECTADO A WHATSAPP\n');
                guardarLog('Conexión exitosa');
            }

            if (connection === 'close') {
                const statusCode = lastDisconnect?.error instanceof Boom ? lastDisconnect.error.output.statusCode : 500;
                const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
                
                if (shouldReconnect) {
                    guardarLog('🔄 Reconectando...');
                    setTimeout(() => iniciarWhatsApp(), 5000);
                } else {
                    guardarLog('🚫 Sesión cerrada. Borra carpeta sesion_whatsapp');
                }
            }
        });

        // Guardar credenciales
        sock.ev.on('creds.update', saveCreds);

        // Evento de mensajes
        sock.ev.on('messages.upsert', async (m) => {
            const mensaje = m.messages[0];
            
            if (!mensaje.key || mensaje.key.fromMe || !mensaje.message) return;

            const remitente = mensaje.key.remoteJid;
            
            // Ignorar grupos
            if (remitente && remitente.includes('@g.us')) return;

            const texto = mensaje.message.conversation || 
                         mensaje.message.extendedTextMessage?.text || '';
            
            if (!texto || texto.trim() === '') return;

            console.log('\n══════════════════════════════════');
            console.log(`📩 Mensaje de ${remitente.split('@')[0]}: "${texto}"`);
            console.log('══════════════════════════════════\n');

            // Simular que está escribiendo
            await simularTyping(sock, remitente);

            // Obtener datos de la empresa desde Sheets
            const datos = await obtenerDatosSheets(url_sheets);
            
            if (!datos) {
                await sock.sendMessage(remitente, { text: '❌ Error consultando base de datos' });
                return;
            }

            // Construir contexto para Ollama
            let contexto = datos.config?.PROMPT_SISTEMA || 
                "Eres un asistente de ventas amable y servicial. Ayudas a clientes con dudas sobre productos, precios, disponibilidad.";
            
            // Agregar información de productos si existe
            if (datos.productos && datos.productos.length > 0) {
                contexto += "\n\nProductos disponibles:\n";
                datos.productos.forEach(p => {
                    contexto += `- ${p.Nombre}: ${p.Precio} (${p.Stock} disponibles). ${p.Descripcion || ''}\n`;
                });
            }

            // Consultar Ollama
            const respuesta = await consultarOllama(texto, contexto);
            
            // Enviar respuesta
            await sock.sendMessage(remitente, { text: respuesta });
            guardarLog(`✅ Respuesta enviada a ${remitente.split('@')[0]}`);
        });

        console.log('\n📝 Bot listo para recibir mensajes');
        console.log('Presiona CTRL+C para salir\n');

    } catch (error) {
        guardarLog(`❌ ERROR FATAL: ${error.message}`);
        setTimeout(() => iniciarWhatsApp(), 30000);
    }
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
iniciarWhatsApp();
