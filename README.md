# 🛡️ Sistema ETL con Validación Previa MySQL

> **Sistema inteligente de validación de datos que previene errores ANTES de la inserción**

[![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)](https://www.mysql.com/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🌟 Funcionalidad Principal

El sistema **valida datos ANTES de insertarlos**, evitando errores de duplicados y garantizando que solo registros válidos lleguen a la base de datos.

### Características Principales

- Validación Previa: Detecta errores antes de la inserción
- Cero Duplicados: Elimina completamente el ERROR 1062
- Trazabilidad Completa: Registra todos los errores para corrección
- Inserción Selectiva: Solo datos válidos llegan a la BD

---

## 🔧 Cómo Funciona el ETL

### Proceso Paso a Paso

1. Inicialización
   - Limpia logs anteriores y configura variables de conteo en cero
   - Crea un ID único para rastrear esta ejecución específica

2. Tablas Temporales
   - Crea tablas espejo (`temp_articulos_validar`, `temp_clientes_validar`, `temp_proveedores_validar`)
   - Carga datos de prueba con errores intencionales para demostrar las validaciones

3. Validaciones (10 tipos)
   - Detecta duplicados dentro del mismo lote de datos
   - Verifica conflictos con registros ya existentes en la base de datos
   - Valida nombres vacíos, precios negativos, categorías nulas, emails inválidos
   - Registra todos los errores encontrados sin detener la ejecución

4. Registro de Errores
   - Guarda cada error en `sys_errores_etl` con descripción detallada
   - Incluye tipo de error, tabla, campo problemático y valor específico

5. Inserción Selectiva
   - Inserta solo registros que no aparecen en la tabla de errores
   - Usa exclusión por código: `WHERE codigo NOT IN (SELECT errores...)`

6. Evita Duplicados
   - Al validar primero, nunca intenta insertar códigos que ya existen
   - Elimina completamente el ERROR 1062 (Duplicate entry)

7. Conteos Reales
   - Cuenta registros directamente desde las tablas finales
   - Muestra cuántos artículos, clientes y proveedores se insertaron realmente

8. Reportes Visuales
   - Presenta resumen con conteos de insertados vs errores detectados
   - Lista todos los errores encontrados para revisión y corrección

---

## 🚀 Script de Ejecución

### `ejecutar_etl_inteligente.sh`

#### Funcionalidades del Script

1. Verificación de Archivos
   - Confirma que existen los archivos SQL necesarios antes de ejecutar

2. Ejecución Secuencial
   - Ejecuta primero `create_TiendaInsumosOficina.sql` para crear la estructura
   - Luego ejecuta `etl_validacion_previa.sql` para procesar los datos

3. Manejo de Errores
   - Detiene el proceso si algún paso falla y muestra el error específico

4. Verificación Automática
   - Al final ejecuta consultas para mostrar cuántos registros se insertaron
   - Confirma que el proceso terminó correctamente

---

## 📊 Datos de Prueba Incluidos

| Tabla          | Total Registros | Registros Válidos | IDs Válidos     |
|----------------|----------------|-------------------|-----------------|
| Artículos      | 7              | 2                 | ART001, ART002  |
| Clientes       | 6              | 2                 | CLI001, CLI002  |
| Proveedores    | 5              | 2                 | PROV001, PROV002|

### Errores Detectados
- ~12 errores de diferentes tipos (duplicados, nulos, inválidos)

---

## 🎯 Resultado Final

### Datos Válidos
Se insertan en las tablas principales

### Datos con Errores
Se registran en `sys_errores_etl` pero **NO** se insertan

### Trazabilidad
Cada error queda documentado para corrección posterior

---

## 🎉 Beneficios del Sistema

- Protección Total: La base de datos solo contiene datos válidos
- Reporte Completo: Documentación detallada de todo lo que necesita corrección
- Eficiencia: Evita rollbacks y errores en producción
- Transparencia: Visibilidad completa del proceso de validación

---

## 🚀 Uso Rápido

```bash
# Hacer ejecutable el script
chmod +x ejecutar_etl_inteligente.sh

# Ejecutar el ETL completo
./ejecutar_etl_inteligente.sh