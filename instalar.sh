#!/bin/bash

header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR AUTOMÁTICO IA LOCAL v2.0"
    echo "=========================================="
}

header
echo "📦 PASO 1: Instalando dependencias y herramientas de compilación..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget cmake clang -y

header
echo "📦 PASO 2: Descargando el Bot de Ventas..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas/bot

# CAPTURA DE DATOS
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
echo "🧠 PASO 4: Instalación Automática de Llama.cpp..."
cd $HOME
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp
    cd llama.cpp
    cmake -B build
    cmake --build build --config Release -j$(nproc)
fi

header
echo "📥 PASO 5: Descargando Modelo Inteligente (GGUF)..."
cd $HOME/llama.cpp
mkdir -p models
if [ ! -f "models/model.gguf" ]; then
    wget -O models/model.gguf https://huggingface.co/MaziyarPanahi/Llama-3-8B-Instruct-v0.1-GGUF/resolve/main/Llama-3-8B-Instruct-v0.1.Q2_K.gguf
fi

header
echo "🚀 PASO 6: Iniciando Servidor de IA en segundo plano..."
nohup ./build/bin/llama-server -m ./models/model.gguf --port 8080 --threads 4 > llama_server.log 2>&1 &
sleep 10 # Espera a que el servidor cargue el modelo en RAM

header
echo "=========================================="
echo "✅ INSTALACIÓN Y ARRANQUE COMPLETADOS"
echo "=========================================="
cd $HOME/whatsapp-bot-ventas/bot && node bot.js
