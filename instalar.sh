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
# PASO 3: PEDIR LA URL (FORZANDO LECTURA)
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

# FORZAR lectura desde terminal
exec < /dev/tty
echo -n "📝 PEGA LA URL AQUÍ y presiona Enter: "
read USER_URL

# Guardar la URL (en dos lugares para seguridad)
echo "$USER_URL" > url_sheets.txt
echo "$USER_URL" > /data/data/com.termux/files/home/whatsapp-bot-ventas/url_sheets.txt
echo "✅ URL guardada correctamente"
echo ""

# PASO 4: Instalar programas necesarios
echo "📦 PASO 4: Instalando programas necesarios..."
pkg update -y
pkg install nodejs -y
pkg install yarn -y
pkg install wget -y

# PASO 5: Crear carpeta del bot
echo "📦 PASO 5: Creando estructura..."
mkdir -p bot
cp url_sheets.txt bot/

# PASO 6: Crear carpetas multimedia
echo "📦 PASO 6: Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# PASO 7: Instalar dependencias Node.js
echo "📦 PASO 7: Instalando librerías (esto puede tomar varios minutos)..."
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

# PASO 8: Instalar Ollama
echo "📦 PASO 8: Instalando Ollama (IA local)..."
cd ..
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

# PASO 9: Crear carpetas de sesión y logs
mkdir -p bot/sesion_whatsapp
mkdir -p bot/logs

# ============================================
# MENSAJE FINAL (AHORA CON LA URL CORRECTA)
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

# PASO 10: Preguntar si quiere iniciar ahora
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
