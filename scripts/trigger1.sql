/**
* Когда заполняется ВПП, если указанная сумма не равна сумме в накаладной,
* с учетом курса, на дату указанную в накладной, то отменяется запись.
* Если сумма >= чем сумма в накладной то принять, иначе отвергнуть
*/

BEGIN;

/**
* Использовать только при заполнении таблицы "payment_order"
*/
CREATE OR REPLACE FUNCTION check_payment_order_func()
  RETURNS trigger AS $$
DECLARE
    invoice_sum DECIMAL(9);
    invoice_currrency CHAR(3);
    translated_sum DECIMAL(9);
    exchange_rate DECIMAL(6,2);
    invoice_row "invoice"%ROWTYPE;
    exchange_rate_row "exchange_rate"%ROWTYPE;
BEGIN
  -- NEW is "payment_order" row
  IF NEW.invoice_id is NULL THEN
    RETURN NEW;
  END IF;
  BEGIN
    SELECT * INTO STRICT invoice_row FROM "invoice" WHERE id = NEW.invoice_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'invoice with id % not found', NEW.invoice_id;
      WHEN TOO_MANY_ROWS THEN
        RAISE EXCEPTION 'order_id % related with too many invoices', NEW.invoice_id;
  END;
  IF invoice_row.currency_id = NEW.currency_id THEN
    IF invoice_row.sum <= NEW.sum THEN
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'not enugh sum';
    END IF;
  ELSE
    BEGIN
      EXECUTE
        'SELECT * FROM "exchange_rate"
          WHERE numerator = $1 AND
            denominator = $2 AND
            created_at <= $3 AND
            DATE(created_at) = DATE($3)
          ORDER BY created_at DESC
          LIMIT 1'
        INTO STRICT exchange_rate_row USING NEW.currency_id, invoice_row.currency_id, NEW.created_at;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           RAISE EXCEPTION 'exchange not found';
    END;
    translated_sum := exchange_rate_row.value * NEW.sum;
    IF invoice_row.sum <= translated_sum THEN
      RETURN NEW;
    ELSE
      RAISE EXCEPTION 'not enugh sum';
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_payment_order BEFORE UPDATE OR INSERT ON "payment_order"
  FOR EACH ROW
  EXECUTE PROCEDURE check_payment_order_func();

COMMIT;
