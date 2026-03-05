#!/bin/bash

echo "===================================="
echo "🚀 INSTALADOR BOT VENTAS v1.0"
echo "===================================="
echo ""

# PASO 1: Instalar Git
echo "📦 PASO 1: Instalando Git..."
pkg install git -y

# PASO 2: Clonar el repositorio
echo "📦 PASO 2: Descargando el bot..."
cd /data/data/com.termux/files/home
rm -rf whatsapp-bot-ventas 2>/dev/null
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# ============================================
# PASO 3: PEDIR URL (IGUAL QUE TU OTRO PROYECTO)
# ============================================
echo ""
echo "===================================="
echo "🔗 URL DE GOOGLE SHEETS"
echo "===================================="
echo "1. Abre Google Sheets"
echo "2. En el menú '🤖 Bot Ventas'"
echo "3. Ve a '📋 Ver instrucciones'"
echo "4. Copia la URL que aparece"
echo "===================================="
echo ""
echo "✏️  PEGA LA URL AQUÍ y presiona ENTER:"
read URL_SHEETS

# Guardar la URL
echo $URL_SHEETS > url_sheets.txt
mkdir -p bot
echo $URL_SHEETS > bot/url_sheets.txt

echo ""
echo "✅ URL guardada correctamente"
echo ""

# ============================================
# PASO 4: INSTALAR DEPENDENCIAS (como en install.sh)
# ============================================
echo "📦 Instalando programas necesarios..."
pkg update -y
pkg install nodejs -y
pkg install yarn -y
pkg install wget -y

echo "📦 Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

echo "📦 Instalando librerías (esto puede tomar varios minutos)..."
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

echo "📦 Instalando Ollama (IA local)..."
cd ..
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

mkdir -p bot/sesion_whatsapp
mkdir -p bot/logs

# ============================================
# MENSAJE FINAL
# ============================================
clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📌 URL guardada: $URL_SHEETS"
echo ""
echo "🚀 INICIANDO BOT EN 3 SEGUNDOS..."
sleep 3

# INICIAR BOT AUTOMÁTICAMENTE (como en tu otro proyecto)
cd bot
node bot.js
