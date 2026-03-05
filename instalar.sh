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
# INSTALACIÓN DE OLLAMA
# ============================================
header
echo "🧠 PASO 4: Instalando Ollama..."

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

# Descargar modelo
echo "📥 Verificando modelo..."
if ! ollama list | grep -q "llama3.2:1b"; then
    echo "⏳ Descargando modelo llama3.2:1b..."
    ollama pull llama3.2:1b
fi

# ============================================
# CONFIGURACIÓN DE ACTUALIZACIONES AUTOMÁTICAS
# ============================================
header
echo "🔄 PASO 5: Configurando actualizaciones automáticas..."

# Crear carpeta de logs si no existe
mkdir -p /storage/emulated/0/WhatsAppBot/logs

# Crear script de actualización COMPLETO (con todo incluido)
cat > $HOME/whatsapp-bot-ventas/actualizar.sh << 'EOF'
#!/bin/bash

FECHA=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"

echo "==========================================" >> $LOG_FILE
echo "[$FECHA] INICIANDO ACTUALIZACIÓN AUTOMÁTICA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE

# 1. DETENER EL BOT SI ESTÁ CORRIENDO
echo "[$FECHA] Deteniendo bot..." >> $LOG_FILE
pkill -f "node bot.js" 2>/dev/null
sleep 3

# 2. ACTUALIZAR BAILEYS Y DEPENDENCIAS NPM
echo "[$FECHA] Actualizando Baileys y dependencias..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
npm update @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra >> $LOG_FILE 2>&1
npm cache clean --force >> $LOG_FILE 2>&1
echo "[$FECHA] ✅ Dependencias npm actualizadas" >> $LOG_FILE

# 3. ACTUALIZAR OLLAMA (LA INTELIGENCIA ARTIFICIAL)
echo "[$FECHA] Verificando actualizaciones de Ollama..." >> $LOG_FILE

# Verificar si hay nueva versión de Ollama
cd /data/data/com.termux/files/home
if [ -d "ollama" ]; then
    echo "[$FECHA] Ollama ya está instalado, verificando actualizaciones..." >> $LOG_FILE
    cd ollama
    git pull origin master >> $LOG_FILE 2>&1
    go build -o ollama . >> $LOG_FILE 2>&1
    cp ollama $PREFIX/bin/ >> $LOG_FILE 2>&1
    echo "[$FECHA] ✅ Ollama binario actualizado" >> $LOG_FILE
else
    echo "[$FECHA] ⚠️ Ollama no encontrado para actualizar" >> $LOG_FILE
fi

# 4. ACTUALIZAR EL MODELO DE IA (siempre a la última versión)
echo "[$FECHA] Actualizando modelo llama3.2:1b..." >> $LOG_FILE
ollama pull llama3.2:1b >> $LOG_FILE 2>&1
echo "[$FECHA] ✅ Modelo de IA actualizado/verificado" >> $LOG_FILE

# 5. VERIFICAR QUE OLLAMA ESTÉ CORRIENDO
echo "[$FECHA] Verificando servidor Ollama..." >> $LOG_FILE
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "[$FECHA] Reiniciando servidor Ollama..." >> $LOG_FILE
    pkill -f "ollama serve" 2>/dev/null
    ollama serve > /dev/null 2>&1 &
    sleep 5
fi

# 6. LIMPIAR ARCHIVOS TEMPORALES
echo "[$FECHA] Limpiando archivos temporales..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
rm -f *.log.old 2>/dev/null

# 7. REINICIAR EL BOT
echo "[$FECHA] Reiniciando bot..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
nohup node bot.js > /dev/null 2>&1 &

echo "[$FECHA] ✅ ACTUALIZACIÓN COMPLETADA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE
EOF

# Hacer ejecutable el script
chmod +x $HOME/whatsapp-bot-ventas/actualizar.sh

# Configurar cron para ejecutar diariamente a las 3:00 AM
echo "🔄 Configurando cron para actualización diaria..."
(crontab -l 2>/dev/null; echo "0 3 * * * /data/data/com.termux/files/home/whatsapp-bot-ventas/actualizar.sh") | crontab -
sv up cron

# Agregar inicio automático de Ollama al .bashrc
if ! grep -q "ollama serve" $HOME/.bashrc; then
    echo 'ollama serve > /dev/null 2>&1 &' >> $HOME/.bashrc
    echo "✅ Inicio automático de Ollama configurado"
fi

# ============================================
# VERIFICACIÓN FINAL
# ============================================
header
echo "🔍 VERIFICANDO INSTALACIÓN..."

# Verificar Ollama
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama: Funcionando correctamente"
else
    echo "⚠️ Ollama: No responde, intentando reiniciar..."
    ollama serve &
    sleep 3
fi

# Verificar modelo
if ollama list | grep -q "llama3.2:1b"; then
    echo "✅ Modelo IA: Instalado (llama3.2:1b)"
else
    echo "⚠️ Modelo IA: No encontrado, descargando..."
    ollama pull llama3.2:1b &
fi

# Verificar cron
if crontab -l | grep -q "actualizar.sh"; then
    echo "✅ Actualización automática: Configurada (3:00 AM)"
else
    echo "⚠️ Actualización automática: No configurada"
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
echo "🔄 Actualización automática: Diaria (3:00 AM)"
echo "   • Baileys y dependencias npm"
echo "   • Ollama (binario y modelo)"
echo ""
echo "📁 Logs de actualización:"
echo "   /storage/emulated/0/WhatsAppBot/logs/actualizaciones.log"
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
