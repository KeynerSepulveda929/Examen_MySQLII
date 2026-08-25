CREATE VIEW vista_facturacion_reservas AS
SELECT
	c.nombre_cliente AS cliente,
	r.fecha_reserva,
	r.total_reserva,
	p.abono,
	p.valor_pendiente
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
    
SELECT * FROM vista_facturacion_reservas
