}#!/bin/bash

echo "===================================="
echo "🚀 INSTALADOR BOT VENTAS v1.0"
echo "===================================="
echo ""

# PASO 1: Instalar Git
echo "📦 PASO 1: Instalando Git..."
pkg install git -y

# PASO 2: Crear directorio y descargar
echo "📦 PASO 2: Descargando el bot..."
cd /data/data/com.termux/files/home
rm -rf whatsapp-bot-ventas 2>/dev/null
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# ============================================
# PASO 3: PEDIR URL - ESTO SE DETIENE
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

# TRUCO: Usar >&2 para asegurar que el prompt se vea
echo -n "📝 PEGA LA URL AQUÍ y presiona Enter: " >&2

# Leer directamente desde la terminal
read USER_URL </dev/tty

# Guardar URL
echo "$USER_URL" > url_sheets.txt
mkdir -p bot
cp url_sheets.txt bot/

echo "✅ URL guardada: $USER_URL"
echo ""

# PASO 4: Continuar instalación
echo "📦 Instalando programas necesarios..."
pkg update -y
pkg install nodejs yarn wget -y

# PASO 5: Carpetas multimedia
mkdir -p /storage/emulated/0/WhatsAppBot/{imagenes,videos,audios}

# PASO 6: Dependencias
cd bot
npm init -y
npm install @whiskeysockets/baileys @hapi/boom qrcode-terminal node-cron axios pino dotenv fs-extra

# PASO 7: Ollama
cd ..
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

mkdir -p bot/sesion_whatsapp bot/logs

clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo "URL: $USER_URL"
echo ""
echo "cd whatsapp-bot-ventas/bot && node bot.js"
echo ""
read -p "¿Iniciar ahora? (1=SI): " OPCION
[ "$OPCION" == "1" ] && cd bot && node bot.js
