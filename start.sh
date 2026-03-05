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

# PASO 3: Pedir la URL de Google Sheets
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
echo "📝 PEGA LA URL AQUÍ y presiona Enter:"
read USER_URL

# Guardar la URL (usando ruta absoluta)
echo $USER_URL > /data/data/com.termux/files/home/whatsapp-bot-ventas/url_sheets.txt
echo "✅ URL guardada correctamente"
echo ""

# Mostrar confirmación
echo "📌 URL guardada en: /data/data/com.termux/files/home/whatsapp-bot-ventas/url_sheets.txt"
ls -la /data/data/com.termux/files/home/whatsapp-bot-ventas/url_sheets.txt

# PASO 4: Ejecutar la instalación completa
echo ""
echo "📦 Continuando con la instalación..."
cd /data/data/com.termux/files/home/whatsapp-bot-ventas
bash install.sh
