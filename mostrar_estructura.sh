#!/bin/bash

# Script de verificación de la estructura final limpia
# Ejecutar: chmod +x mostrar_estructura.sh && ./mostrar_estructura.sh

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              ESTRUCTURA FINAL LIMPIA DEL SISTEMA ETL             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

echo "📁 DIRECTORIO: $(pwd)"
echo ""

echo "📄 ARCHIVOS ESENCIALES (5 únicamente):"
echo ""

files=(
    "create_TiendaInsumosOficina.sql:Estructura de base de datos"
    "etl_validacion_previa.sql:ETL con validación previa"
    "ejecutar_etl_inteligente.sh:Script de ejecución principal"
    "INSTRUCCIONES_FINAL.txt:Documentación completa"
    "mostrar_estructura.sh:Verificación de estructura"
)

for item in "${files[@]}"; do
    file="${item%%:*}"
    desc="${item##*:}"
    
    if [[ -f "$file" ]]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo "N/A")
        echo "   ✅ $file ($lines líneas)"
        echo "      └─ $desc"
    else
        echo "   ❌ $file - NO ENCONTRADO"
    fi
    echo ""
done

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     COMANDOS DE VERIFICACIÓN SQL                ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 Ejecutar ETL completo:"
echo "   ./ejecutar_etl_inteligente.sh"
echo ""
echo "🔍 VERIFICAR DATOS INSERTADOS (solo válidos):"
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT * FROM DB_ARTICULO;\""
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT * FROM DB_CLIENTE;\""
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT * FROM DB_PROVEEDOR;\""
echo ""
echo "📊 CONTAR REGISTROS INSERTADOS:"
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT (SELECT COUNT(*) FROM DB_ARTICULO) AS Articulos, (SELECT COUNT(*) FROM DB_CLIENTE) AS Clientes, (SELECT COUNT(*) FROM DB_PROVEEDOR) AS Proveedores;\""
echo ""
echo "❌ VER TODOS LOS ERRORES DETECTADOS:"
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT * FROM sys_errores_etl ORDER BY tipo_error;\""
echo ""
echo "📈 RESUMEN DE ERRORES POR TIPO:"
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT tipo_error, COUNT(*) AS cantidad FROM sys_errores_etl GROUP BY tipo_error;\""
echo ""
echo "📋 ESTADO DEL PROCESO ETL:"
echo "   mysql -u root -p -e \"USE TiendaInsumosOficina; SELECT * FROM sys_etl_log ORDER BY fecha_inicio DESC LIMIT 1;\""
echo ""

echo "✅ LIMPIEZA COMPLETADA - Solo archivos esenciales mantenidos"
echo "🎯 SISTEMA LISTO PARA PRODUCCIÓN"
