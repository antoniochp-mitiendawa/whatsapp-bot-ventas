#!/bin/bash

# Colores
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
NC='\033[0m'

echo -e "${AZUL}========================================${NC}"
echo -e "${VERDE}   🚀 INSTALADOR AUTOMÁTICO - BOT VENTAS${NC}"
echo -e "${AZUL}========================================${NC}"

# 1. Actualizar Termux
echo -e "${AMARILLO}[1/9] Actualizando Termux...${NC}"
yes | pkg update -y && yes | pkg upgrade -y

# 2. Instalar git
echo -e "${AMARILLO}[2/9] Instalando git...${NC}"
yes | pkg install git -y

# 3. Configurar git (preguntando al usuario)
echo -e "${AMARILLO}[3/9] Configurando git...${NC}"
echo -e "${AZUL}Ingresa tu nombre de usuario de GitHub:${NC}"
read GIT_USER
echo -e "${AZUL}Ingresa tu email de GitHub:${NC}"
read GIT_EMAIL
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

# 4. Clonar el repositorio
echo -e "${AMARILLO}[4/9] Clonando repositorio...${NC}"
git clone https://github.com/$GIT_USER/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# 5. Instalar Node.js
echo -e "${AMARILLO}[5/9] Instalando Node.js...${NC}"
yes | pkg install nodejs -y

# 6. Instalar yarn
echo -e "${AMARILLO}[6/9] Instalando yarn...${NC}"
yes | pkg install yarn -y

# 7. Instalar dependencias del proyecto
echo -e "${AMARILLO}[7/9] Instalando dependencias...${NC}"
npm install

# 8. Crear carpetas necesarias
echo -e "${AMARILLO}[8/9] Creando estructura de carpetas...${NC}"
mkdir -p sessions
mkdir -p database/cache
mkdir -p logs
mkdir -p /storage/emulated/0/WhatsAppBot
mkdir -p /storage/emulated/0/WhatsAppBot/imagenes
mkdir -p /storage/emulated/0/WhatsAppBot/videos

# 9. Instalar y configurar Ollama
echo -e "${AMARILLO}[9/9] Instalando Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b &

echo -e "${VERDE}========================================${NC}"
echo -e "${VERDE}✅ INSTALACIÓN COMPLETADA${NC}"
echo -e "${VERDE}========================================${NC}"
echo ""
echo -e "${AZUL}Ahora ejecuta estos comandos uno por uno:${NC}"
echo -e "${AMARILLO}1. cd whatsapp-bot-ventas${NC}"
echo -e "${AMARILLO}2. cp .env.example .env${NC}"
echo -e "${AMARILLO}3. nano .env${NC} (para configurar tu Google Sheet)"
echo -e "${AMARILLO}4. node setup.js${NC} (configuración inicial)"
echo -e "${AMARILLO}5. npm start${NC} (iniciar el bot)"
