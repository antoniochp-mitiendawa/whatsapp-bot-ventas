#!/bin/bash

# Este script se ejecuta LOCALMENTE después de la clonación
# Aquí SÍ funciona el read correctamente

clear
echo "===================================="
echo "🔗 CONFIGURACIÓN - PASO 1 DE 2"
echo "===================================="
echo "📌 URL DE GOOGLE SHEETS"
echo ""
echo "1. Abre Google Sheets"
echo "2. Ve al menú '🤖 Bot Ventas'"
echo "3. Haz clic en '📋 Ver instrucciones'"
echo "4. Copia la URL que aparece"
echo ""
echo "===================================="
echo ""
echo -n "📝 PEGA LA URL AQUÍ: "
read USER_URL

echo "$USER_URL" > url_sheets.txt
mkdir -p bot
cp url_sheets.txt bot/

clear
echo "===================================="
echo "📱 CONFIGURACIÓN - PASO 2 DE 2"
echo "===================================="
echo "📌 NÚMERO DE WHATSAPP"
echo ""
echo "Ingresa tu número con código de país"
echo "Ejemplo: 5215512345678"
echo ""
echo -n "📱 NÚMERO (sin +): "
read USER_NUMBER

echo "WHATSAPP_NUMBER=$USER_NUMBER" > bot/.env

# Continuar con el resto de la instalación...
echo ""
echo "📦 Instalando programas necesarios..."
pkg update -y
pkg install nodejs -y
pkg install yarn -y

echo "📦 Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios
mkdir -p bot/logs
mkdir -p bot/sesion_whatsapp

echo "📦 Instalando librerías..."
cd bot
npm init -y
npm install @whiskeysockets/baileys
npm install @hapi/boom
npm install qrcode-terminal
npm install node-cron
npm install axios
npm install pino
npm install dotenv
npm install fs-extra

echo "📦 Instalando Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📌 CONFIGURACIÓN GUARDADA:"
echo "   • URL: $USER_URL"
echo "   • Número: $USER_NUMBER"
echo ""
echo "🚀 INICIANDO BOT..."
sleep 2
node bot.js
