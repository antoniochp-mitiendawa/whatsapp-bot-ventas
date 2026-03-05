#!/bin/bash

echo "===================================="
echo "🚀 INICIADOR BOT VENTAS"
echo "===================================="
echo ""

# PASO 1: Instalar Git
echo "📦 Instalando Git..."
pkg install git -y

# PASO 2: Clonar el repositorio
echo "📦 Descargando el bot..."
cd /data/data/com.termux/files/home
rm -rf whatsapp-bot-ventas 2>/dev/null
git clone https://github.com/antoniochp-mitiendawa/whatsapp-bot-ventas.git
cd whatsapp-bot-ventas

# PASO 3: Ejecutar el instalador real (que SÍ puede leer tu entrada)
echo "📦 Ejecutando instalador..."
bash install.sh
