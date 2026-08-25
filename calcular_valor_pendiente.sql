CREATE FUNCTION calcular_valor_pendiente(p_total_reserva DECIMAL (10,2), p_abono DECIMAL (10,2))
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
   
   	SET total = p_total_reserva - p_abono;
   
   	RETURN ROUND (total, 2);
END
;

SELECT calcular_valor_pendiente (500000, 175000) AS total;