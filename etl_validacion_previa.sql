-- =========================================================
-- ETL CON VALIDACIÓN PREVIA (ANTES DE INSERCIÓN)
-- =========================================================
-- Este sistema valida los datos ANTES de insertarlos
-- manteniendo las restricciones UNIQUE del schema
-- =========================================================

USE TiendaInsumosOficina;

-- =========================================================
-- CONFIGURACIÓN INICIAL
-- =========================================================

-- Inicializar variables de conteo
SET @articulos_insertados = 0;
SET @clientes_insertados = 0;
SET @proveedores_insertados = 0;
SET @total_errores = 0;

-- Limpiar logs anteriores
DELETE FROM sys_errores_etl;
DELETE FROM sys_etl_log;

-- Desactivar validaciones estrictas temporalmente
SET sql_mode = '';
SET foreign_key_checks = 0;

-- Crear log principal del proceso
INSERT INTO sys_etl_log (proceso, fecha_inicio, estado, mensaje)
VALUES ('ETL_VALIDACION_PREVIA', NOW(), 'INICIADO', 'Validación ETL ANTES de inserción');

SET @log_id = LAST_INSERT_ID();

SELECT CONCAT('LOG ID: ', @log_id) AS INICIO_VALIDACION;
SELECT '================================================================' AS SEPARADOR;

-- =========================================================
-- TABLA TEMPORAL PARA DATOS A VALIDAR
-- =========================================================

-- Crear tabla temporal para datos de artículos a insertar
DROP TEMPORARY TABLE IF EXISTS temp_articulos_validar;
CREATE TEMPORARY TABLE temp_articulos_validar (
    CODIGO_ARTICULO VARCHAR(50),
    NOMBRE_ARTICULO VARCHAR(200),
    DESCRIPCION TEXT,
    CATEGORIA VARCHAR(100),
    MARCA VARCHAR(100),
    PRECIO_UNITARIO DECIMAL(10,2),
    CREATED_BY VARCHAR(50),
    fila_num INT AUTO_INCREMENT PRIMARY KEY
);

-- Crear tabla temporal para datos de clientes a insertar
DROP TEMPORARY TABLE IF EXISTS temp_clientes_validar;
CREATE TEMPORARY TABLE temp_clientes_validar (
    CODIGO_CLIENTE VARCHAR(50),
    NOMBRE_CLIENTE VARCHAR(200),
    EMAIL VARCHAR(100),
    TELEFONO VARCHAR(20),
    CREATED_BY VARCHAR(50),
    fila_num INT AUTO_INCREMENT PRIMARY KEY
);

-- Crear tabla temporal para datos de proveedores a insertar
DROP TEMPORARY TABLE IF EXISTS temp_proveedores_validar;
CREATE TEMPORARY TABLE temp_proveedores_validar (
    CODIGO_PROVEEDOR VARCHAR(50),
    NOMBRE_PROVEEDOR VARCHAR(200),
    EMAIL VARCHAR(100),
    RUC_NIT VARCHAR(20),
    CREATED_BY VARCHAR(50),
    fila_num INT AUTO_INCREMENT PRIMARY KEY
);

-- =========================================================
-- CARGAR DATOS A VALIDAR (SIMULANDO DATOS DEL ETL)
-- =========================================================

SELECT '>>> Cargando datos para validación...' as PASO_1;

-- Datos de artículos con errores intencionales
INSERT INTO temp_articulos_validar (CODIGO_ARTICULO, NOMBRE_ARTICULO, DESCRIPCION, CATEGORIA, MARCA, PRECIO_UNITARIO, CREATED_BY) VALUES
('ART001', 'Lápiz HB', 'Lápiz de grafito HB', 'LAPICES', 'Faber-Castell', 0.50, 'ADMIN'),
('ART002', 'Cuaderno', 'Cuaderno 100 hojas', 'CUADERNOS', 'Norma', 2.50, 'ADMIN'),
('ART001', 'Lápiz 2B', 'Lápiz grafito 2B', 'LAPICES', 'Staedtler', 0.60, 'ADMIN'), -- DUPLICADO
('ART003', '', 'Borrador', 'BORRADORES', 'Pelikan', 0.75, 'ADMIN'), -- NOMBRE VACÍO
('ART004', 'Regla', 'Regla 30cm', 'REGLAS', 'Artesco', -1.00, 'ADMIN'), -- PRECIO NEGATIVO
('ART005', 'Marcador', 'Marcador negro', '', 'Sharpie', 1.25, 'ADMIN'), -- CATEGORÍA VACÍA
('ART006', 'Tijeras', 'Tijeras escolares', 'TIJERAS', 'Maped', NULL, 'ADMIN'); -- PRECIO NULL

