CREATE TABLE auditoria_abonos(
	id_pago INT AUTO_INCREMENT PRIMARY KEY,
	fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
    valor_anterior DECIMAL(10,2) NOT NULL,
    valor_nuevo DECIMAL(10,2) NOT NULL,
    usuario VARCHAR(100) NOT NULL,
)

CREATE TRIGGER auditar_abono_trigger
AFTER UPDATE ON salones
FOR EACH ROW
BEGIN 
	IF OLD. <> NEW. THEN
	
		INSERT INTO auditoria_abonos(
			id_pago,
			fecha_movimiento,
    		valor_anterior,
    		valor_nuevo,
    		usuario,
	)
END
;