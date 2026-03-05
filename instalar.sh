#!/bin/bash

header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR PROFESIONAL BOT VENTAS"
    echo "=========================================="
}

header
echo "📦 PASO 1: Preparando entorno de Termux..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget -y

header
echo "📦 PASO 2: Clonando proyecto desde GitHub..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas/bot # <--- CORRECCIÓN DE RUTA AQUÍ

# CONFIGURACIÓN
header
echo "🔗 CONFIGURACIÓN DE DATOS"
read -p "📝 PEGA TU URL DE GOOGLE SHEETS: " USER_URL
read -p "📞 NÚMERO (Ej: 5212223334455): " WHATSAPP_NUMBER

# Crear el .env dentro de la carpeta /bot/
echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env

header
echo "📦 PASO 3: Instalando librerías..."
npm install

header
echo "🧠 PASO 4: Configurando IA (Ollama)..."
curl -fsSL https://ollama.com/install.sh | sh
ollama serve > /dev/null 2>&1 &
sleep 8
ollama pull llama3.2:1b

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ]; then
    node bot.js
fi