-- Datos de clientes con errores intencionales
INSERT INTO temp_clientes_validar (CODIGO_CLIENTE, NOMBRE_CLIENTE, EMAIL, TELEFONO, CREATED_BY) VALUES
('CLI001', 'Juan Pérez', 'juan.perez@email.com', '555-1234', 'ADMIN'),
('CLI002', 'María García', 'maria.garcia@email.com', '555-5678', 'ADMIN'),
('CLI001', 'Juan Carlos', 'juan.carlos@email.com', '555-2222', 'ADMIN'), -- DUPLICADO
('CLI003', '', 'cliente.vacio@email.com', '555-9999', 'ADMIN'), -- NOMBRE VACÍO
('CLI004', 'Pedro López', 'email_invalido', '555-1111', 'ADMIN'), -- EMAIL INVÁLIDO
('CLI005', 'Ana Torres', NULL, '555-3333', 'ADMIN'); -- EMAIL NULL

-- Datos de proveedores con errores intencionales
INSERT INTO temp_proveedores_validar (CODIGO_PROVEEDOR, NOMBRE_PROVEEDOR, EMAIL, RUC_NIT, CREATED_BY) VALUES
('PROV001', 'Distribuidora ABC', 'ventas@abc.com', '12345678901', 'ADMIN'),
('PROV002', 'Papelería XYZ', 'info@xyz.com', '98765432109', 'ADMIN'),
('PROV001', 'Distribuidora DEF', 'ventas@def.com', '11111111111', 'ADMIN'), -- DUPLICADO
('PROV003', '', 'proveedor@email.com', '22222222222', 'ADMIN'), -- NOMBRE VACÍO
('PROV004', 'Librería GHI', 'correo_sin_arroba', '33333333333', 'ADMIN'); -- EMAIL INVÁLIDO

-- =========================================================
-- VALIDACIÓN 1: DUPLICADOS EN ARTÍCULOS (EN DATOS NUEVOS)
-- =========================================================
SELECT '>>> Validando duplicados en artículos...' as PASO_2;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_DATOS_NUEVOS', 'temp_articulos_validar', 'CODIGO_ARTICULO', CODIGO_ARTICULO, 
       CONCAT('Código de artículo duplicado en datos nuevos: "', CODIGO_ARTICULO, '" aparece ', COUNT(*), ' veces')
FROM temp_articulos_validar 
GROUP BY CODIGO_ARTICULO 
HAVING COUNT(*) > 1;

-- =========================================================
-- VALIDACIÓN 2: CONFLICTOS CON DATOS EXISTENTES EN ARTÍCULOS
-- =========================================================
SELECT '>>> Validando conflictos con artículos existentes...' as PASO_3;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_CON_EXISTENTE', 'temp_articulos_validar', 'CODIGO_ARTICULO', t.CODIGO_ARTICULO, 
       CONCAT('Código de artículo ya existe en BD: "', t.CODIGO_ARTICULO, '"')
FROM temp_articulos_validar t
INNER JOIN DB_ARTICULO d ON t.CODIGO_ARTICULO = d.CODIGO_ARTICULO;

