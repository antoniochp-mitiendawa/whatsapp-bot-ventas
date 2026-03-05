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
pkg install -y git nodejs-lts wget cronie termux-services cmake make gcc g++

header
echo "📦 PASO 2: Instalando dependencias para compilación..."
pkg install -y clang binutils libxml2 libxslt python ndk-sysroot

header
echo "📦 PASO 3: Clonando proyecto base desde GitHub..."
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

# Crear estructura de carpetas
mkdir -p bot
cd bot

# Crear archivo .env con toda la configuración
echo "URL_SHEETS=$USER_URL" > .env
echo "PAIRING_NUMBER=$WHATSAPP_NUMBER" >> .env

# ============================================
# INSTALACIÓN DE DEPENDENCIAS NODE
# ============================================
header
echo "📦 PASO 4: Instalando librerías Node.js base..."
npm init -y
npm install @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra

# ============================================
# INSTALACIÓN DE BAILEYS.CPP Y LLAMA.CPP
# ============================================
header
echo "🧠 PASO 5: Instalando Baileys.cpp (IA local)..."

# Volver a la raíz del proyecto
cd $HOME/whatsapp-bot-ventas

# Clonar Baileys.cpp
echo "📥 Clonando Baileys.cpp..."
git clone https://github.com/HirCoir/Baileys.cpp.git
cd Baileys.cpp

# Instalar dependencias de Baileys.cpp
echo "📦 Instalando dependencias de Baileys.cpp..."
yarn install

# Clonar Llama.cpp dentro de Baileys.cpp
echo "📥 Clonando Llama.cpp..."
git clone https://github.com/ggerganov/llama.cpp.git

# Compilar Llama.cpp
echo "🔧 Compilando Llama.cpp (esto puede tomar varios minutos)..."
cd llama.cpp
mkdir -p build
cd build
cmake ..
make -j4
cd $HOME/whatsapp-bot-ventas/Baileys.cpp

# ============================================
# DESCARGA DEL MODELO VICUNA (4GB)
# ============================================
header
echo "📥 PASO 6: Descargando modelo Vicuna (4GB)"
echo "=========================================="
echo "Esta descarga puede tomar 20-40 minutos dependiendo"
echo "de tu velocidad de internet. NO INTERRUMPAS EL PROCESO."
echo "=========================================="
echo ""

cd $HOME/whatsapp-bot-ventas/Baileys.cpp/llama.cpp

# Descargar modelo Vicuna
echo "⏳ Descargando modelo ggml-vicuna-7b-1.1-q4_0.bin (4GB)..."
wget -O models/ggml-vicuna-7b-1.1-q4_0.bin https://huggingface.co/CRD716/ggml-vicuna-1.1-quantized/resolve/main/ggml-vicuna-7b-1.1-q4_0.bin

if [ $? -eq 0 ]; then
    echo "✅ Modelo descargado correctamente"
else
    echo "⚠️ Error en descarga, reintentando con método alternativo..."
    curl -L -o models/ggml-vicuna-7b-1.1-q4_0.bin https://huggingface.co/CRD716/ggml-vicuna-1.1-quantized/resolve/main/ggml-vicuna-7b-1.1-q4_0.bin
fi

# ============================================
# CONFIGURACIÓN DEL BOT PRINCIPAL
# ============================================
header
echo "⚙️ PASO 7: Configurando integración con Baileys.cpp..."

# Crear el archivo de personalidad del bot
cat > $HOME/whatsapp-bot-ventas/Baileys.cpp/Example/example.ts << 'EOF'
import makeWASocket from '../src';
import { downloadContentFromMessage } from '../src';
import * as fs from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import axios from 'axios';

// Configuración
const maxProcesses = 1;
let currentProcesses = 0;
const IGNORED_NUMBERS: string[] = [];
const SHEETS_URL = process.env.URL_SHEETS || '';
const DATOS_LOCALES = '/data/data/com.termux/files/home/whatsapp-bot-ventas/bot/datos_tienda.json';

