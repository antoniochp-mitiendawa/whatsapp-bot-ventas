// ============================================
// SERVICIO DE GOOGLE SHEETS VÍA WEB APP
// ============================================

const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');
const cron = require('node-cron');

class GoogleSheetsService {
  constructor() {
    this.webAppUrl = process.env.GOOGLE_SHEETS_URL;
    this.cachePath = path.join(__dirname, '../../database/cache');
    this.cacheHours = process.env.CACHE_UPDATE_HOURS || '06:00,18:00';
    
    // Datos en caché
    this.cache = {
      empresa: null,
      productos: null,
      asesores: null,
      configuracion: null,
      lastUpdate: null
    };
    
    // Inicializar
    this.inicializar();
  }

  async inicializar() {
    // Crear carpeta de caché si no existe
    await fs.ensureDir(this.cachePath);
    
    // Cargar caché existente
    await this.cargarCache();
    
    // Programar actualizaciones automáticas
    this.programarActualizaciones();
    
    // Primera actualización
    await this.actualizarCache();
  }

  async cargarCache() {
    try {
      const cacheFile = path.join(this.cachePath, 'datos.json');
      if (await fs.pathExists(cacheFile)) {
        this.cache = await fs.readJson(cacheFile);
        console.log('📦 Caché cargado desde archivo');
      }
    } catch (error) {
      console.log('⚠️ No se pudo cargar caché, iniciando vacío');
    }
  }

  async guardarCache() {
    try {
      const cacheFile = path.join(this.cachePath, 'datos.json');
      this.cache.lastUpdate = new Date().toISOString();
      await fs.writeJson(cacheFile, this.cache, { spaces: 2 });
    } catch (error) {
      console.error('❌ Error guardando caché:', error.message);
    }
  }

  programarActualizaciones() {
    const horas = this.cacheHours.split(',');
    
    horas.forEach(hora => {
      const [hour, minute] = hora.trim().split(':');
      
      // Cron job: minutos hora * * *
      cron.schedule(`${minute} ${hour} * * *`, async () => {
        console.log(`🔄 Actualización programada a las ${hora}`);
        await this.actualizarCache();
      });
    });
    
    console.log(`📅 Actualizaciones programadas: ${this.cacheHours}`);
  }

  async actualizarCache() {
    try {
      console.log('🔄 Actualizando datos desde Google Sheets...');
      
      // Obtener todos los datos de una vez
      const response = await axios.get(this.webAppUrl, {
        params: { accion: 'obtener_todo' },
        timeout: 30000 // 30 segundos
      });
      
      if (response.data.status === 'success') {
        this.cache.empresa = response.data.data.empresa;
        this.cache.productos = response.data.data.productos;
        this.cache.asesores = response.data.data.asesores;
        this.cache.configuracion = response.data.data.configuracion;
        
        await this.guardarCache();
        
        console.log('✅ Caché actualizado correctamente');
        console.log(`   📊 Productos: ${this.cache.productos?.length || 0}`);
        console.log(`   👥 Asesores: ${this.cache.asesores?.length || 0}`);
      } else {
        console.error('❌ Error en respuesta:', response.data.mensaje);
      }
      
    } catch (error) {
      console.error('❌ Error actualizando caché:', error.message);
      console.log('⚠️ Usando datos en caché (si existen)');
    }
  }

  // ============================================
  // MÉTODOS PARA ACCEDER A LOS DATOS
  // ============================================

  getEmpresa() {
    return this.cache.empresa || {};
  }

  getProductos() {
    return this.cache.productos || [];
  }

  getProductosActivos() {
    return (this.cache.productos || []).filter(p => p.Activo === 'SI');
  }

  buscarProductoPorNombre(texto) {
    const productos = this.getProductosActivos();
    const palabras = texto.toLowerCase().split(' ');
    
    // Buscar productos que coincidan con alguna palabra
    return productos.filter(producto => {
      const nombre = (producto.Nombre || '').toLowerCase();
      const descripcion = (producto.Descripción || '').toLowerCase();
      const categoria = (producto.Categoría || '').toLowerCase();
      
      return palabras.some(palabra => 
        nombre.includes(palabra) || 
        descripcion.includes(palabra) || 
        categoria.includes(palabra)
      );
    });
  }

  getAsesores() {
    return this.cache.asesores || [];
  }

  getAsesoresActivos() {
    return (this.cache.asesores || []).filter(a => a.Activo === 'SI');
  }

  getConfiguracion() {
    return this.cache.configuracion || {};
  }

  // ============================================
  // MÉTODOS PARA ACTUALIZAR DATOS EN SHEETS
  // ============================================

  async actualizarConteoAsesor(id, atendidos) {
    try {
      const response = await axios.get(this.webAppUrl, {
        params: {
          accion: 'actualizar_asesor',
          id: id,
          atendidos: atendidos
        }
      });
      
      if (response.data.status === 'success') {
        // Actualizar caché local
        const asesor = this.cache.asesores.find(a => a.ID == id);
        if (asesor) {
          asesor['Atendidos Hoy'] = atendidos;
          asesor['Última Asignación'] = new Date().toLocaleString();
          await this.guardarCache();
        }
        return true;
      }
      return false;
      
    } catch (error) {
      console.error('❌ Error actualizando asesor:', error.message);
      return false;
    }
  }

  // Obtener el siguiente asesor en rotación
  getSiguienteAsesor(ultimoAsesorId = 0) {
    const activos = this.getAsesoresActivos();
    if (activos.length === 0) return null;
    
    // Ordenar por ID
    activos.sort((a, b) => a.ID - b.ID);
    
    // Encontrar el siguiente
    let siguiente = null;
    for (let asesor of activos) {
      if (asesor.ID > ultimoAsesorId) {
        siguiente = asesor;
        break;
      }
    }
    
    // Si no hay siguiente, tomar el primero
    if (!siguiente) {
      siguiente = activos[0];
    }
    
    return siguiente;
  }
}

module.exports = GoogleSheetsService;
