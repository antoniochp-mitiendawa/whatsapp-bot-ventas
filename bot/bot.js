// ============================================
// BOT DE VENTAS PARA WHATSAPP
// Versión: 1.0 - Basado en proyecto anterior
// Google Sheets + Ollama + Pairing
// ============================================

const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const fs = require('fs');
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
    archivo_url: './url_sheets.txt',
    carpeta_logs: './logs',
    carpeta_multimedia: '/storage/emulated/0/WhatsAppBot',
    tiempo_typing: 2000
};

// Crear carpetas necesarias
if (!fs.existsSync(CONFIG.carpeta_logs)) fs.mkdirSync(CONFIG.carpeta_logs);
if (!fs.existsSync(CONFIG.carpeta_sesion)) fs.mkdirSync(CONFIG.carpeta_sesion);
if (!fs.existsSync(CONFIG.carpeta_multimedia)) {
    try {
        fs.mkdirSync(CONFIG.carpeta_multimedia, { recursive: true });
    } catch (e) {}
}

// ============================================
// LEER URL DE GOOGLE SHEETS
// ============================================
function leerURL() {
    try {
        if (fs.existsSync(CONFIG.archivo_url)) {
            const url = fs.readFileSync(CONFIG.archivo_url, 'utf8').trim();
            console.log('✅ URL de Google Sheets cargada');
            return url;
        } else {
            console.error('❌ No se encuentra el archivo url_sheets.txt');
            console.log('📝 Crea el archivo con: echo "TU_URL" > url_sheets.txt');
            process.exit(1);
        }
    } catch (error) {
        console.error('❌ Error leyendo URL:', error.message);
        process.exit(1);
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
// PEDIR NÚMERO DE TELÉFONO (como en tu otro proyecto)
// ============================================
function pedirNumero() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        console.log('\n====================================');
        console.log('📱 CONFIGURACIÓN INICIAL');
        console.log('====================================');
        console.log('Ingresa tu número de WhatsApp');
        console.log('Ejemplo: 5215512345678 (México)');
        console.log('         5491123456789 (Argentina)');
        console.log('====================================\n');
        
        rl.question('📱 NÚMERO (sin +): ', (numero) => {
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
    if (!url_sheets) return;

    try {
        const { version } = await fetchLatestBaileysVersion();
        const { state, saveCreds } = await useMultiFileAuthState(CONFIG.carpeta_sesion);

        const existeSesion = fs.existsSync(path.join(CONFIG.carpeta_sesion, 'creds.json'));

        const sock = makeWASocket({
            version,
            auth: state,
            logger: pino({ level: 'silent' }),
            printQRInTerminal: false,
            browser: ["Ubuntu", "Chrome", "20.0.04"],
            syncFullHistory: false,
            keepAliveIntervalMs: 25000
        });

        // ============================================
        // PRIMERA VEZ - PEDIR NÚMERO Y MOSTRAR CÓDIGO
        // ============================================
        if (!existeSesion) {
            console.log('\n📱 PRIMERA CONFIGURACIÓN\n');
            const numero = await pedirNumero();
            
            console.log('\n🔄 Solicitando código de vinculación...\n');
            
            setTimeout(async () => {
                try {
                    const codigo = await sock.requestPairingCode(numero);
                    
                    console.log('\n====================================');
                    console.log('🔐 CÓDIGO DE VINCULACIÓN');
                    console.log('====================================');
                    console.log(`   ${codigo}`);
                    console.log('====================================\n');
                    console.log('1. Abre WhatsApp en tu teléfono');
                    console.log('2. Ve a 3 puntos → Dispositivos vinculados');
                    console.log('3. Toca "Vincular con número de teléfono"');
                    console.log('4. Ingresa el código de arriba\n');
                    
                } catch (error) {
                    console.log('❌ Error generando código:', error.message);
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

        sock.ev.on('creds.update', saveCreds);

        // ============================================
        // EVENTO DE MENSAJES
        // ============================================
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

            guardarLog(`📩 Mensaje de ${remitente.split('@')[0]}: "${texto}"`);

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
