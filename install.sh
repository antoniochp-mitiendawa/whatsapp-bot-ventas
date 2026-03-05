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

# ============================================
# PASO 3: PEDIR URL - VERSIÓN CORREGIDA
# ============================================
clear
echo "===================================="
echo "🔗 CONFIGURACIÓN DE GOOGLE SHEETS"
echo "===================================="
echo ""
echo "ANTES DE CONTINUAR:"
echo "1. Ve a Google Sheets"
echo "2. Abre el menú '🤖 Bot Ventas'"
echo "3. Haz clic en '📋 Ver instrucciones'"
echo "4. Copia la URL que aparece"
echo ""
echo "===================================="
echo ""

# Crear un archivo temporal para forzar la pausa
echo "⏸️  PRESIONA ENTER PARA CONTINUAR..."
read -p ""

# Ahora pedir la URL directamente desde el terminal
echo ""
echo "📝 PEGA LA URL AQUÍ (clic derecho o mantener presionado para pegar):"
read USER_URL

# Validar que no esté vacía
while [ -z "$USER_URL" ]; do
    echo "❌ La URL no puede estar vacía. Intenta de nuevo:"
    read USER_URL
done

# Guardar URL
echo "$USER_URL" > url_sheets.txt
echo "✅ URL guardada correctamente"

# PASO 4: Crear carpeta del bot
mkdir -p bot

# PASO 5: Guardar URL también dentro
cp url_sheets.txt bot/

# PASO 6: Instalar dependencias
echo ""
echo "📦 PASO 6: Instalando librerías..."
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

# PASO 7: Crear carpetas necesarias
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios
mkdir -p logs
mkdir -p sesion_whatsapp

echo ""
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📝 Para iniciar el bot:"
echo "cd whatsapp-bot-ventas/bot"
echo "node bot.js"
echo ""