-- =========================================================
-- VALIDACIÓN 3: DUPLICADOS EN CLIENTES (EN DATOS NUEVOS)
-- =========================================================
SELECT '>>> Validando duplicados en clientes...' as PASO_4;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_DATOS_NUEVOS', 'temp_clientes_validar', 'CODIGO_CLIENTE', CODIGO_CLIENTE, 
       CONCAT('Código de cliente duplicado en datos nuevos: "', CODIGO_CLIENTE, '" aparece ', COUNT(*), ' veces')
FROM temp_clientes_validar 
GROUP BY CODIGO_CLIENTE 
HAVING COUNT(*) > 1;

-- =========================================================
-- VALIDACIÓN 4: CONFLICTOS CON DATOS EXISTENTES EN CLIENTES
-- =========================================================
SELECT '>>> Validando conflictos con clientes existentes...' as PASO_5;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_CON_EXISTENTE', 'temp_clientes_validar', 'CODIGO_CLIENTE', t.CODIGO_CLIENTE, 
       CONCAT('Código de cliente ya existe en BD: "', t.CODIGO_CLIENTE, '"')
FROM temp_clientes_validar t
INNER JOIN DB_CLIENTE d ON t.CODIGO_CLIENTE = d.CODIGO_CLIENTE;

-- =========================================================
-- VALIDACIÓN 5: DUPLICADOS EN PROVEEDORES (EN DATOS NUEVOS)
-- =========================================================
SELECT '>>> Validando duplicados en proveedores...' as PASO_6;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_DATOS_NUEVOS', 'temp_proveedores_validar', 'CODIGO_PROVEEDOR', CODIGO_PROVEEDOR, 
       CONCAT('Código de proveedor duplicado en datos nuevos: "', CODIGO_PROVEEDOR, '" aparece ', COUNT(*), ' veces')
FROM temp_proveedores_validar 
GROUP BY CODIGO_PROVEEDOR 
HAVING COUNT(*) > 1;

-- =========================================================
-- VALIDACIÓN 6: CONFLICTOS CON DATOS EXISTENTES EN PROVEEDORES
-- =========================================================
SELECT '>>> Validando conflictos con proveedores existentes...' as PASO_7;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'DUPLICADO_CON_EXISTENTE', 'temp_proveedores_validar', 'CODIGO_PROVEEDOR', t.CODIGO_PROVEEDOR, 
       CONCAT('Código de proveedor ya existe en BD: "', t.CODIGO_PROVEEDOR, '"')
FROM temp_proveedores_validar t
INNER JOIN DB_PROVEEDOR d ON t.CODIGO_PROVEEDOR = d.CODIGO_PROVEEDOR;

-- =========================================================
-- VALIDACIÓN 7: NOMBRES NULOS O VACÍOS
-- =========================================================
SELECT '>>> Validando nombres vacíos...' as PASO_8;

-- Artículos con nombres vacíos
INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'VALOR_NULO', 'temp_articulos_validar', 'NOMBRE_ARTICULO', CODIGO_ARTICULO, 
       CONCAT('Nombre de artículo vacío para código: "', CODIGO_ARTICULO, '"')
FROM temp_articulos_validar 
WHERE NOMBRE_ARTICULO IS NULL OR TRIM(NOMBRE_ARTICULO) = '';

-- Clientes con nombres vacíos
INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'VALOR_NULO', 'temp_clientes_validar', 'NOMBRE_CLIENTE', CODIGO_CLIENTE, 
       CONCAT('Nombre de cliente vacío para código: "', CODIGO_CLIENTE, '"')
FROM temp_clientes_validar 
WHERE NOMBRE_CLIENTE IS NULL OR TRIM(NOMBRE_CLIENTE) = '';

-- Proveedores con nombres vacíos
INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'VALOR_NULO', 'temp_proveedores_validar', 'NOMBRE_PROVEEDOR', CODIGO_PROVEEDOR, 
       CONCAT('Nombre de proveedor vacío para código: "', CODIGO_PROVEEDOR, '"')
FROM temp_proveedores_validar 
WHERE NOMBRE_PROVEEDOR IS NULL OR TRIM(NOMBRE_PROVEEDOR) = '';

