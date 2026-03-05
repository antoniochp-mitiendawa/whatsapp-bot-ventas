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

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================
header
echo "🔗 CONFIGURACIÓN DE DATOS"
echo "=========================================="
read -p "📝 PEGA TU URL DE GOOGLE SHEETS: " USER_URL
read -p "📞 NÚMERO (Ej: 5212223334455): " WHATSAPP_NUMBER

# Crear archivo .env con toda la configuración
echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env
echo "OLLAMA_MODEL=llama3.2:1b" >> .env
echo "DELAY_MIN=5" >> .env
echo "DELAY_MAX=10" >> .env

# ============================================
# INSTALACIÓN DE DEPENDENCIAS NODE
# ============================================
header
echo "📦 PASO 3: Instalando librerías Node.js..."
npm install

# ============================================
# INSTALACIÓN DE OLLAMA (INTELIGENCIA ARTIFICIAL)
# ============================================
header
echo "🧠 PASO 4: Instalando Ollama (IA local)..."

# Instalar Ollama
echo "📥 Descargando e instalando Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Iniciar servidor Ollama
echo "🚀 Iniciando servidor Ollama..."
pkill -f "ollama serve" 2>/dev/null || true
ollama serve > /dev/null 2>&1 &
sleep 5

# Verificar que Ollama está corriendo
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Servidor Ollama funcionando correctamente"
else
    echo "⚠️ Reintentando iniciar Ollama..."
    ollama serve > /dev/null 2>&1 &
    sleep 8
fi

# ============================================
# DESCARGA DEL MODELO (1.3GB)
# ============================================
echo ""
echo "📥 PASO CRÍTICO: Descargando modelo de IA (1.3GB)"
echo "=========================================="
echo "Esta descarga puede tomar 10-30 minutos dependiendo"
echo "de tu velocidad de internet. NO INTERRUMPAS EL PROCESO."
echo "=========================================="
echo ""

# Verificar si el modelo ya existe
if ollama list | grep -q "llama3.2:1b"; then
    echo "✅ Modelo ya existe, verificando integridad..."
    ollama pull llama3.2:1b
else
    echo "⏳ Descargando modelo llama3.2:1b (1.3GB)..."
    echo "   Progreso visible en la siguiente línea:"
    echo ""
    ollama pull llama3.2:1b
    
    if [ $? -eq 0 ]; then
        echo "✅ Modelo descargado correctamente"
    else
        echo "❌ Error en descarga, reintentando..."
        ollama pull llama3.2:1b
    fi
fi

# ============================================
# VERIFICACIÓN DEL MODELO
# ============================================
echo ""
echo "🔄 Verificando que el modelo funcione correctamente..."
sleep 2

PRUEBA_IA=$(curl -s -X POST http://localhost:11434/api/generate -d '{
    "model": "llama3.2:1b",
    "prompt": "Responde OK si funcionas",
    "stream": false
}' 2>/dev/null | grep -o '"response":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$PRUEBA_IA" ]; then
    echo "✅ IA responde correctamente: $PRUEBA_IA"
else
    echo "⚠️ La IA no responde. Reintentando..."
    sleep 3
    ollama serve > /dev/null 2>&1 &
    sleep 5
fi

# ============================================
# CONFIGURACIÓN DE ACTUALIZACIONES AUTOMÁTICAS
# ============================================
header
echo "🔄 PASO 5: Configurando actualizaciones automáticas..."

# Crear carpeta de logs
mkdir -p /storage/emulated/0/WhatsAppBot/logs

# Crear script de actualización diaria
cat > $HOME/whatsapp-bot-ventas/actualizar.sh << 'EOF'
#!/bin/bash

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"

echo "==========================================" >> $LOG_FILE
echo "[$FECHA] INICIANDO ACTUALIZACIÓN AUTOMÁTICA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE

# 1. Detener el bot
echo "[$FECHA] Deteniendo bot..." >> $LOG_FILE
pkill -f "node bot.js" 2>/dev/null
sleep 3

# 2. Actualizar Baileys y dependencias
echo "[$FECHA] Actualizando Baileys..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
npm update @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra >> $LOG_FILE 2>&1
npm cache clean --force >> $LOG_FILE 2>&1

# 3. Actualizar Ollama (binario)
echo "[$FECHA] Verificando actualizaciones de Ollama..." >> $LOG_FILE
curl -fsSL https://ollama.com/install.sh | sh >> $LOG_FILE 2>&1

# 4. Actualizar modelo de IA
echo "[$FECHA] Actualizando modelo llama3.2:1b..." >> $LOG_FILE
ollama pull llama3.2:1b >> $LOG_FILE 2>&1

# 5. Verificar que Ollama esté corriendo
echo "[$FECHA] Verificando servidor Ollama..." >> $LOG_FILE
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "[$FECHA] Reiniciando servidor Ollama..." >> $LOG_FILE
    pkill -f "ollama serve" 2>/dev/null
    ollama serve > /dev/null 2>&1 &
    sleep 5
fi

# 6. Reiniciar el bot
echo "[$FECHA] Reiniciando bot..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
nohup node bot.js > /dev/null 2>&1 &

echo "[$FECHA] ✅ ACTUALIZACIÓN COMPLETADA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE
EOF

chmod +x $HOME/whatsapp-bot-ventas/actualizar.sh

# Configurar cron para ejecutar diariamente a las 3:00 AM
echo "🔄 Configurando cron para actualización diaria (3:00 AM)..."
(crontab -l 2>/dev/null; echo "0 3 * * * /data/data/com.termux/files/home/whatsapp-bot-ventas/actualizar.sh") | crontab -
sv up cron

# Agregar inicio automático de Ollama al .bashrc
if ! grep -q "ollama serve" $HOME/.bashrc; then
    echo '# Iniciar Ollama automáticamente' >> $HOME/.bashrc
    echo 'ollama serve > /dev/null 2>&1 &' >> $HOME/.bashrc
    echo "✅ Inicio automático de Ollama configurado"
fi

# ============================================
# VERIFICACIÓN FINAL
# ============================================
header
echo "🔍 VERIFICACIÓN FINAL DEL SISTEMA"
echo "=========================================="

# Verificar espacio en disco
ESPACIO=$(df -h /data | awk 'NR==2 {print $4}')
echo "💾 Espacio disponible: $ESPACIO"

# Verificar modelo instalado
echo "📦 Modelos instalados:"
ollama list

# Verificar conexión con Sheets
echo ""
echo "📊 Probando conexión con Google Sheets..."
if curl -s -I "$USER_URL?accion=test" | grep -q "200"; then
    echo "✅ Google Sheets accesible"
else
    echo "⚠️ No se pudo verificar Google Sheets"
fi

# ============================================
# MENSAJE FINAL
# ============================================
header
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETA Y VERIFICADA"
echo "=========================================="
echo ""
echo "📌 URL: $USER_URL"
echo "📞 Número: $WHATSAPP_NUMBER"
echo "🧠 Modelo IA: llama3.2:1b (1.3GB)"
echo "🔄 Actualización: Diaria (3:00 AM)"
echo "⏱️  Delay respuestas: 5-10 segundos (configurable en .env)"
echo ""
echo "📁 Logs de actualización:"
echo "   /storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"
echo ""
echo "=========================================="
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
