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
# INSTALACIÓN SIMPLIFICADA DE OLLAMA (SIN COMPILAR)
# ============================================
header
echo "🧠 PASO 4: Instalando Ollama (versión simplificada)..."

# Método 1: Intentar con el binario oficial para Termux (si existe)
if ! command -v ollama &> /dev/null; then
    echo "📥 Descargando Ollama para Termux..."
    
    # Crear directorio para binarios si no existe
    mkdir -p $PREFIX/bin
    
    # Descargar binario precompilado (esto puede fallar, por eso tenemos plan B)
    wget -O $PREFIX/bin/ollama https://github.com/ollama/ollama/releases/latest/download/ollama-linux-arm64 || {
        echo "⚠️ No se pudo descargar el binario. Usando método alternativo..."
        
        # Método 2: Instalar ollama desde los repositorios de Termux (si existe)
        pkg install -y ollama || {
            echo "⚠️ Ollama no está en repositorios. Instalando dependencias mínimas..."
            
            # Método 3: Usar una implementación ligera (llama.cpp)
            pkg install -y llama.cpp
            
            # Crear un script wrapper para simular ollama
            cat > $PREFIX/bin/ollama << 'EOF'
#!/bin/bash
if [ "$1" = "serve" ]; then
    llama-server --port 11434 --model $HOME/.ollama/models/blobs/llama3.2-1b.gguf &
elif [ "$1" = "pull" ]; then
    echo "Descargando modelo..."
    mkdir -p $HOME/.ollama/models/blobs
    wget -O $HOME/.ollama/models/blobs/llama3.2-1b.gguf https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf
elif [ "$1" = "list" ]; then
    ls -la $HOME/.ollama/models/blobs/
else
    $@
fi
EOF
            chmod +x $PREFIX/bin/ollama
        }
    fi
    chmod +x $PREFIX/bin/ollama 2>/dev/null || true
fi

echo "✅ Ollama configurado"

# ============================================
# INICIAR OLLAMA Y VERIFICAR
# ============================================
echo "🚀 Iniciando servidor Ollama..."

# Matar procesos previos
pkill -f "ollama" 2>/dev/null
pkill -f "llama-server" 2>/dev/null

# Iniciar según el método disponible
if command -v ollama &> /dev/null; then
    ollama serve > /dev/null 2>&1 &
elif command -v llama-server &> /dev/null; then
    llama-server --port 11434 --model $HOME/.ollama/models/blobs/llama3.2-1b.gguf > /dev/null 2>&1 &
fi

# Esperar a que inicie
echo "⏳ Esperando a que Ollama inicie..."
sleep 10

# Verificar conexión
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Servidor Ollama funcionando"
else
    echo "⚠️ No se pudo conectar con Ollama. Intentando método alternativo..."
    
    # Último intento: usar llama.cpp directamente
    if ! command -v llama-server &> /dev/null; then
        pkg install -y llama.cpp
    fi
    
    # Crear directorio para el modelo
    mkdir -p $HOME/.ollama/models/blobs
    
    # Descargar modelo si no existe
    if [ ! -f $HOME/.ollama/models/blobs/llama3.2-1b.gguf ]; then
        echo "📥 Descargando modelo (esto puede tomar varios minutos)..."
        wget -O $HOME/.ollama/models/blobs/llama3.2-1b.gguf https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf
    fi
    
    # Iniciar llama-server
    pkill -f "llama-server" 2>/dev/null
    llama-server --port 11434 --model $HOME/.ollama/models/blobs/llama3.2-1b.gguf > /dev/null 2>&1 &
    sleep 5
fi

# Prueba final
if curl -s http://localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"hola","stream":false}' > /dev/null 2>&1; then
    echo "✅ IA lista para usar"
else
    echo "⚠️ La IA podría no estar respondiendo, pero el bot intentará igual."
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
