#!/bin/bash

echo "===================================="
echo "🚀 INSTALADOR BOT VENTAS v1.0"
echo "===================================="
echo ""

# PASO 1: Instalar lo básico
echo "📦 PASO 1: Instalando programas necesarios..."
pkg update -y
pkg install git -y
pkg install nodejs -y
pkg install yarn -y

# PASO 2: Clonar el repositorio
echo "📦 PASO 2: Descargando el bot..."
cd /data/data/com.termux/files/home
rm -rf whatsapp-bot-ventas 2>/dev/null
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# PASO 3: Crear carpeta del bot
mkdir -p bot
mkdir -p bot/logs
mkdir -p bot/sesion_whatsapp

# PASO 4: Crear carpetas multimedia
echo "📦 PASO 3: Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 5: Instalar dependencias
echo "📦 PASO 4: Instalando librerías..."
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

# PASO 6: Mensaje final con INSTRUCCIONES CLARAS
clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "===================================="
echo ""
echo "📝 PASOS MANUALES NECESARIOS:"
echo ""
echo "1. GUARDAR LA URL DE GOOGLE SHEETS:"
echo "   echo 'https://script.google.com/macros/s/.../exec' > ~/whatsapp-bot-ventas/url_sheets.txt"
echo ""
echo "2. CONFIGURAR NÚMERO DE WHATSAPP:"
echo "   echo 'WHATSAPP_NUMBER=521234567890' > ~/whatsapp-bot-ventas/bot/.env"
echo "   (reemplaza 521234567890 con tu número, código de país sin +)"
echo ""
echo "3. INICIAR EL BOT:"
echo "   cd ~/whatsapp-bot-ventas/bot"
echo "   node bot.js"
echo ""
echo "===================================="
echo ""
