#!/bin/bash

echo "===================================="
echo "📦 INSTALANDO BOT VENTAS"
echo "===================================="
echo ""

# PASO 1: Instalar programas necesarios
echo "📦 PASO 1: Instalando programas necesarios..."
pkg update -y
pkg install nodejs -y
pkg install yarn -y
pkg install wget -y

# PASO 2: Crear carpeta del bot
echo "📦 PASO 2: Creando estructura..."
mkdir -p bot
cp url_sheets.txt bot/

# PASO 3: Crear carpetas multimedia
echo "📦 PASO 3: Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 4: Instalar dependencias Node.js
echo "📦 PASO 4: Instalando librerías (esto puede tomar varios minutos)..."
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

# PASO 5: Instalar Ollama
echo "📦 PASO 5: Instalando Ollama (IA local)..."
cd ..
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

# PASO 6: Crear carpetas de sesión y logs
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
echo "📌 URL guardada: $USER_URL"
echo ""
echo "🚀 PARA INICIAR EL BOT:"
echo "cd whatsapp-bot-ventas/bot"
echo "node bot.js"
echo ""
echo "📱 El bot te pedirá el número de teléfono"
echo "   y mostrará el código de vinculación"
echo "===================================="
echo ""

# PASO 7: Preguntar si quiere iniciar ahora
echo ""
echo "¿Quieres iniciar el bot AHORA?"
echo "Escribe 1 y Enter para INICIAR"
echo "Escribe 2 y Enter para SALIR"
echo ""
read OPCION

if [ "$OPCION" == "1" ]; then
    echo ""
    echo "🚀 INICIANDO BOT..."
    echo "======================"
    echo ""
    cd bot
    node bot.js
else
    echo ""
    echo "📝 Para iniciar después:"
    echo "cd whatsapp-bot-ventas/bot"
    echo "node bot.js"
    echo ""
fi
