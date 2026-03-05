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

# PASO 3: Crear estructura básica
mkdir -p bot
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios
mkdir -p bot/logs
mkdir -p bot/sesion_whatsapp

# ============================================
# PASO 4: PEDIR URL DE GOOGLE SHEETS
# ============================================
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

# Versión simplificada - sin exec < /dev/tty
echo -n "📝 PEGA LA URL AQUÍ: "
read USER_URL < /dev/tty || {
    # Si falla, intentamos método alternativo
    read USER_URL
}

echo "$USER_URL" > url_sheets.txt
cp url_sheets.txt bot/
echo "✅ URL guardada correctamente"

# ============================================
# PASO 5: PEDIR NÚMERO DE WHATSAPP
# ============================================
clear
echo "===================================="
echo "📱 CONFIGURACIÓN - PASO 2 DE 2"
echo "===================================="
echo "📌 NÚMERO DE WHATSAPP"
echo ""
echo "Ingresa tu número con código de país"
echo "Ejemplo: 5215512345678 (México)"
echo "===================================="
echo ""

echo -n "📱 NÚMERO (sin +): "
read USER_NUMBER < /dev/tty || {
    read USER_NUMBER
}

echo "WHATSAPP_NUMBER=$USER_NUMBER" > bot/.env
echo "✅ Número guardado correctamente"

# ============================================
# PASO 6: INSTALAR DEPENDENCIAS
# ============================================
clear
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

# ============================================
# PASO 7: INSTALAR OLLAMA
# ============================================
echo "📦 Instalando Ollama (IA local)..."
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

# ============================================
# MENSAJE FINAL
# ============================================
clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📌 CONFIGURACIÓN GUARDADA:"
echo "   • URL: $USER_URL"
echo "   • Número: $USER_NUMBER"
echo ""
echo "🚀 INICIANDO BOT EN 3 SEGUNDOS..."
sleep 3

# Iniciar el bot automáticamente
cd ~/whatsapp-bot-ventas/bot
node bot.js
