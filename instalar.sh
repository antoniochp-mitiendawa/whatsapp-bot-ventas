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
# PASO 3: PEDIR LA URL - ¡VERSIÓN CORREGIDA!
# ============================================
echo ""
echo "===================================="
echo "🔗 CONFIGURACIÓN - URL DE GOOGLE SHEETS"
echo "===================================="
echo "1. Abre Google Sheets"
echo "2. Ve al menú '🤖 Bot Ventas'"
echo "3. Haz clic en '📋 Ver instrucciones'"
echo "4. Copia la URL que aparece"
echo "===================================="
echo ""

# LECTURA CORRECTA: El prompt y la lectura en la MISMA línea
read -p "📝 PEGA LA URL AQUÍ y presiona Enter: " USER_URL

# Validar que no esté vacía
if [ -z "$USER_URL" ]; then
    echo "❌ ERROR: No se ingresó ninguna URL"
    exit 1
fi

# Guardar la URL
echo "$USER_URL" > url_sheets.txt
mkdir -p bot
cp url_sheets.txt bot/

echo "✅ URL guardada correctamente: $USER_URL"
echo ""

# PASO 4: Instalar programas necesarios
echo "📦 PASO 4: Instalando programas necesarios..."
pkg update -y
pkg install nodejs -y
pkg install yarn -y
pkg install wget -y

# PASO 5: Crear carpetas multimedia
echo "📦 PASO 5: Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 6: Instalar dependencias Node.js
echo "📦 PASO 6: Instalando librerías (esto puede tomar varios minutos)..."
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

# PASO 7: Instalar Ollama
echo "📦 PASO 7: Instalando Ollama (IA local)..."
cd ..
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

# PASO 8: Crear carpetas de sesión y logs
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

# PASO 9: Preguntar si quiere iniciar ahora
echo ""
read -p "¿Quieres iniciar el bot AHORA? (1=SI / 2=NO): " OPCION

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
