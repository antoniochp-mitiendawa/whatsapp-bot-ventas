// ============================================
// ARCHIVO PRINCIPAL DEL BOT
// ============================================

const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs-extra');

// Cargar variables de entorno
dotenv.config();

// Verificar configuración básica
function verificarConfiguracion() {
  const required = ['GOOGLE_SHEETS_URL', 'WHATSAPP_NUMBER'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error('\x1b[31m❌ Faltan variables de entorno:\x1b[0m');
    missing.forEach(key => console.error(`   - ${key}`));
    console.error('\n\x1b[33mEjecuta: node setup.js\x1b[0m');
    process.exit(1);
  }
}

verificarConfiguracion();

console.log('\x1b[34m========================================\x1b[0m');
console.log('\x1b[32m   🤖 BOT DE VENTAS INICIANDO...\x1b[0m');
console.log('\x1b[34m========================================\x1b[0m');
console.log(`📱 Número: ${process.env.WHATSAPP_NUMBER}`);
console.log(`📊 Google Sheets: ${process.env.GOOGLE_SHEETS_URL.substring(0, 50)}...`);
console.log(`🤖 Modelo Ollama: ${process.env.OLLAMA_MODEL || 'llama3.2:1b'}`);
console.log('\x1b[34m========================================\x1b[0m\n');

// Aquí irán las importaciones de servicios
// (las agregaremos en los próximos archivos)

// Función principal
async function main() {
  try {
    console.log('🔄 Inicializando servicios...');
    
    // TODO: Conectar con Google Sheets
    // TODO: Conectar con WhatsApp
    // TODO: Conectar con Ollama
    
    console.log('✅ Bot listo para recibir mensajes');
    
  } catch (error) {
    console.error('❌ Error fatal:', error);
    process.exit(1);
  }
}

// Manejo de cierre graceful
process.on('SIGINT', async () => {
  console.log('\n\x1b[33m🛑 Cerrando bot...\x1b[0m');
  process.exit(0);
});

// Iniciar
main();