// Función para cargar datos de la tienda
function cargarDatosTienda() {
    try {
        if (fs.existsSync(DATOS_LOCALES)) {
            return JSON.parse(fs.readFileSync(DATOS_LOCALES, 'utf8'));
        }
    } catch (e) {
        console.log('Error cargando datos locales:', e);
    }
    return { empresa: {}, productos: [] };
}

// Función para construir prompt con contexto de la tienda
function construirPrompt(texto: string): string {
    const datos = cargarDatosTienda();
    let prompt = "Eres un asistente de ventas amable y servicial.\n\n";
    
    if (datos.empresa) {
        prompt += "INFORMACIÓN DE LA TIENDA:\n";
        for (let [key, value] of Object.entries(datos.empresa)) {
            if (value && key !== 'prompt_sistema') {
                prompt += `${key}: ${value}\n`;
            }
        }
        prompt += "\n";
    }
    
    if (datos.productos && datos.productos.length > 0) {
        prompt += "PRODUCTOS DISPONIBLES:\n";
        datos.productos.forEach((p: any) => {
            if (p.Activo === 'SI') {
                prompt += `- ${p.Nombre}: ${p.Precio} (Stock: ${p.Stock})\n`;
            }
        });
        prompt += "\n";
    }
    
    prompt += `Cliente: ${texto}\n`;
    prompt += `Asistente: `;
    
    return prompt;
}

// Configuración del socket
const sock = makeWASocket({
    auth: {
        creds: {},
        keys: {}
    },
    printQRInTerminal: true,
    browser: ["Baileys.cpp", "Chrome", "1.0.0"]
});

// Evento de mensajes
sock.ev.on('messages.upsert', async ({ messages }) => {
    const m = messages[0];
    if (!m.message || m.key.fromMe) return;
    
    const jid = m.key.remoteJid!;
    if (jid.includes('@g.us')) return;
    if (IGNORED_NUMBERS.includes(jid.split('@')[0])) return;
    
    const text = m.message.conversation || 
                 m.message.extendedTextMessage?.text || '';
    
    if (!text) return;
    
    console.log(`📩 Mensaje de ${jid}: ${text}`);
    
    if (currentProcesses >= maxProcesses) {
        await sock.sendMessage(jid, { 
            text: '🔄 Estoy procesando otra solicitud, espera un momento.' 
        });
        return;
    }
    
    currentProcesses++;
    
    try {
        // Construir prompt con datos de la tienda
        const prompt = construirPrompt(text);
        
        // Guardar prompt en archivo temporal
        fs.writeFileSync('/tmp/prompt.txt', prompt);
        
        // Ejecutar Llama.cpp con el modelo Vicuna
        exec(`cd ${__dirname}/../llama.cpp && ./build/bin/main -m models/ggml-vicuna-7b-1.1-q4_0.bin -f /tmp/prompt.txt -n 150 --temp 0.7`, 
            async (error, stdout, stderr) => {
                if (error) {
                    console.error('Error ejecutando Llama.cpp:', error);
                    await sock.sendMessage(jid, { 
                        text: 'Lo siento, tengo problemas técnicos. Un asesor humano te atenderá en breve.' 
                    });
                } else {
                    // Extraer la respuesta (eliminar el prompt)
                    const respuesta = stdout.replace(prompt, '').trim().split('\n')[0];
                    await sock.sendMessage(jid, { text: respuesta });
                }
                currentProcesses--;
            });
            
    } catch (error) {
        console.error('Error:', error);
        await sock.sendMessage(jid, { 
            text: 'Error procesando tu mensaje. Intenta de nuevo.' 
        });
        currentProcesses--;
    }
});

console.log('✅ Bot con Baileys.cpp iniciado');
EOF

# ============================================
# CONFIGURACIÓN DE ACTUALIZACIONES AUTOMÁTICAS
# ============================================
header
echo "🔄 PASO 8: Configurando actualizaciones automáticas..."

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

# 1. Detener procesos
echo "[$FECHA] Deteniendo procesos..." >> $LOG_FILE
pkill -f "node" 2>/dev/null
sleep 3

