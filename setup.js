// ============================================
// CONFIGURACIÓN GUIADA DEL BOT
// ============================================

const fs = require('fs-extra');
const path = require('path');
const readline = require('readline');
const { exec } = require('child_process');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Función para hacer preguntas
function pregunta(pregunta) {
  return new Promise((resolve) => {
    rl.question(pregunta, resolve);
  });
}

// Función principal
async function setup() {
  console.log('\n\x1b[34m========================================\x1b[0m');
  console.log('\x1b[32m   🔧 CONFIGURACIÓN INICIAL DEL BOT\x1b[0m');
  console.log('\x1b[34m========================================\x1b[0m\n');

  // Verificar si ya existe .env
  if (fs.existsSync('.env')) {
    const respuesta = await pregunta('⚠️  Ya existe un archivo .env. ¿Deseas sobrescribirlo? (s/N): ');
    if (respuesta.toLowerCase() !== 's') {
      console.log('\x1b[33mConfiguración cancelada\x1b[0m');
      rl.close();
      return;
    }
  }

  console.log('\n\x1b[33mPor favor, proporciona los siguientes datos:\x1b[0m\n');

  // 1. Preguntar URL de Google Sheets
  const googleSheetsUrl = await pregunta('📌 URL de tu Web App de Google Sheets:\n   > ');
  
  // Validar que la URL tenga el formato correcto
  if (!googleSheetsUrl.includes('/exec')) {
    console.log('\x1b[31m❌ La URL debe terminar en /exec\x1b[0m');
    rl.close();
    return;
  }

  // 2. Preguntar número de WhatsApp
  const whatsappNumber = await pregunta('📱 Tu número de WhatsApp (con código de país, sin + ni espacios):\n   > ');

  // 3. Preguntar modelo de Ollama (con opción por defecto)
  const modeloOllama = await pregunta('🤖 Modelo de Ollama a usar (por defecto: llama3.2:1b):\n   > ') || 'llama3.2:1b';

  // 4. Crear archivo .env
  const envContent = `# ============================================
# CONFIGURACIÓN DEL BOT - GENERADO POR SETUP
# ============================================

# GOOGLE SHEETS
GOOGLE_SHEETS_URL=${googleSheetsUrl}

# WHATSAPP
WHATSAPP_NUMBER=${whatsappNumber}

# OLLAMA
OLLAMA_MODEL=${modeloOllama}
OLLAMA_TEMPERATURE=0.7
OLLAMA_MAX_TOKENS=200

# RUTAS
MULTIMEDIA_PATH=/storage/emulated/0/WhatsAppBot/

# CACHÉ
CACHE_UPDATE_HOURS=06:00,18:00

# LOGS
LOG_LEVEL=info
`;

  fs.writeFileSync('.env', envContent);
  
  console.log('\n\x1b[32m✅ Archivo .env creado exitosamente\x1b[0m');

  // 5. Preguntar si quiere instalar dependencias
  const instalarDeps = await pregunta('\n📦 ¿Deseas instalar las dependencias ahora? (s/N): ');
  
  if (instalarDeps.toLowerCase() === 's') {
    console.log('\n\x1b[33mInstalando dependencias...\x1b[0m');
    exec('npm install', (error, stdout, stderr) => {
      if (error) {
        console.log('\x1b[31m❌ Error al instalar dependencias\x1b[0m');
        console.log(error);
      } else {
        console.log('\x1b[32m✅ Dependencias instaladas\x1b[0m');
      }
      
      console.log('\n\x1b[34m========================================\x1b[0m');
      console.log('\x1b[32m   🚀 TODO LISTO PARA INICIAR\x1b[0m');
      console.log('\x1b[34m========================================\x1b[0m');
      console.log('\nPara iniciar el bot: \x1b[33mnpm start\x1b[0m\n');
      rl.close();
    });
  } else {
    console.log('\n\x1b[33mPara instalar dependencias después: npm install\x1b[0m');
    console.log('\n\x1b[34m========================================\x1b[0m');
    console.log('\x1b[32m   🚀 CONFIGURACIÓN COMPLETADA\x1b[0m');
    console.log('\x1b[34m========================================\x1b[0m');
    console.log('\nSiguientes pasos:');
    console.log('1. \x1b[33mnpm install\x1b[0m (instalar dependencias)');
    console.log('2. \x1b[33mnpm start\x1b[0m (iniciar el bot)\n');
    rl.close();
  }
}

// Ejecutar setup
setup().catch(error => {
  console.error('\x1b[31mError:', error, '\x1b[0m');
  rl.close();
});
