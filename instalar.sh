#!/bin/bash

# Función para limpiar pantalla y mostrar encabezado
header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR BOT VENTAS v1.1"
    echo "=========================================="
}

header
echo "📦 PASO 1: Actualizando sistema e instalando dependencias..."
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts wget -y

# PASO 2: Clonar repositorio
header
echo "📦 PASO 2: Descargando el repositorio..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# ============================================
# PASO 3: DETENCIÓN PARA URL DE GOOGLE SHEETS
# ============================================
header
echo "🔗 CONFIGURACIÓN - URL DE GOOGLE SHEETS"
echo "------------------------------------------"
echo "1. Abre tu Google Sheets."
echo "2. Ve al menú 'Bot Ventas' > 'Instrucciones'."
echo "3. Copia la URL de la API (Web App)."
echo "------------------------------------------"
echo ""
echo -n "📝 PEGA LA URL AQUÍ y presiona Enter: "
read USER_URL

# Crear archivo .env inicial
echo "URL_SHEETS=$USER_URL" > .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env
echo "OLLAMA_TEMPERATURE=0.7" >> .env
echo "OLLAMA_MAX_TOKENS=200" >> .env

# PASO 4: Instalación de dependencias de Node
header
echo "📦 PASO 3: Instalando librerías de Node.js..."
npm install

# PASO 5: Configuración de Ollama (IA)
header
echo "🧠 PASO 4: Configurando IA (Ollama)..."
curl -fsSL https://ollama.com/install.sh | sh
# Iniciamos ollama en segundo plano
ollama serve > /dev/null 2>&1 &
sleep 5
echo "📥 Descargando modelo Llama 3.2..."
ollama pull llama3.2:1b

# ============================================
# PASO 6: DETENCIÓN PARA PAIRING CODE (WHATSAPP)
# ============================================
header
echo "📱 CONFIGURACIÓN - VINCULACIÓN WHATSAPP"
echo "------------------------------------------"
echo "Introduce el número que usarás para el bot."
echo "Usa formato internacional sin símbolos (ej: 5212223334455)."
echo "------------------------------------------"
echo ""
echo -n "📞 NÚMERO DE TELÉFONO: "
read WHATSAPP_NUMBER

# Guardar el número en el archivo de configuración .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env

header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
echo "Número guardado: $WHATSAPP_NUMBER"
echo "URL Sheets guardada: $USER_URL"
echo "------------------------------------------"
echo ""
read -p "¿Deseas iniciar el bot ahora mismo? (s/n): " START_NOW

if [[ "$START_NOW" =~ ^[Ss]$ ]]; then
    npm start
fi
