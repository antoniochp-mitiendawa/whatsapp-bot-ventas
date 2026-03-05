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
# INSTALACIÓN Y VERIFICACIÓN DE OLLAMA
# ============================================
header
echo "🧠 PASO 4: Instalando y configurando IA (Ollama)..."

# Instalar dependencias necesarias para Ollama
echo "📦 Instalando dependencias para Ollama..."
pkg install -y cmake golang which

# Verificar si Ollama ya está instalado
if ! command -v ollama &> /dev/null; then
    echo "⚙️  Ollama no encontrado. Instalando desde código fuente..."
    
    # Clonar y compilar Ollama
    cd $HOME
    if [ -d "ollama" ]; then
        rm -rf ollama
    fi
    
    echo "⏳ Descargando Ollama (esto puede tomar varios minutos)..."
    git clone --depth 1 https://github.com/ollama/ollama.git
    cd ollama
    
    echo "🔧 Compilando Ollama (esto puede tomar varios minutos)..."
    go generate ./...
    go build .
    
    # Mover el binario a una ubicación accesible
    cp ollama $PREFIX/bin/
    cd $HOME/whatsapp-bot-ventas/bot
    
    echo "✅ Ollama instalado correctamente"
else
    echo "✅ Ollama ya está instalado"
fi

# Función para verificar que Ollama está corriendo
verificar_ollama() {
    echo "🔄 Verificando que Ollama esté funcionando..."
    
    # Matar procesos previos de Ollama si existen
    pkill -f "ollama serve" 2>/dev/null || true
    
    # Iniciar Ollama en segundo plano
    echo "🚀 Iniciando servidor Ollama..."
    ollama serve > /dev/null 2>&1 &
    
    # Esperar a que inicie (máximo 10 segundos)
    local max_intentos=10
    local intento=0
    
    while [ $intento -lt $max_intentos ]; do
        sleep 2
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo "✅ Servidor Ollama funcionando correctamente"
            return 0
        fi
        intento=$((intento + 1))
        echo "⏳ Esperando a que Ollama inicie... (intento $intento/$max_intentos)"
    done
    
    echo "❌ Error: No se pudo iniciar el servidor Ollama"
    return 1
}

# Verificar que Ollama está corriendo
if ! verificar_ollama; then
    echo "❌ No se pudo iniciar Ollama. Intentando método alternativo..."
    
    # Método alternativo: iniciar en una terminal diferente
    nohup ollama serve > $HOME/ollama.log 2>&1 &
    sleep 5
    
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "❌ Error fatal: No se puede iniciar Ollama"
        echo "📝 Para solucionar manualmente:"
        echo "  1. Ejecuta: ollama serve &"
        echo "  2. Espera 5 segundos"
        echo "  3. Ejecuta: node bot.js"
        read -p "Presiona Enter para continuar con la instalación..."
    else
        echo "✅ Ollama iniciado correctamente (método alternativo)"
    fi
fi

# Verificar y descargar modelo
echo "📥 Verificando modelo llama3.2:1b..."
if ! ollama list | grep -q "llama3.2:1b"; then
    echo "⏳ Descargando modelo llama3.2:1b (esto puede tomar varios minutos)..."
    ollama pull llama3.2:1b
    if [ $? -eq 0 ]; then
        echo "✅ Modelo descargado correctamente"
    else
        echo "⚠️  Error descargando modelo. Se intentará de nuevo al iniciar el bot"
    fi
else
    echo "✅ Modelo ya existe"
fi

# Prueba final de conexión
echo "🔄 Probando conexión con Ollama..."
if curl -s http://localhost:11434/api/generate -d '{
    "model": "llama3.2:1b",
    "prompt": "responde OK si funcionas",
    "stream": false
}' > /dev/null 2>&1; then
    echo "✅ IA lista para usar"
else
    echo "⚠️  La IA no responde. Verifica manualmente con: curl http://localhost:11434/api/tags"
fi

# Agregar inicio automático al .bashrc para futuras sesiones
if ! grep -q "ollama serve" $HOME/.bashrc; then
    echo 'ollama serve > /dev/null 2>&1 &' >> $HOME/.bashrc
    echo "✅ Inicio automático de Ollama configurado"
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
echo "🧠 IA: Configurada y verificada"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • Ollama está corriendo en segundo plano"
echo "   • No cierres Termux sin detenerlo primero"
echo ""

read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ]; o "$START" == "S" ]; then
    echo ""
    echo "🚀 INICIANDO BOT..."
    echo "======================"
    echo ""
    # Verificar una última vez que Ollama esté vivo
    if ! curl -s http://localhost:11434/api/tags > /dev/null; then
        echo "⚠️  Ollama no responde. Intentando reiniciar..."
        ollama serve &
        sleep 5
    fi
    node bot.js
else
    echo ""
    echo "📝 Para iniciar después:"
    echo "   cd whatsapp-bot-ventas/bot"
    echo "   node bot.js"
    echo ""
    echo "⚠️  Recuerda tener Ollama corriendo: ollama serve &"
fi
