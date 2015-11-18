/**
* Ограничить количество неполаченных накладных для одного клиента двумя
*/

BEGIN;

CREATE OR REPLACE FUNCTION check_payed_invoice_func()
  RETURNS trigger AS $$
DECLARE
  count INTEGER;
BEGIN
  EXECUTE '
  SELECT count(invoice.id)
  FROM invoice
  LEFT OUTER JOIN payment_order
  ON invoice.id = payment_order.invoice_id
  WHERE invoice.buyer_id = $1 AND
    payment_order.invoice_id is NULL'
   USING NEW.buyer_id INTO count;
   IF (count >= 2) THEN
     RAISE EXCEPTION 'buyer has more then 2 unpayend invoices';
   ELSE
     RETURN NEW;
   END IF;
END;
$$ LANGUAGE plpgsql;


--CREATE TRIGGER check_payed_invoice BEFORE UPDATE OR INSERT ON "invoice"
--  FOR EACH ROW
--  EXECUTE PROCEDURE check_payed_invoice_func();

COMMIT;
