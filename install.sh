#!/bin/bash

# ============================================
# INSTALADOR AUTOMÁTICO - BOT VENTAS
# ============================================

# Colores para output
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${AZUL}========================================${NC}"
echo -e "${VERDE}   🚀 BOT VENTAS - INSTALADOR AUTOMÁTICO${NC}"
echo -e "${AZUL}========================================${NC}"
echo ""

# Verificar que estamos en Termux
if [ ! -d /data/data/com.termux ]; then
    echo -e "${ROJO}❌ Este instalador solo funciona en Termux${NC}"
    exit 1
fi

# 1. Actualizar Termux
echo -e "${AMARILLO}[1/8] Actualizando Termux...${NC}"
pkg update -y && pkg upgrade -y

# 2. Instalar git
echo -e "${AMARILLO}[2/8] Instalando git...${NC}"
pkg install git -y

# 3. Pedir datos de GitHub (para que puedan hacer push si quieren)
echo -e "${AZUL}----------------------------------------${NC}"
echo -e "Para poder guardar cambios en tu GitHub:"
read -p "👤 Tu nombre de usuario de GitHub: " GIT_USER
read -p "📧 Tu email de GitHub: " GIT_EMAIL
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

# 4. Clonar el repositorio
echo -e "${AMARILLO}[4/8] Clonando repositorio...${NC}"
git clone https://github.com/$GIT_USER/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# 5. Instalar Node.js y yarn
echo -e "${AMARILLO}[5/8] Instalando Node.js y yarn...${NC}"
pkg install nodejs yarn -y

# 6. Crear estructura de carpetas
echo -e "${AMARILLO}[6/8] Creando carpetas necesarias...${NC}"
mkdir -p sessions
mkdir -p database/cache
mkdir -p logs
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos
mkdir -p /storage/emulated/0/WhatsAppBot/audios

# 7. Instalar Ollama
echo -e "${AMARILLO}[7/8] Instalando Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh

# 8. Mensaje final
echo -e "${VERDE}========================================${NC}"
echo -e "${VERDE}✅ INSTALACIÓN BASE COMPLETADA${NC}"
echo -e "${VERDE}========================================${NC}"
echo ""
echo -e "${AZUL}Ahora ejecuta estos comandos UNO POR UNO:${NC}"
echo ""
echo -e "${AMARILLO}1. cd whatsapp-bot-ventas${NC}"
echo -e "${AMARILLO}2. pkg install nodejs${NC} (si no se instaló bien)"
echo -e "${AMARILLO}3. npm install${NC}"
echo -e ""
echo -e "${ROJO}⚠️  IMPORTANTE:${NC}"
echo -e "En el siguiente paso necesitarás:"
echo -e "   📌 La URL de tu Web App de Google Sheets"
echo -e "   📌 Tu número de WhatsApp (para vincular)"
echo ""
