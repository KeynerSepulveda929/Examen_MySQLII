CREATE DATABASE IF NOT EXISTS eventos_premier;

USE eventos_premier;

-- ==========================================
-- TABLA: encargados
-- ==========================================

CREATE TABLE encargados (
    encargado_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100)
);

-- ==========================================
-- TABLA: salones
-- ==========================================

CREATE TABLE salones (
    salon_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    capacidad INT NOT NULL,
    precio_hora DECIMAL(10,2) NOT NULL,
    estado ENUM('Disponible', 'Ocupado', 'Mantenimiento')
        DEFAULT 'Disponible',
    encargado_id INT NOT NULL,

    CONSTRAINT fk_salon_encargado
        FOREIGN KEY (encargado_id)
        REFERENCES encargados(encargado_id),

    CONSTRAINT chk_capacidad
        CHECK (capacidad > 0),

    CONSTRAINT chk_precio
        CHECK (precio_hora >= 0)
);

-- ==========================================
-- TABLA: clientes
-- ==========================================

CREATE TABLE clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    identificacion VARCHAR(30) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    tipo_cliente ENUM('Individual', 'Corporativo') NOT NULL
);

-- ==========================================
-- TABLA: reservas
-- ==========================================

CREATE TABLE reservas (
    reserva_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    salon_id INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    total_horas DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(12,2) NOT NULL,
    estado ENUM('Activa', 'Cancelada', 'Finalizada')
        DEFAULT 'Activa',

    CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES clientes(cliente_id),

    CONSTRAINT fk_reserva_salon
        FOREIGN KEY (salon_id)
        REFERENCES salones(salon_id),

    CONSTRAINT chk_fechas
        CHECK (fecha_fin > fecha_inicio),

    CONSTRAINT chk_horas
        CHECK (total_horas > 0)
);

-- ==========================================
-- TABLA: pagos
-- ==========================================

CREATE TABLE pagos (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    reserva_id INT NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM(
        'Efectivo',
        'Tarjeta',
        'Transferencia'
    ) NOT NULL,

    CONSTRAINT fk_pago_reserva
        FOREIGN KEY (reserva_id)
        REFERENCES reservas(reserva_id),

    CONSTRAINT chk_monto
        CHECK (monto > 0)
);

-- ==========================================
-- TABLA: auditoria_precios
-- ==========================================

CREATE TABLE auditoria_precios (
    auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    valor_anterior DECIMAL(10,2) NOT NULL,
    valor_nuevo DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_auditoria_salon
        FOREIGN KEY (salon_id)
        REFERENCES salones(salon_id)
);


USE eventos_premier;

