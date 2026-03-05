#!/bin/bash

header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR BOT VENTAS v1.1"
    echo "=========================================="
}

header
echo "📦 PASO 1: Actualizando sistema e instalando dependencias..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget -y [cite: 80]

header
echo "📦 PASO 2: Descargando el repositorio..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas [cite: 80]

header
echo "🔗 CONFIGURACIÓN - URL DE GOOGLE SHEETS"
echo "------------------------------------------"
echo "1. Abre tu Google Sheets."
echo "2. Ve al menú 'Bot Ventas' > 'Instrucciones'."
echo "3. Copia la URL de la Web App."
echo "------------------------------------------"
echo ""
echo -n "📝 PEGA LA URL AQUÍ y presiona Enter: "
read USER_URL [cite: 81, 82]

# Crear archivo .env con la URL de Sheets
echo "URL_SHEETS=$USER_URL" > .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env
echo "OLLAMA_TEMPERATURE=0.7" >> .env
echo "OLLAMA_MAX_TOKENS=200" >> .env [cite: 79, 82]

header
echo "📦 PASO 3: Instalando librerías de Node.js..."
npm install [cite: 84]

header
echo "🧠 PASO 4: Configurando IA (Ollama)..."
curl -fsSL https://ollama.com/install.sh | sh
ollama serve > /dev/null 2>&1 &
sleep 5
echo "📥 Descargando modelo Llama 3.2..."
ollama pull llama3.2:1b [cite: 85]

header
echo "📱 CONFIGURACIÓN - VINCULACIÓN WHATSAPP"
echo "------------------------------------------"
echo "Introduce el número que usarás para el bot."
echo "Usa formato internacional (ej: 5212223334455)."
echo "------------------------------------------"
echo ""
echo -n "📞 NÚMERO DE TELÉFONO: "
read WHATSAPP_NUMBER [cite: 86]

# Guardar el número en el archivo .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env [cite: 86]

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
echo "Número guardado: $WHATSAPP_NUMBER"
echo "URL Sheets: $USER_URL"
echo "------------------------------------------"
echo ""
read -p "¿Deseas iniciar el bot ahora mismo? (s/n): " START_NOW

if [[ "$START_NOW" =~ ^[Ss]$ ]]; then
    npm start [cite: 87]
fi
