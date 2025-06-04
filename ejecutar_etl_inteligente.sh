#!/bin/bash

# =========================================================
# ETL INTELIGENTE CON VALIDACIÓN PREVIA
# =========================================================
# Este script resuelve el conflicto entre las restricciones
# UNIQUE del schema y el sistema de validación ETL
# =========================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${GREEN}ETL INTELIGENTE CON VALIDACIÓN PREVIA${NC}"
echo "================================================================"
echo ""

# Verificar si MySQL está disponible
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}ERROR: MySQL no está instalado o no está en el PATH${NC}"
    exit 1
fi

# Solicitar credenciales una sola vez
echo -e "${YELLOW}Ingrese las credenciales de MySQL:${NC}"
read -p "Usuario: " MYSQL_USER
read -s -p "Contraseña: " MYSQL_PASS
echo ""

# Función para ejecutar SQL y mostrar resultado
execute_sql() {
    local file=$1
    local description=$2
    
    echo ""
    echo "----------------------------------------------------------------"
    echo -e "${BLUE}$description${NC}"
    echo "----------------------------------------------------------------"
    
    if mysql -u $MYSQL_USER -p$MYSQL_PASS TiendaInsumosOficina < $file 2>&1; then
        echo -e "${GREEN}✓ Completado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}✗ Error durante la ejecución${NC}"
        return 1
    fi
}

# Verificar archivos necesarios
echo -e "${YELLOW}Verificando archivos...${NC}"

required_files=(
    "create_TiendaInsumosOficina.sql"
    "etl_validacion_previa.sql"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}ERROR: Archivo $file no encontrado${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $file encontrado${NC}"
done

echo ""
echo "================================================================"
echo -e "${GREEN}INICIANDO PROCESO ETL COMPLETO${NC}"
echo "================================================================"

# Paso 1: Crear base de datos y estructura
execute_sql "create_TiendaInsumosOficina.sql" "PASO 1: Creando estructura de base de datos"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}PROCESO ABORTADO: Error en la creación de la base de datos${NC}"
    exit 1
fi

# Paso 2: Ejecutar ETL con validación previa
execute_sql "etl_validacion_previa.sql" "PASO 2: Ejecutando ETL con validación previa"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}PROCESO ABORTADO: Error en la validación ETL${NC}"
    exit 1
fi

# Resumen final
echo ""
echo "================================================================"
echo -e "${GREEN}PROCESO ETL COMPLETADO${NC}"
echo "================================================================"
echo ""
echo -e "${BLUE}Resumen de archivos procesados:${NC}"
echo "1. create_TiendaInsumosOficina.sql - Estructura de BD"
echo "2. etl_validacion_previa.sql - Validación inteligente"
echo ""
echo -e "${YELLOW}Ejecutando verificación automática...${NC}"
echo ""

# Verificación automática de resultados
mysql -u $MYSQL_USER -p -e "
USE TiendaInsumosOficina;
SELECT '╔══════════════════════════════════════════════════════════════════╗' AS '';
SELECT '║                    VERIFICACIÓN AUTOMÁTICA                       ║' AS '';
SELECT '╚══════════════════════════════════════════════════════════════════╝' AS '';
SELECT 
    (SELECT COUNT(*) FROM DB_ARTICULO) AS 'Artículos Insertados',
    (SELECT COUNT(*) FROM DB_CLIENTE) AS 'Clientes Insertados',
    (SELECT COUNT(*) FROM DB_PROVEEDOR) AS 'Proveedores Insertados',
    (SELECT COUNT(*) FROM sys_errores_etl) AS 'Errores Detectados';
"

echo ""
echo -e "${YELLOW}Para ver detalles de errores:${NC}"
echo "./verificar_resultados.fish"
echo ""
echo -e "${GREEN}¡Sistema ETL listo para usar!${NC}"
