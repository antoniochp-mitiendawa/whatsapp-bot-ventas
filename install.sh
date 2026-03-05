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

# PASO 2: Definir ruta base
BASE_DIR="/data/data/com.termux/files/home/whatsapp-bot-ventas"
cd $BASE_DIR

# PASO 3: Verificar que existe url_sheets.txt
echo "📦 PASO 2: Verificando URL..."
if [ ! -f "$BASE_DIR/url_sheets.txt" ]; then
    echo "❌ ERROR: No se encuentra url_sheets.txt"
    echo "Debes ejecutar primero: bash start.sh"
    exit 1
fi

# Leer la URL para mostrarla después
URL_GUARDADA=$(cat $BASE_DIR/url_sheets.txt)
echo "✅ URL encontrada: $URL_GUARDADA"

# PASO 4: Crear carpeta del bot
echo "📦 PASO 3: Creando estructura..."
mkdir -p $BASE_DIR/bot

# Copiar URL a la carpeta bot
cp $BASE_DIR/url_sheets.txt $BASE_DIR/bot/
echo "✅ URL copiada a bot/"

# PASO 5: Crear carpetas multimedia
echo "📦 PASO 4: Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 6: Instalar dependencias Node.js
echo "📦 PASO 5: Instalando librerías (esto puede tomar varios minutos)..."
cd $BASE_DIR/bot
npm init -y
npm install @whiskeysockets/baileys
npm install @hapi/boom
npm install qrcode-terminal
npm install node-cron
npm install axios
npm install pino
npm install dotenv
npm install fs-extra

# PASO 7: Instalar Ollama
echo "📦 PASO 6: Instalando Ollama (IA local)..."
cd $BASE_DIR
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

# PASO 8: Crear carpetas de sesión y logs
mkdir -p $BASE_DIR/bot/sesion_whatsapp
mkdir -p $BASE_DIR/bot/logs

# ============================================
# MENSAJE FINAL
# ============================================
clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📌 URL guardada: $URL_GUARDADA"
echo ""
echo "🚀 PARA INICIAR EL BOT:"
echo "cd $BASE_DIR/bot"
echo "node bot.js"
echo ""
echo "📱 El bot te pedirá el número de teléfono"
echo "   y mostrará el código de vinculación"
echo "===================================="
echo ""

# PASO 9: Preguntar si quiere iniciar ahora
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
    cd $BASE_DIR/bot
    node bot.js
else
    echo ""
    echo "📝 Para iniciar después:"
    echo "cd $BASE_DIR/bot"
    echo "node bot.js"
    echo ""
fi
