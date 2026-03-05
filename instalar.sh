#!/bin/bash

header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR LLAMA.CPP + BOT VENTAS"
    echo "=========================================="
}

header
echo "📦 PASO 1: Instalando dependencias y compiladores..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget cmake clang -y

header
echo "📦 PASO 2: Clonando proyecto..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas/bot

# CONFIGURACIÓN
header
echo "🔗 CONFIGURACIÓN DE DATOS"
read -p "📝 PEGA TU URL DE GOOGLE SHEETS: " USER_URL
read -p "📞 NÚMERO (Ej: 5212223334455): " WHATSAPP_NUMBER

echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env
echo "LLAMA_API=http://localhost:8080/v1/chat/completions" >> .env

header
echo "📦 PASO 3: Instalando librerías de Node.js..."
npm install

header
echo "🧠 PASO 4: Instalando Llama.cpp (Motor Local)..."
cd $HOME
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build
cmake --build build --config Release -j4

header
echo "📥 PASO 5: Descargando Modelo Llama-3-8B (GGUF)..."
mkdir -p models
wget -O models/model.gguf https://huggingface.co/MaziyarPanahi/Llama-3-8B-Instruct-v0.1-GGUF/resolve/main/Llama-3-8B-Instruct-v0.1.Q2_K.gguf

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
echo "Para usar el bot, primero inicia el servidor de Llama.cpp"
echo "Comando: ./llama.cpp/build/bin/llama-server -m ./llama.cpp/models/model.gguf --port 8080"
echo "------------------------------------------"
read -p "¿Deseas iniciar todo ahora? (s/n): " START
if [ "$START" == "s" ]; then
    cd $HOME/llama.cpp/build/bin/ && ./llama-server -m ../../models/model.gguf --port 8080 > /dev/null 2>&1 &
    sleep 10
    cd $HOME/whatsapp-bot-ventas/bot && node bot.js
fi
