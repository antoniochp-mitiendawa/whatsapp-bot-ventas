#!/bin/bash

# Función de encabezado
header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR BOT VENTAS v1.1"
    echo "=========================================="
}

header
echo "📦 PASO 1: Instalando dependencias del sistema..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget -y

header
echo "📦 PASO 2: Descargando el bot..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# --- DETENCIÓN 1: URL DE GOOGLE SHEETS ---
header
echo "🔗 CONFIGURACIÓN - GOOGLE SHEETS"
echo "1. Ve a tu Google Sheets > Bot Ventas > Instrucciones."
echo "2. Copia la URL de implementación (Web App)."
echo "------------------------------------------"
echo -n "📝 PEGA LA URL AQUÍ y presiona Enter: "
read USER_URL

# Crear archivo .env base
echo "URL_SHEETS=$USER_URL" > .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env
echo "OLLAMA_TEMPERATURE=0.7" >> .env

header
echo "📦 PASO 3: Instalando librerías de Node.js..."
npm install

header
echo "🧠 PASO 4: Configurando IA (Ollama)..."
curl -fsSL https://ollama.com/install.sh | sh
ollama serve > /dev/null 2>&1 &
sleep 5
echo "📥 Descargando modelo Llama 3.2..."
ollama pull llama3.2:1b

# --- DETENCIÓN 2: NÚMERO DE TELÉFONO ---
header
echo "📱 CONFIGURACIÓN - WHATSAPP"
echo "Introduce el número (ej: 5212223334455)"
echo "------------------------------------------"
echo -n "📞 NÚMERO DE TELÉFONO: "
read WHATSAPP_NUMBER

# Guardar el número en el .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
echo "URL: $USER_URL"
echo "Número: $WHATSAPP_NUMBER"
echo "------------------------------------------"
echo ""
read -p "¿Iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ]; then
    node bot.js
fi
