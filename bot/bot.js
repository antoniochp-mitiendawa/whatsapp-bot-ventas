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
    modelo: process.env.OLLAMA_MODEL || 'tinyllama:1.1b-chat-q4_K_M'
};

// ============================================
// FUNCIÓN PARA SINCRONIZAR DATOS
// ============================================
async function sincronizarDatos() {
    try {
        console.log("📥 Sincronizando con Google Sheets...");
        const response = await axios.get(`${CONFIG.url_sheets}?accion=obtener_todo`);
        
        if (response.data && response.data.status === 'success') {
            const data = response.data.data;
            
            if (data.configuracion && data.configuracion.delay_respuesta) {
                const delayStr = data.configuracion.delay_respuesta;
                if (delayStr.includes('-')) {
                    const partes = delayStr.split('-').map(p => parseInt(p.trim()));
                    if (partes.length === 2 && !isNaN(partes[0]) && !isNaN(partes[1])) {
                        CONFIG.delay_min = partes[0];
                        CONFIG.delay_max = partes[1];
                        console.log(`⏱️  Delay configurado: ${CONFIG.delay_min}-${CONFIG.delay_max} segundos`);
                    }
                }
            }
            
            fs.writeFileSync(CONFIG.archivo_memoria, JSON.stringify(data, null, 2));
            console.log("✅ Datos sincronizados correctamente");
            console.log(`   • Empresa: ${data.empresa?.nombre || 'No configurada'}`);
            console.log(`   • Productos: ${data.productos?.length || 0}`);
            console.log(`   • Asesores: ${data.asesores?.length || 0}`);
            return data;
        }
    } catch (error) {
        console.log("⚠️ Error conectando con Sheets, usando caché local:", error.message);
        if (fs.existsSync(CONFIG.archivo_memoria)) {
            return JSON.parse(fs.readFileSync(CONFIG.archivo_memoria));
        }
    }
    return null;
}

// ============================================
// FUNCIÓN PARA DELAY ALEATORIO
// ============================================
function delayAleatorio() {
    const min = CONFIG.delay_min || 2;
    const max = CONFIG.delay_max || 5;
    const tiempo = Math.floor(Math.random() * (max - min + 1) + min) * 1000;
    console.log(`⏱️  Esperando ${tiempo/1000} segundos antes de responder...`);
    return new Promise(resolve => setTimeout(resolve, tiempo));
}

// ============================================
// FUNCIÓN PARA PROCESAR CON IA
// ============================================
async function procesarConIA(texto, datos) {
    try {
        let prompt = "Eres un asistente de ventas amable y servicial.\n\n";
        
        if (datos.empresa) {
            prompt += "INFORMACIÓN DE LA EMPRESA:\n";
            for (let [key, value] of Object.entries(datos.empresa)) {
                if (value && key !== 'prompt_sistema') {
                    prompt += `${key}: ${value}\n`;
                }
            }
            prompt += "\n";
        }
        
        if (datos.empresa?.prompt_sistema) {
            prompt += `INSTRUCCIONES: ${datos.empresa.prompt_sistema}\n\n`;
        }
        
        if (datos.productos && datos.productos.length > 0) {
            prompt += "PRODUCTOS DISPONIBLES:\n";
            datos.productos.forEach(p => {
                if (p.Activo === 'SI') {
                    prompt += `- ${p.Nombre}: ${p.Precio} (Stock: ${p.Stock})\n`;
                }
            });
            prompt += "\n";
        }
        
        prompt += `Cliente: ${texto}\n`;
        prompt += `Asistente: `;

        const res = await axios.post(CONFIG.ollama_url, {
            model: CONFIG.modelo,
            prompt: prompt,
            stream: false,
            options: {
                temperature: 0.7,
                max_tokens: 150
            }
        }, {
            timeout: 30000
        });
        
        return res.data.response;
        
    } catch (error) {
        if (error.code === 'ECONNABORTED') {
            console.log("❌ Timeout: IA tardó demasiado");
            return "Lo siento, estoy procesando tu solicitud. Un asesor humano te atenderá en breve si lo prefieres.";
        }
        console.log("❌ Error en IA:", error.message);
        return "Un asesor humano te atenderá en breve.";
    }
}

