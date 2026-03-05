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
pkg install -y git nodejs-lts wget cronie termux-services

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
# INSTALACIÓN DE OLLAMA (CON DESCARGA DEL MODELO)
# ============================================
header
echo "🧠 PASO 4: Instalando Ollama y descargando modelo (1.3GB)..."

# Verificar si Ollama está instalado
if ! command -v ollama &> /dev/null; then
    echo "📥 Instalando Ollama desde repositorio..."
    pkg install -y ollama || {
        echo "⚠️ Instalando dependencias para compilación..."
        pkg install -y golang cmake
        cd $HOME
        git clone --depth 1 https://github.com/ollama/ollama.git
        cd ollama
        go build -o ollama .
        cp ollama $PREFIX/bin/
        cd $HOME/whatsapp-bot-ventas/bot
    }
fi

# Iniciar Ollama
echo "🚀 Iniciando servidor Ollama..."
pkill -f "ollama serve" 2>/dev/null || true
ollama serve > /dev/null 2>&1 &
sleep 5

# ============================================
# DESCARGA FORZADA DEL MODELO (1.3GB)
# ============================================
echo "📥 VERIFICANDO MODELO (esto puede tomar varios minutos)..."

# Verificar si el modelo ya existe
if ollama list | grep -q "llama3.2:1b"; then
    echo "✅ Modelo ya existe"
else
    echo "⏳ DESCARGANDO MODELO DE 1.3GB..."
    echo "   Esto puede tomar 10-30 minutos dependiendo de tu internet"
    echo ""
    ollama pull llama3.2:1b
    
    # Verificar que la descarga fue exitosa
    if [ $? -eq 0 ]; then
        echo "✅ Modelo descargado correctamente"
    else
        echo "❌ Error descargando modelo. Reintentando..."
        ollama pull llama3.2:1b
    fi
fi

# Verificar que el modelo está listo
echo "🔄 Verificando que el modelo funcione..."
if curl -s http://localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"hola","stream":false}' > /dev/null; then
    echo "✅ Modelo listo para usar"
else
    echo "⚠️ El modelo no responde, reintentando..."
    sleep 5
    ollama pull llama3.2:1b
fi

# ============================================
# CONFIGURACIÓN DE ACTUALIZACIONES AUTOMÁTICAS
# ============================================
header
echo "🔄 PASO 5: Configurando actualizaciones automáticas..."

# Crear carpeta de logs si no existe
mkdir -p /storage/emulated/0/WhatsAppBot/logs

# Crear script de actualización
cat > $HOME/whatsapp-bot-ventas/actualizar.sh << 'EOF'
#!/bin/bash

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"

echo "==========================================" >> $LOG_FILE
echo "[$FECHA] INICIANDO ACTUALIZACIÓN AUTOMÁTICA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE

# 1. DETENER EL BOT
echo "[$FECHA] Deteniendo bot..." >> $LOG_FILE
pkill -f "node bot.js" 2>/dev/null
sleep 3

# 2. ACTUALIZAR DEPENDENCIAS
echo "[$FECHA] Actualizando dependencias npm..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
npm update @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra >> $LOG_FILE 2>&1
npm cache clean --force >> $LOG_FILE 2>&1

# 3. ACTUALIZAR OLLAMA (si hay nueva versión)
echo "[$FECHA] Verificando actualizaciones de Ollama..." >> $LOG_FILE
cd /data/data/com.termux/files/home
if [ -d "ollama" ]; then
    cd ollama
    git pull origin master >> $LOG_FILE 2>&1
    go build -o ollama . >> $LOG_FILE 2>&1
    cp ollama $PREFIX/bin/ >> $LOG_FILE 2>&1
fi

# 4. ACTUALIZAR EL MODELO DE IA (siempre a la última versión)
echo "[$FECHA] Actualizando modelo de IA..." >> $LOG_FILE
ollama pull llama3.2:1b >> $LOG_FILE 2>&1

# 5. VERIFICAR OLLAMA
echo "[$FECHA] Verificando servidor Ollama..." >> $LOG_FILE
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "[$FECHA] Reiniciando servidor Ollama..." >> $LOG_FILE
    pkill -f "ollama serve" 2>/dev/null
    ollama serve > /dev/null 2>&1 &
    sleep 5
fi

# 6. REINICIAR EL BOT
echo "[$FECHA] Reiniciando bot..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
nohup node bot.js > /dev/null 2>&1 &

echo "[$FECHA] ✅ ACTUALIZACIÓN COMPLETADA" >> $LOG_FILE
EOF

chmod +x $HOME/whatsapp-bot-ventas/actualizar.sh

# Configurar cron
(crontab -l 2>/dev/null; echo "0 3 * * * /data/data/com.termux/files/home/whatsapp-bot-ventas/actualizar.sh") | crontab -
sv up cron

# Agregar inicio automático de Ollama
if ! grep -q "ollama serve" $HOME/.bashrc; then
    echo 'ollama serve > /dev/null 2>&1 &' >> $HOME/.bashrc
fi

# ============================================
# VERIFICACIÓN FINAL
# ============================================
header
echo "🔍 VERIFICACIÓN FINAL..."

# Verificar modelo
echo "📦 Modelo instalado:"
ollama list

# Probar conexión
echo ""
echo "🔄 Probando respuesta de IA..."
RESPUESTA=$(curl -s -X POST http://localhost:11434/api/generate -d '{
    "model": "llama3.2:1b",
    "prompt": "Responde OK si funcionas",
    "stream": false
}' | grep -o '"response":"[^"]*"' | cut -d'"' -f4)

if [ -n "$RESPUESTA" ]; then
    echo "✅ IA responde: $RESPUESTA"
else
    echo "⚠️ IA no responde correctamente"
fi

# ============================================
# FINALIZACIÓN
# ============================================
header
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📌 URL: $USER_URL"
echo "📞 Número: $WHATSAPP_NUMBER"
echo "🧠 Modelo: llama3.2:1b (1.3GB) - INSTALADO"
echo "🔄 Actualización automática: Diaria (3:00 AM)"
echo ""
echo "📁 Logs: /storage/emulated/0/WhatsAppBot/logs/"
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