-- =========================================================
-- VALIDACIÓN 8: PRECIOS INVÁLIDOS
-- =========================================================
SELECT '>>> Validando precios inválidos...' as PASO_9;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'PRECIO_INVALIDO', 'temp_articulos_validar', 'PRECIO_UNITARIO', CODIGO_ARTICULO, 
       CONCAT('Precio inválido para artículo "', CODIGO_ARTICULO, '": ', 
              CASE 
                  WHEN PRECIO_UNITARIO IS NULL THEN 'NULL'
                  ELSE CAST(PRECIO_UNITARIO AS CHAR)
              END)
FROM temp_articulos_validar 
WHERE PRECIO_UNITARIO IS NULL OR PRECIO_UNITARIO < 0;

-- =========================================================
-- VALIDACIÓN 9: CATEGORÍAS VACÍAS
-- =========================================================
SELECT '>>> Validando categorías vacías...' as PASO_10;

INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'CATEGORIA_VACIA', 'temp_articulos_validar', 'CATEGORIA', CODIGO_ARTICULO, 
       CONCAT('Categoría vacía para artículo: "', CODIGO_ARTICULO, '"')
FROM temp_articulos_validar 
WHERE CATEGORIA IS NULL OR TRIM(CATEGORIA) = '';

-- =========================================================
-- VALIDACIÓN 10: EMAILS INVÁLIDOS
-- =========================================================
SELECT '>>> Validando emails inválidos...' as PASO_11;

-- Clientes con emails inválidos
INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'EMAIL_INVALIDO', 'temp_clientes_validar', 'EMAIL', CODIGO_CLIENTE, 
       CONCAT('Email inválido para cliente "', CODIGO_CLIENTE, '": "', COALESCE(EMAIL, 'NULL'), '"')
FROM temp_clientes_validar 
WHERE EMAIL IS NULL OR EMAIL NOT LIKE '%@%.%';

-- Proveedores con emails inválidos
INSERT INTO sys_errores_etl (id_log, tipo_error, tabla_origen, campo_error, valor_error, descripcion_error)
SELECT @log_id, 'EMAIL_INVALIDO', 'temp_proveedores_validar', 'EMAIL', CODIGO_PROVEEDOR, 
       CONCAT('Email inválido para proveedor "', CODIGO_PROVEEDOR, '": "', COALESCE(EMAIL, 'NULL'), '"')
FROM temp_proveedores_validar 
WHERE EMAIL IS NULL OR EMAIL NOT LIKE '%@%.%';

-- =========================================================
-- INSERCIÓN SELECTIVA: SOLO REGISTROS SIN ERRORES
-- =========================================================
SELECT '>>> Insertando solo registros válidos...' as PASO_12;

-- Insertar artículos válidos únicamente
INSERT INTO DB_ARTICULO (CODIGO_ARTICULO, NOMBRE_ARTICULO, DESCRIPCION, CATEGORIA, MARCA, PRECIO_UNITARIO, CREATED_BY)
SELECT CODIGO_ARTICULO, NOMBRE_ARTICULO, DESCRIPCION, CATEGORIA, MARCA, PRECIO_UNITARIO, CREATED_BY
FROM temp_articulos_validar t
WHERE t.CODIGO_ARTICULO NOT IN (
    -- Excluir registros con errores detectados
    SELECT DISTINCT valor_error 
    FROM sys_errores_etl 
    WHERE id_log = @log_id 
    AND tabla_origen IN ('temp_articulos_validar')
    AND valor_error IS NOT NULL
);

SET @articulos_insertados = ROW_COUNT();

-- Insertar clientes válidos únicamente
INSERT INTO DB_CLIENTE (CODIGO_CLIENTE, NOMBRE_CLIENTE, EMAIL, TELEFONO, CREATED_BY)
SELECT CODIGO_CLIENTE, NOMBRE_CLIENTE, EMAIL, TELEFONO, CREATED_BY
FROM temp_clientes_validar t
WHERE t.CODIGO_CLIENTE NOT IN (
    -- Excluir registros con errores detectados
    SELECT DISTINCT valor_error 
    FROM sys_errores_etl 
    WHERE id_log = @log_id 
    AND tabla_origen IN ('temp_clientes_validar')
    AND valor_error IS NOT NULL
);

