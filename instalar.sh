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
cd whatsapp-bot-ventas

# DETENCIÓN PARA GOOGLE SHEETS
header
echo "🔗 CONFIGURACIÓN DE DATOS"
echo "------------------------------------------"
read -p "📝 PEGA TU URL DE GOOGLE SHEETS: " USER_URL

# DETENCIÓN PARA WHATSAPP
echo ""
echo "📱 VINCULACIÓN DE WHATSAPP"
echo "------------------------------------------"
read -p "📞 NÚMERO (Ej: 5212223334455): " WHATSAPP_NUMBER

# CREACIÓN DEL ARCHIVO .ENV (EL CORAZÓN DEL BOT)
echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env

header
echo "📦 PASO 3: Instalando librerías de Node.js..."
npm install

header
echo "🧠 PASO 4: Instalando y configurando Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
# Iniciar servidor de Ollama en segundo plano
ollama serve > /dev/null 2>&1 &
sleep 8
echo "📥 Descargando modelo de IA (Llama 3.2)..."
ollama pull llama3.2:1b

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA CON ÉXITO"
echo "=========================================="
echo "El sistema está listo para vincular."
echo ""
read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ]; then
    node bot.js
fi