//
CREATE FUNCTION calcular_total_reserva(p_precio_hora DECIMAL(10,2),p_horas DECIMAL(10,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE subtotal DECIMAL(12,2);
    DECLARE total DECIMAL(12,2);

    SET subtotal = p_precio_hora * p_horas;
    SET total = subtotal * 1.19;

    RETURN ROUND(total, 2);
END
;

SELECT calcular_total_reserva(50000, 3) AS total;


CREATE FUNCTION verificar_disponibilidad(
    p_salon_id INT,
    p_fecha_inicio DATETIME,
    p_fecha_fin DATETIME
)
RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE cantidad INT DEFAULT 0;

    SELECT COUNT(*)
    INTO cantidad
    FROM reservas
    WHERE salon_id = p_salon_id
      AND estado <> 'Cancelada'
      AND fecha_inicio < p_fecha_fin
      AND fecha_fin > p_fecha_inicio;

    IF cantidad > 0 THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
END
;

SELECT verificar_disponibilidad(1,'2026-09-10 10:00:00','2026-09-10 14:00:00') AS disponible;


USE eventos_premier;


CREATE TRIGGER actualizar_estado_salon_trigger
AFTER INSERT ON reservas
FOR EACH ROW
BEGIN

    UPDATE salones
    SET estado = 'Ocupado'
    WHERE salon_id = NEW.salon_id;

END
;


CREATE TRIGGER liberar_salon_trigger
AFTER DELETE ON reservas
FOR EACH ROW
BEGIN

    UPDATE salones
    SET estado = 'Disponible'
    WHERE salon_id = OLD.salon_id
      AND estado = 'Ocupado';

END
;


CREATE TRIGGER auditoria_precios_trigger
AFTER UPDATE ON salones
FOR EACH ROW
BEGIN
    IF OLD.precio_hora <> NEW.precio_hora THEN
    
        INSERT INTO auditoria_precios (
            salon_id,
            usuario,
            fecha_cambio,
            valor_anterior,
            valor_nuevo
        )
        VALUES (
            NEW.salon_id,
            CURRENT_USER(),
            NOW(),
            OLD.precio_hora,
            NEW.precio_hora
        );

    END IF;

END
;


UPDATE salones
SET precio_hora = 85000
WHERE salon_id = 1;


USE eventos_premier;

-- ==========================================
-- ENCARGADOS
-- ==========================================

INSERT INTO encargados
(nombre_completo, telefono, correo)
VALUES
('Carlos Rodríguez', '3001112233', 'carlos@eventospremier.com'),
('Laura Martínez', '3004445566', 'laura@eventospremier.com'),
('Andrés Gómez', '3007778899', 'andres@eventospremier.com');

-- ==========================================
-- SALONES
-- ==========================================

INSERT INTO salones
(nombre, capacidad, precio_hora, estado, encargado_id)
VALUES
('Salón Premier', 200, 120000, 'Disponible', 1),
('Salón Ejecutivo', 80, 80000, 'Disponible', 2),
('Salón Corporativo', 120, 95000, 'Disponible', 3),
('Salón Terraza', 50, 60000, 'Disponible', 1),
('Salón Conferencias', 300, 150000, 'Disponible', 2);

-- ==========================================
-- CLIENTES
-- ==========================================

INSERT INTO clientes
(nombre_completo, identificacion, telefono, correo, tipo_cliente)
VALUES
('Juan Pérez', '1001001001', '3101111111', 'juan@gmail.com', 'Individual'),
('María González', '1001001002', '3102222222', 'maria@gmail.com', 'Individual'),
('Empresa ABC S.A.S.', '9001001001', '6015551111',
 'contacto@empresaabc.com', 'Corporativo'),
('Corporación XYZ', '9001001002', '6015552222',
 'reservas@xyz.com', 'Corporativo'),
('Eventos del Norte S.A.S.', '9001001003', '6015553333',
 'eventos@norte.com', 'Corporativo');
 

INSERT INTO reservas
(
    cliente_id,
    salon_id,
    fecha_inicio,
    fecha_fin,
    total_horas,
    valor_total,
    estado
)
VALUES
(
    1,
    1,
    '2026-09-01 08:00:00',
    '2026-09-01 12:00:00',
    4,
    calcular_total_reserva(
        (SELECT precio_hora
         FROM salones
         WHERE salon_id = 1),
        4
    ),
    'Activa'
);


INSERT INTO pagos
(
    reserva_id,
    monto,
    metodo_pago
)
VALUES
(1, 570240, 'Transferencia'),
(2, 380800, 'Tarjeta'),
(3, 339150, 'Efectivo');


USE eventos_premier;

CREATE VIEW vista_resumen_reservas AS
SELECT
    r.reserva_id,
    c.nombre_completo AS cliente,
    s.nombre AS salon,
    r.fecha_inicio,
    r.fecha_fin,
    r.total_horas,
    r.valor_total AS total,
    r.estado
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
INNER JOIN salones s
    ON r.salon_id = s.salon_id;
    

SELECT * FROM vista_resumen_reservas;


SELECT
    r.reserva_id,
    c.nombre_completo AS cliente,
    s.nombre AS salon,
    r.fecha_inicio,
    r.fecha_fin,
    r.valor_total,
    r.estado
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
INNER JOIN salones s
    ON r.salon_id = s.salon_id
WHERE r.fecha_inicio
BETWEEN '2026-09-01 00:00:00'
AND '2026-09-30 23:59:59';


SELECT
    salon_id,
    nombre,
    capacidad,
    precio_hora,
    estado
FROM salones
WHERE capacidad > 100
AND estado = 'Disponible';


SELECT
    c.cliente_id,
    c.nombre_completo,
    c.identificacion,
    COUNT(r.reserva_id) AS cantidad_reservas
FROM clientes c
INNER JOIN reservas r
    ON c.cliente_id = r.cliente_id
WHERE c.tipo_cliente = 'Corporativo'
GROUP BY
    c.cliente_id,
    c.nombre_completo,
    c.identificacion
HAVING COUNT(r.reserva_id) > 3;


SELECT
    SUM(valor_total) AS ingresos_totales
FROM reservas
WHERE estado <> 'Cancelada';


SELECT
    s.nombre AS salon,
    COUNT(r.reserva_id) AS cantidad_reservas
FROM salones s
INNER JOIN reservas r
    ON s.salon_id = r.salon_id
GROUP BY s.salon_id, s.nombre
ORDER BY cantidad_reservas DESC
LIMIT 1;


SELECT
    r.reserva_id,
    c.nombre_completo AS cliente,
    r.valor_total,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    r.valor_total - COALESCE(SUM(p.monto), 0) AS saldo
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
LEFT JOIN pagos p
    ON r.reserva_id = p.reserva_id
GROUP BY
    r.reserva_id,
    c.nombre_completo,
    r.valor_total;
    
   
SELECT
    a.auditoria_id,
    s.nombre AS salon,
    a.usuario,
    a.fecha_cambio,
    a.valor_anterior,
    a.valor_nuevo
FROM auditoria_precios a
INNER JOIN salones s
    ON a.salon_id = s.salon_id
ORDER BY a.fecha_cambio DESC;