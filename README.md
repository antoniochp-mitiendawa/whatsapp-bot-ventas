# 🤖 Bot de Ventas para WhatsApp

Bot automático para WhatsApp que utiliza Google Sheets como base de datos y Ollama (IA local) para responder preguntas de clientes.

## 📋 CARACTERÍSTICAS

- ✅ Respuestas automáticas con IA (Ollama)
- ✅ Catálogo de productos desde Google Sheets
- ✅ Vinculación por código (NO QR)
- ✅ Funciona 24/7 en Termux
- ✅ Soporte para imágenes (próximamente)
- ✅ Rotación de asesores humanos (próximamente)

## 🚀 INSTALACIÓN EN TERMUX

### **PASO 1:** Prepara Google Sheets

1. Abre [Google Sheets](https://sheets.new)
2. Ve a **Extensiones → Apps Script**
3. Borra el código existente y pega el código de abajo
4. Guarda el proyecto como "Bot Ventas"
5. Ve a **Implementar → Nueva implementación → Aplicación web**
   - Ejecutar como: **Yo**
   - Quién tiene acceso: **Cualquier persona**
6. Haz clic en **Implementar** y **COPIA LA URL**

### **PASO 2:** Instala en Termux

Abre Termux y ejecuta UNA SOLA LÍNEA:

```bash
curl -sL https://raw.githubusercontent.com/TU_USUARIO/whatsapp-bot-ventas/main/install.sh | bash