// ============================================
// FUNCIÓN PARA ASIGNAR ASESOR
// ============================================
async function asignarAsesor(datos) {
    if (!datos.asesores) return null;
    
    const activos = datos.asesores.filter(a => a.Activo === 'SI');
    if (activos.length === 0) return null;
    
    activos.sort((a, b) => (a['Atendidos Hoy'] || 0) - (b['Atendidos Hoy'] || 0));
    const asesor = activos[0];
    
    try {
        await axios.get(`${CONFIG.url_sheets}?accion=actualizar_asesor&id=${asesor.ID}&atendidos=${(asesor['Atendidos Hoy'] || 0) + 1}`);
    } catch (e) {
        console.log("⚠️ No se pudo actualizar conteo de asesor");
    }
    
    return asesor;
}

// ============================================
// FUNCIÓN PRINCIPAL
// ============================================
async function iniciarBot() {
    console.log("======================================");
    console.log("🤖 BOT DE VENTAS CON IA");
    console.log("======================================");
    
    const datos = await sincronizarDatos();
    
    if (!datos) {
        console.log("❌ No se pudieron cargar los datos. Verifica tu URL de Sheets.");
        process.exit(1);
    }

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
            try {
                const codigo = await sock.requestPairingCode(CONFIG.numero_telefono);
                console.log('\n======================================');
                console.log('🔐 CÓDIGO DE VINCULACIÓN');
                console.log('======================================');
                console.log(`   ${codigo}`);
                console.log('======================================\n');
                console.log('1. Abre WhatsApp en tu teléfono');
                console.log('2. Ve a 3 puntos → Dispositivos vinculados');
                console.log('3. Toca "Vincular con número de teléfono"');
                console.log('4. Ingresa el código de arriba\n');
            } catch (error) {
                console.log('❌ Error generando código:', error.message);
            }
        }, 3000);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (up) => {
        if (up.connection === 'open') {
            console.log('\n✅ BOT EN LÍNEA - LISTO PARA ATENDER');
            console.log('======================================\n');
        }
        if (up.connection === 'close') {
            const shouldReconnect = new Boom(up.lastDisconnect?.error)?.output?.statusCode !== DisconnectReason.loggedOut;
            if (shouldReconnect) {
                console.log('🔄 Reconectando...');
                iniciarBot();
            }
        }
    });

    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify' || !messages[0].message || messages[0].key.fromMe) return;
        
        const jid = messages[0].key.remoteJid;
        if (jid.includes('@g.us')) return;
        
        const msgText = messages[0].message.conversation || 
                       messages[0].message.extendedTextMessage?.text || 
                       '';

        if (msgText && datos) {
            console.log(`\n📩 Mensaje de ${jid.split('@')[0]}: "${msgText}"`);
            
            const textoLower = msgText.toLowerCase();
            if (textoLower.includes('asesor') || textoLower.includes('humano') || textoLower.includes('persona')) {
                const asesor = await asignarAsesor(datos);
                if (asesor) {
                    const mensaje = datos.empresa?.mensaje_asignacion || 'Te contactaré con un asesor en breve.';
                    const mensajeFinal = mensaje.replace('{nombre}', asesor.Nombre || '').replace('{telefono}', asesor.Teléfono || '');
                    await sock.sendMessage(jid, { text: mensajeFinal });
                    console.log(`✅ Asesor asignado: ${asesor.Nombre}`);
                    return;
                }
            }
            
            console.log("🤔 Procesando con IA...");
            const respuesta = await procesarConIA(msgText, datos);
            
            await delayAleatorio();
            
            await sock.sendMessage(jid, { text: respuesta });
            console.log(`✅ Respuesta enviada: "${respuesta.substring(0, 50)}..."`);
        }
    });
}

iniciarBot().catch(error => {
    console.log('❌ Error fatal:', error);
});
