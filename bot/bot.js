// ============================================
// PEDIR NÚMERO DE TELÉFONO (EXACTAMENTE COMO TU OTRO PROYECTO)
// ============================================
function pedirNumeroSilencioso() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        console.log('\n====================================');
        console.log('📱 CONFIGURACIÓN INICIAL');
        console.log('====================================');
        console.log('Ingresa tu número con código de país');
        console.log('Ejemplo: 5215512345678');
        console.log('====================================\n');
        
        rl.question('📱 Introduce tu número (sin +): ', (numero) => {
            rl.close();
            resolve(numero.trim());
        });
    });
}

// ============================================
// DENTRO DE iniciarWhatsApp(), antes de crear el socket
// ============================================
if (!fs.existsSync(path.join(CONFIG.carpeta_sesion, 'creds.json'))) {
    console.log('\n📱 PRIMERA CONFIGURACIÓN\n');
    const numero = await pedirNumeroSilencioso();
    CONFIG.numero_telefono = numero;
    
    console.log(`\n🔄 Solicitando código para ${numero}...\n`);
    
    setTimeout(async () => {
        try {
            const codigo = await sock.requestPairingCode(numero);
            console.log('\n====================================');
            console.log('🔐 CÓDIGO DE VINCULACIÓN');
            console.log('====================================');
            console.log(`   ${codigo}`);
            console.log('====================================\n');
            console.log('1. Abre WhatsApp');
            console.log('2. 3 puntos → Dispositivos vinculados');
            console.log('3. Vincular con número');
            console.log('4. Ingresa el código\n');
        } catch (error) {
            console.log('❌ Error:', error.message);
        }
    }, 2000);
}
