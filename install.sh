#!/bin/bash

echo "===================================="
echo "🚀 INSTALADOR BOT VENTAS v1.0"
echo "===================================="
echo ""

# PASO 1: Instalar programas
echo "📦 Instalando programas necesarios..."
pkg update -y
pkg install git -y
pkg install nodejs -y
pkg install yarn -y

# PASO 2: Clonar
echo "📦 Descargando el bot..."
cd /data/data/com.termux/files/home
rm -rf whatsapp-bot-ventas 2>/dev/null
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# PASO 3: Crear estructura
mkdir -p bot
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 4: Instalar dependencias
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

echo ""
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📝 PARA CONFIGURAR:"
echo "1. Crea el archivo de configuración:"
echo "   echo 'TU_URL_DE_SHEETS' > ~/whatsapp-bot-ventas/url_sheets.txt"
echo ""
echo "2. Crea el archivo .env:"
echo "   echo 'WHATSAPP_NUMBER=TU_NUMERO' > ~/whatsapp-bot-ventas/bot/.env"
echo ""
echo "3. Inicia el bot:"
echo "   cd ~/whatsapp-bot-ventas/bot"
echo "   node bot.js"
echo ""
