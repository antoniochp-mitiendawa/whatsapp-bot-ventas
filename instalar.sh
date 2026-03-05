#!/bin/bash

header() {
    clear
    echo "=========================================="
    echo "🚀 INSTALADOR BOT VENTAS - TINYLLAMA"
    echo "=========================================="
}

header
echo "📦 PASO 1: Preparando entorno de Termux..."
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts wget cronie termux-services cmake make

header
echo "📦 PASO 2: Clonando repositorio..."
cd $HOME
rm -rf whatsapp-bot-ventas
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================
header
echo "🔗 CONFIGURACIÓN DE DATOS"
echo "=========================================="
read -p "📝 PEGA TU URL DE GOOGLE SHEETS: " USER_URL
read -p "📞 NÚMERO (Ej: 5212223334455): " WHATSAPP_NUMBER

# Crear estructura y archivos de configuración
mkdir -p bot
cd bot

# Crear .env
echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env

# ============================================
# INSTALACIÓN DE DEPENDENCIAS NODE
# ============================================
header
echo "📦 PASO 3: Instalando librerías Node.js..."
npm init -y
npm install @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra qrcode-terminal node-cron

# ============================================
# INSTALACIÓN DE LLAMA.CPP Y TINYLLAMA
# ============================================
header
echo "🧠 PASO 4: Instalando llama.cpp y modelo TinyLlama..."

cd $HOME/whatsapp-bot-ventas
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

echo "🔧 Compilando llama.cpp..."
make -j4

# Descargar modelo TinyLlama (780MB)
cd models
echo "📥 Descargando modelo TinyLlama (780MB) - esto puede tomar varios minutos..."
wget -O tinyllama-1.1b-chat.Q4_K_M.gguf https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

if [ ! -f tinyllama-1.1b-chat.Q4_K_M.gguf ]; then
    echo "⚠️ Error con wget, intentando con curl..."
    curl -L -o tinyllama-1.1b-chat.Q4_K_M.gguf https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
fi

cd $HOME/whatsapp-bot-ventas

# ============================================
# CREAR SCRIPT DE INICIO RÁPIDO
# ============================================
cat > bot/iniciar.sh << 'EOF'
#!/bin/bash
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
node bot.js
EOF
chmod +x bot/iniciar.sh

# ============================================
# CONFIGURACIÓN DE ACTUALIZACIONES AUTOMÁTICAS
# ============================================
header
echo "🔄 PASO 5: Configurando actualizaciones automáticas..."

mkdir -p /storage/emulated/0/WhatsAppBot/logs

cat > $HOME/whatsapp-bot-ventas/actualizar.sh << 'EOF'
#!/bin/bash
FECHA=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"

echo "[$FECHA] Iniciando actualización..." >> $LOG_FILE

# Detener bot
pkill -f "node bot.js" 2>/dev/null
sleep 2

# Actualizar dependencias
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
npm update >> $LOG_FILE 2>&1

# Recompilar llama.cpp (opcional)
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/llama.cpp
git pull >> $LOG_FILE 2>&1
make -j4 >> $LOG_FILE 2>&1

echo "[$FECHA] Actualización completada" >> $LOG_FILE
EOF

chmod +x $HOME/whatsapp-bot-ventas/actualizar.sh

# Configurar cron
(crontab -l 2>/dev/null; echo "0 3 * * * /data/data/com.termux/files/home/whatsapp-bot-ventas/actualizar.sh") | crontab -
sv up cron

# ============================================
# VERIFICACIÓN FINAL
# ============================================
header
echo "🔍 VERIFICANDO INSTALACIÓN..."

if [ -f "$HOME/whatsapp-bot-ventas/llama.cpp/models/tinyllama-1.1b-chat.Q4_K_M.gguf" ]; then
    TAMANO=$(ls -lh "$HOME/whatsapp-bot-ventas/llama.cpp/models/tinyllama-1.1b-chat.Q4_K_M.gguf" | awk '{print $5}')
    echo "✅ Modelo TinyLlama instalado: $TAMANO"
else
    echo "❌ Error: Modelo no encontrado"
fi

# ============================================
# MENSAJE FINAL
# ============================================
header
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📌 URL: $USER_URL"
echo "📞 Número: $WHATSAPP_NUMBER"
echo "🧠 Modelo: TinyLlama (780MB)"
echo "🔄 Actualización: Diaria (3:00 AM)"
echo ""
echo "🚀 PARA INICIAR EL BOT:"
echo "   cd ~/whatsapp-bot-ventas/bot"
echo "   node bot.js"
echo ""
echo "📱 IMPORTANTE:"
echo "   • El bot usará PAIRING (código), NO QR"
echo "   • Se generará un código de 8 dígitos"
echo "   • Ingresa el código en WhatsApp → Vincular dispositivo"
echo ""
echo "=========================================="

read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ] || [ "$START" == "S" ]; then
    echo ""
    echo "🚀 INICIANDO BOT..."
    echo "======================"
    cd $HOME/whatsapp-bot-ventas/bot
    node bot.js
fi