SET @clientes_insertados = ROW_COUNT();

-- Insertar proveedores válidos únicamente
INSERT INTO DB_PROVEEDOR (CODIGO_PROVEEDOR, NOMBRE_PROVEEDOR, EMAIL, RUC_NIT, CREATED_BY)
SELECT CODIGO_PROVEEDOR, NOMBRE_PROVEEDOR, EMAIL, RUC_NIT, CREATED_BY
FROM temp_proveedores_validar t
WHERE t.CODIGO_PROVEEDOR NOT IN (
    -- Excluir registros con errores detectados
    SELECT DISTINCT valor_error 
    FROM sys_errores_etl 
    WHERE id_log = @log_id 
    AND tabla_origen IN ('temp_proveedores_validar')
    AND valor_error IS NOT NULL
);

SET @proveedores_insertados = ROW_COUNT();

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

-- Obtener conteos reales directamente de las tablas
SELECT COUNT(*) INTO @articulos_insertados FROM DB_ARTICULO;
SELECT COUNT(*) INTO @clientes_insertados FROM DB_CLIENTE;
SELECT COUNT(*) INTO @proveedores_insertados FROM DB_PROVEEDOR;

-- Contar total de errores
SELECT COUNT(*) INTO @total_errores FROM sys_errores_etl WHERE id_log = @log_id;

SELECT '╔══════════════════════════════════════════════════════════════════╗' AS '';
SELECT '║                    RESUMEN DEL PROCESO ETL                       ║' AS '';
SELECT '╚══════════════════════════════════════════════════════════════════╝' AS '';

-- Mostrar resumen con conteos reales
SELECT 
    @articulos_insertados AS 'Artículos Válidos Insertados',
    @clientes_insertados AS 'Clientes Válidos Insertados', 
    @proveedores_insertados AS 'Proveedores Válidos Insertados',
    @total_errores AS 'Total Errores Detectados';

-- =========================================================
-- MOSTRAR TODOS LOS ERRORES DETECTADOS
-- =========================================================
SELECT CASE WHEN @total_errores > 0 THEN '╔══════════════════════════════════════════════════════════════════╗' ELSE '' END AS '';
SELECT CASE WHEN @total_errores > 0 THEN '║                       ERRORES DETECTADOS                        ║' ELSE '' END AS '';
SELECT CASE WHEN @total_errores > 0 THEN '║                  (Necesitan ser corregidos)                     ║' ELSE '' END AS '';
SELECT CASE WHEN @total_errores > 0 THEN '╚══════════════════════════════════════════════════════════════════╝' ELSE '' END AS '';

SELECT 
    tipo_error AS 'Tipo de Error',
    tabla_origen AS 'Tabla Origen',
    campo_error AS 'Campo Problemático',
    valor_error AS 'Valor Problemático',
    descripcion_error AS 'Descripción del Error'
FROM sys_errores_etl 
WHERE id_log = @log_id
ORDER BY tipo_error, tabla_origen, campo_error;

-- =========================================================
-- ACTUALIZAR LOG FINAL
-- =========================================================
UPDATE sys_etl_log 
SET fecha_fin = NOW(), 
    estado = CASE WHEN @total_errores > 0 THEN 'COMPLETADO_CON_ERRORES' ELSE 'COMPLETADO_OK' END,
    mensaje = CONCAT('Proceso finalizado. Errores detectados: ', @total_errores, 
                          '. Registros insertados: ', 
                          @articulos_insertados + @clientes_insertados + @proveedores_insertados)
WHERE id_log = @log_id;

-- Reactivar validaciones estrictas
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';
SET foreign_key_checks = 1;

SELECT '╔══════════════════════════════════════════════════════════════════╗' AS '';
SELECT '║                    PROCESO ETL COMPLETADO                        ║' AS '';
SELECT '╚══════════════════════════════════════════════════════════════════╝' AS '';
