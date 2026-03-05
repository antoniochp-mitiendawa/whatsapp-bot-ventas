#!/bin/bash

echo "===================================="
echo "🔧 CONFIGURACIÓN ADICIONAL"
echo "===================================="
echo ""

# Verificar que estamos en la carpeta correcta
if [ ! -f "url_sheets.txt" ]; then
    echo "❌ No se encuentra url_sheets.txt"
    echo "Ejecuta primero: bash start.sh"
    exit 1
fi

# Crear carpeta del bot si no existe
mkdir -p bot

# Copiar URL si es necesario
if [ ! -f "bot/url_sheets.txt" ]; then
    cp url_sheets.txt bot/
    echo "✅ URL copiada a carpeta bot/"
fi

# Crear carpetas necesarias
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios
mkdir -p bot/logs
mkdir -p bot/sesion_whatsapp

echo ""
echo "✅ Configuración adicional completada"
echo ""
echo "📝 Para iniciar el bot:"
echo "cd bot"
echo "node bot.js"
echo ""