# 2. Actualizar Baileys y dependencias
echo "[$FECHA] Actualizando dependencias npm..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/bot
npm update @whiskeysockets/baileys @hapi/boom axios pino dotenv fs-extra >> $LOG_FILE 2>&1

# 3. Actualizar Baileys.cpp
echo "[$FECHA] Actualizando Baileys.cpp..." >> $LOG_FILE
cd /data/data/com.termux/files/home/whatsapp-bot-ventas/Baileys.cpp
git pull origin master >> $LOG_FILE 2>&1
yarn install >> $LOG_FILE 2>&1

# 4. Actualizar Llama.cpp
echo "[$FECHA] Actualizando Llama.cpp..." >> $LOG_FILE
cd llama.cpp
git pull origin master >> $LOG_FILE 2>&1
cd build
cmake .. >> $LOG_FILE 2>&1
make -j4 >> $LOG_FILE 2>&1

echo "[$FECHA] ✅ ACTUALIZACIÓN COMPLETADA" >> $LOG_FILE
echo "==========================================" >> $LOG_FILE
EOF

chmod +x $HOME/whatsapp-bot-ventas/actualizar.sh

# Configurar cron para ejecutar diariamente a las 3:00 AM
(crontab -l 2>/dev/null; echo "0 3 * * * /data/data/com.termux/files/home/whatsapp-bot-ventas/actualizar.sh") | crontab -
sv up cron

# ============================================
# VERIFICACIÓN FINAL
# ============================================
header
echo "🔍 VERIFICACIÓN FINAL DEL SISTEMA"
echo "=========================================="

# Verificar espacio en disco
ESPACIO=$(df -h /data | awk 'NR==2 {print $4}')
echo "💾 Espacio disponible: $ESPACIO"
echo "   (Necesitas al menos 5GB libres)"

# Verificar modelo descargado
if [ -f "$HOME/whatsapp-bot-ventas/Baileys.cpp/llama.cpp/models/ggml-vicuna-7b-1.1-q4_0.bin" ]; then
    TAMANO=$(ls -lh "$HOME/whatsapp-bot-ventas/Baileys.cpp/llama.cpp/models/ggml-vicuna-7b-1.1-q4_0.bin" | awk '{print $5}')
    echo "✅ Modelo Vicuna instalado: $TAMANO"
else
    echo "❌ Modelo no encontrado. Revisa la descarga manualmente."
fi

# ============================================
# MENSAJE FINAL
# ============================================
header
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETA - BAILEYS.CPP"
echo "=========================================="
echo ""
echo "📌 URL: $USER_URL"
echo "📞 Número: $WHATSAPP_NUMBER"
echo "🧠 IA: Baileys.cpp + Vicuna (4GB)"
echo "🔄 Actualización: Diaria (3:00 AM)"
echo ""
echo "📁 Ubicaciones importantes:"
echo "   • Bot principal: ~/whatsapp-bot-ventas/bot/"
echo "   • Baileys.cpp: ~/whatsapp-bot-ventas/Baileys.cpp/"
echo "   • Modelo Vicuna: ~/whatsapp-bot-ventas/Baileys.cpp/llama.cpp/models/"
echo "   • Logs: /storage/emulated/0/WhatsAppBot/logs/"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • La primera ejecución puede tardar en cargar el modelo"
echo "   • El bot ignorará mensajes de grupos automáticamente"
echo "   • Los datos de Sheets se guardan localmente en bot/datos_tienda.json"
echo ""
echo "=========================================="
echo ""

read -p "¿Deseas iniciar el bot ahora? (s/n): " START
if [ "$START" == "s" ] || [ "$START" == "S" ]; then
    echo ""
    echo "🚀 INICIANDO BOT CON BAILEYS.CPP..."
    echo "======================"
    echo ""
    echo "📱 Se generará un código QR. Escanéalo con WhatsApp."
    echo ""
    cd $HOME/whatsapp-bot-ventas/Baileys.cpp
    yarn example
else
    echo ""
    echo "📝 Para iniciar después:"
    echo "   cd ~/whatsapp-bot-ventas/Baileys.cpp"
    echo "   yarn example"
    echo ""
fi
