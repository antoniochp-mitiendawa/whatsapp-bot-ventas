#!/bin/bash

# 1. Configuración de pantalla
clear
echo "=========================================="
echo "🚀 INSTALADOR TODO-EN-UNO (CORREGIDO)"
echo "=========================================="

# 2. Instalación de sistema
echo "📦 Instalando herramientas necesarias..."
pkg update -y
pkg install git nodejs-lts -y

# 3. Preparar carpetas
cd $HOME
rm -rf whatsapp-bot-ventas
mkdir whatsapp-bot-ventas
cd whatsapp-bot-ventas

# 4. PEDIR DATOS (Aquí es donde el código se detiene)
echo ""
echo "🔗 CONFIGURACIÓN DE GOOGLE SHEETS"
read -p "📝 Pega la URL de tu hoja de cálculo: " URL_USER

echo ""
echo "📱 CONFIGURACIÓN DE WHATSAPP"
read -p "📞 Introduce tu número (ej. 5212223334455): " TEL_USER

# 5. EL COCOCINERO PREPARA LA RECETA (Escribir archivos automáticamente)
echo "URL_SHEETS=$URL_USER" > .env
echo "PAIRING_NUMBER=$TEL_USER" >> .env

# Crear el package.json sin errores
cat <<EOT > package.json
{
  "name": "bot-ventas",
  "version": "1.0.0",
  "main": "bot.js",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.5.0",
    "@hapi/boom": "^10.0.1",
    "dotenv": "^16.3.1",
    "pino": "^8.15.0"
  }
}
EOT

# Crear el bot.js sin el error de la línea 20
cat <<EOT > bot.js
require('dotenv').config();
const { default: makeWASocket, useMultiFileAuthState, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const pino = require('pino');

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion');
    const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({
        version,
        printQRInTerminal: false,
        auth: state,
        logger: pino({ level: 'silent' }),
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    if (!sock.authState.creds.registered) {
        const num = process.env.PAIRING_NUMBER;
        console.log("🔄 Generando código para: " + num);
        setTimeout(async () => {
            const code = await sock.requestPairingCode(num);
            console.log("\n✅ TU CÓDIGO ES: " + code + "\n");
        }, 3000);
    }
    sock.ev.on('creds.update', saveCreds);
    sock.ev.on('connection.update', (u) => {
        if (u.connection === 'open') console.log('✅ CONECTADO');
        if (u.connection === 'close') iniciar();
    });
}
iniciar();
EOT

# 6. Finalizar
echo "📦 Instalando librerías finales..."
npm install

echo "=========================================="
echo "✅ TODO LISTO"
echo "=========================================="
node bot.js
