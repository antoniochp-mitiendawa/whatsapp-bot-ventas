// ============================================
// SERVICIO DE WHATSAPP CON BAILEYS (PAIRING)
// ============================================

const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const P = require('pino');
const path = require('path');
const fs = require('fs-extra');

class WhatsAppService {
  constructor(messageHandler) {
    this.sock = null;
    this.messageHandler = messageHandler;
    this.sessionPath = path.join(__dirname, '../../sessions');
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.connected = false;
  }

  async inicializar() {
    try {
      // Asegurar que existe la carpeta de sesiones
      await fs.ensureDir(this.sessionPath);

      // Cargar estado de autenticación
      const { state, saveCreds } = await useMultiFileAuthState(this.sessionPath);

      // Crear conexión
      this.sock = makeWASocket({
        auth: state,
        printQRInTerminal: false, // No usar QR
        logger: P({ level: 'silent' }), // Silenciar logs de Baileys
        browser: ['Bot Ventas', 'Chrome', '1.0.0'],
        syncFullHistory: false,
        generateHighQualityLinkPreview: false,
        shouldSyncHistoryMessage: false,
        patchMessageBeforeSending: (msg) => msg
      });

      // Configurar eventos
      this.configurarEventos(saveCreds);

      // Iniciar pairing si no está autenticado
      if (!this.sock.authState.creds.registered) {
        await this.iniciarPairing();
      }

      return this.sock;

    } catch (error) {
      console.error('❌ Error inicializando WhatsApp:', error);
      throw error;
    }
  }

  configurarEventos(saveCreds) {
    // Guardar credenciales cuando se actualicen
    this.sock.ev.on('creds.update', saveCreds);

    // Manejar conexión
    this.sock.ev.on('connection.update', async (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        // No debería mostrar QR porque usamos pairing
        console.log('⚠️ Se generó un QR inesperado (ignorando)');
      }

      if (connection === 'close') {
        const shouldReconnect = 
          (lastDisconnect?.error instanceof Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
        
        console.log('🔌 Conexión cerrada', { shouldReconnect });

        if (shouldReconnect && this.reconnectAttempts < this.maxReconnectAttempts) {
          this.reconnectAttempts++;
          console.log(`🔄 Reintentando conexión (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
          setTimeout(() => this.inicializar(), 5000 * this.reconnectAttempts);
        } else {
          console.log('❌ No se pudo reconectar, sesión cerrada');
          this.connected = false;
        }
      }

      if (connection === 'open') {
        console.log('✅ WhatsApp conectado exitosamente');
        this.reconnectAttempts = 0;
        this.connected = true;
        
        // Mostrar información de la conexión
        const numero = this.sock.user?.id?.split(':')[0];
        console.log(`📱 Conectado como: ${numero}`);
      }
    });

    // Manejar mensajes entrantes
    this.sock.ev.on('messages.upsert', async ({ messages, type }) => {
      if (type !== 'notify') return;

      for (const msg of messages) {
        // Ignorar mensajes propios
        if (msg.key.fromMe) continue;

        // Ignorar mensajes de estado
        if (msg.key.remoteJid === 'status@broadcast') continue;

        // Procesar mensaje
        if (this.messageHandler) {
          await this.messageHandler.procesarMensaje(this.sock, msg);
        }
      }
    });

    // Mantener conexión activa (keep-alive)
    setInterval(() => {
      if (this.connected && this.sock) {
        this.sock.sendPresenceUpdate('available');
      }
    }, 60000); // Cada minuto
  }

  async iniciarPairing() {
    try {
      const numero = process.env.WHATSAPP_NUMBER;
      
      if (!numero) {
        console.error('❌ Número de WhatsApp no configurado en .env');
        console.log('Ejecuta: node setup.js para configurar');
        process.exit(1);
      }

      console.log(`\n🔐 Solicitando código de vinculación para: ${numero}`);
      
      // Solicitar código de pairing
      const code = await this.sock.requestPairingCode(numero);
      
      // Formatear código (xxxx xxxx)
      const formattedCode = code.match(/.{1,4}/g).join(' ');
      
      console.log('\n\x1b[32m========================================\x1b[0m');
      console.log('\x1b[33m   📱 CÓDIGO DE VINCULACIÓN\x1b[0m');
      console.log('\x1b[32m========================================\x1b[0m\n');
      console.log(`   \x1b[36m${formattedCode}\x1b[0m\n`);
      console.log('\x1b[32m========================================\x1b[0m\n');
      console.log('Pasos para vincular:');
      console.log('1. Abre WhatsApp en tu teléfono');
      console.log('2. Ve a los 3 puntos → Dispositivos vinculados');
      console.log('3. Toca "Vincular dispositivo"');
      console.log('4. Elige "Vincular con número de teléfono"');
      console.log('5. Ingresa el código de arriba\n');
      console.log('⏳ Esperando vinculación...\n');

      // Esperar a que se complete la vinculación
      return new Promise((resolve) => {
        const checkAuth = setInterval(() => {
          if (this.sock.authState.creds.registered) {
            clearInterval(checkAuth);
            console.log('✅ Vinculación exitosa');
            resolve();
          }
        }, 1000);
      });

    } catch (error) {
      console.error('❌ Error en pairing:', error);
      throw error;
    }
  }

  // Enviar mensaje de texto
  async enviarTexto(jid, texto) {
    try {
      await this.sock.sendMessage(jid, { text: texto });
      return true;
    } catch (error) {
      console.error('❌ Error enviando texto:', error);
      return false;
    }
  }

  // Enviar imagen con texto
  async enviarImagen(jid, texto, imagenPath) {
    try {
      // Verificar si existe el archivo
      const fullPath = path.join(process.env.MULTIMEDIA_PATH || '/storage/emulated/0/WhatsAppBot/', imagenPath);
      
      if (await fs.pathExists(fullPath)) {
        const imagen = await fs.readFile(fullPath);
        await this.sock.sendMessage(jid, { 
          image: imagen, 
          caption: texto 
        });
      } else {
        // Si no hay imagen, solo enviar texto
        await this.enviarTexto(jid, texto + ' (imagen no disponible)');
      }
      return true;
    } catch (error) {
      console.error('❌ Error enviando imagen:', error);
      return this.enviarTexto(jid, texto);
    }
  }

  // Cerrar sesión
  async cerrarSesion() {
    try {
      if (this.sock) {
        await this.sock.logout();
      }
      await fs.remove(this.sessionPath);
      console.log('✅ Sesión cerrada');
    } catch (error) {
      console.error('❌ Error cerrando sesión:', error);
    }
  }
}

module.exports = WhatsAppService;
