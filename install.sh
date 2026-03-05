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
# PASO 3: PEDIR URL DE GOOGLE SHEETS
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

# Crear un archivo temporal para forzar la entrada
exec < /dev/tty

while true; do
    echo -n "📝 PEGA LA URL AQUÍ: "
    read USER_URL
    if [ -n "$USER_URL" ]; then
        break
    else
        echo "❌ La URL no puede estar vacía"
    fi
done

echo "$USER_URL" > url_sheets.txt
echo "✅ URL guardada correctamente"
sleep 1

# ============================================
# PASO 4: PEDIR NÚMERO DE WHATSAPP
# ============================================
clear
echo "===================================="
echo "📱 CONFIGURACIÓN - PASO 2 DE 2"
echo "===================================="
echo "📌 NÚMERO DE WHATSAPP"
echo ""
echo "Ingresa tu número con código de país"
echo "Ejemplo: 5215512345678 (México)"
echo "         5491123456789 (Argentina)"
echo "         34612345678 (España)"
echo ""
echo "===================================="
echo ""

while true; do
    echo -n "📱 NÚMERO (sin + ni espacios): "
    read USER_NUMBER
    if [ -n "$USER_NUMBER" ]; then
        break
    else
        echo "❌ El número no puede estar vacío"
    fi
done

# Crear archivo .env
echo "WHATSAPP_NUMBER=$USER_NUMBER" > bot/.env
echo "✅ Número guardado correctamente"
sleep 1

# ============================================
# CONTINUAR CON LA INSTALACIÓN
# ============================================
clear
echo "📦 Continuando con la instalación..."

# PASO 5: Crear carpeta del bot (si no existe)
mkdir -p bot
cp url_sheets.txt bot/

# PASO 6: Crear carpetas multimedia
echo "📦 Creando carpetas multimedia..."
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios
mkdir -p bot/logs
mkdir -p bot/sesion_whatsapp

# PASO 7: Instalar dependencias
echo "📦 Instalando librerías..."
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
# MENSAJE FINAL
# ============================================
clear
echo "===================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "===================================="
echo ""
echo "📌 RESUMEN:"
echo "   • URL guardada: $USER_URL"
echo "   • Número configurado: $USER_NUMBER"
echo ""
echo "🚀 PARA INICIAR EL BOT:"
echo "   cd ~/whatsapp-bot-ventas/bot"
echo "   node bot.js"
echo ""
echo "📱 El bot mostrará un código de 8 dígitos"
echo "   Abre WhatsApp → Vincular dispositivo"
echo "===================================="
echo ""
