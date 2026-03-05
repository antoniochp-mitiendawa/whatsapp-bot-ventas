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
pkg install -y git nodejs-lts wget

header
echo "📦 PASO 2: Clonando proyecto desde GitHub..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas/bot

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

# ============================================
# INSTALACIÓN SIMPLIFICADA DE OLLAMA
# ============================================
header
echo "🧠 PASO 4: Instalando Ollama..."

# Verificar si ya está instalado
if ! command -v ollama &> /dev/null; then
    echo "📥 Instalando Ollama desde repositorio..."
    
    # Intentar instalar desde repositorio de Termux
    if pkg install -y ollama; then
        echo "✅ Ollama instalado desde repositorio"
    else
        echo "⚠️ No disponible en repositorio, usando método alternativo..."
        
        # Instalar dependencias para compilación rápida
        pkg install -y golang
        
        # Clonar y compilar (versión mínima)
        cd $HOME
        git clone --depth 1 https://github.com/ollama/ollama.git
        cd ollama
        go build -o ollama .
        cp ollama $PREFIX/bin/
        cd $HOME/whatsapp-bot-ventas/bot
    fi
fi

# ============================================
# INICIAR OLLAMA
# ============================================
echo "🚀 Iniciando servidor Ollama..."

# Matar procesos previos
pkill -f "ollama serve" 2>/dev/null || true

# Iniciar servidor
ollama serve > /dev/null 2>&1 &
sleep 5

# Verificar que está corriendo
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Servidor Ollama funcionando"
else
    echo "⚠️ Error al iniciar Ollama, intentando de nuevo..."
    ollama serve &
    sleep 5
fi

# Descargar modelo
echo "📥 Verificando modelo..."
if ! ollama list | grep -q "llama3.2:1b"; then
    echo "⏳ Descargando modelo (esto puede tomar varios minutos)..."
    ollama pull llama3.2:1b
fi

# Prueba final
echo "🔄 Probando conexión con IA..."
if curl -s http://localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"hola","stream":false}' > /dev/null 2>&1; then
    echo "✅ IA lista para usar"
else
    echo "⚠️ La IA no responde, pero el bot intentará igual"
fi

# ============================================
# FINALIZACIÓN
# ============================================
header
echo "=========================================="
echo "✅ INSTALACIÓN FINALIZADA"
echo "=========================================="
echo ""
echo "📌 URL: $USER_URL"
echo "📞 Número: $WHATSAPP_NUMBER"
echo ""

read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ] || [ "$START" == "S" ]; then
    echo ""
    echo "🚀 INICIANDO BOT..."
    echo "======================"
    echo ""
    node bot.js
else
    echo ""
    echo "📝 Para iniciar después:"
    echo "   cd whatsapp-bot-ventas/bot"
    echo "   node bot.js"
    echo ""
fi
