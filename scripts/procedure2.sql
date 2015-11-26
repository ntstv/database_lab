/**
* Процедура оформления накладной
* Добавление товара в накладную, при этом если накладная не существует, то она
* создается, иначе меняется сумма товара и сотав товаров. Если товар уже там
* есть, добавляется еще; списывается со склада
* Пытаться создавать запись с указанным id
* Проверять валюту если указана в накладной
* Проверять чтобы пользователь совпадал
*/

BEGIN;

CREATE OR REPLACE FUNCTION getMaxInoviceId() RETURNS INTEGER AS $$
DECLARE
  id INTEGER;
BEGIN
  BEGIN
  EXECUTE 'SELECT id FROM "invoice" ORDER BY id DESC LIMIT 1' INTO STRICT id;
  RETURN id;
  END;
END
 $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION getSum(
  par_value DECIMAL(9, 2),
  par_date TIMESTAMP,
  par_from_currency_id CHAR(3),
  par_to_currency_id CHAR(3)
) RETURNS DECIMAL(20, 2) AS $$
DECLARE
  translated_sum DECIMAL(9, 2);
  exchange_rate_row "exchange_rate"%ROWTYPE;
BEGIN
  IF (par_from_currency_id = par_to_currency_id) THEN
    translated_sum := par_value;
  ELSE
    BEGIN
      -- RAISE NOTICE 'date % % %',par_from_currency_id,par_to_currency_id, par_date;
      EXECUTE
        'SELECT * FROM "exchange_rate"
          WHERE numerator = $1 AND
            denominator = $2 AND
            created_at <= $3 AND
            DATE(created_at) = DATE($3)
          ORDER BY created_at DESC
          LIMIT 1'
        INTO STRICT exchange_rate_row USING par_from_currency_id, par_to_currency_id, par_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           RAISE EXCEPTION 'exchange not found';
    END;
    translated_sum := exchange_rate_row.value * par_value;
  END IF;
  return translated_sum;
END
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION addProduct(
  par_product_id INTEGER,
  par_quantity INTEGER,
  opt_invoice_id INTEGER,
  opt_buyer_id INTEGER,
  opt_currency_id CHAR(3)

) RETURNS INTEGER AS $$
DECLARE
  invoice_row "invoice"%ROWTYPE;
  product_row "product"%ROWTYPE;
  invoice_product_row "invoice_product"%ROWTYPE;
  new_invoice BOOLEAN;
  new_invoice_product BOOLEAN;
  new_sum DECIMAL(20, 2);
  new_currency CHAR(3);
  invoice_id INTEGER;
BEGIN
  IF par_quantity <= 0 THEN
     RAISE EXCEPTION 'par_quantity should be greater then zero';
  END IF;
  new_invoice := FALSE;
  invoice_id := NULL;
  IF opt_invoice_id IS NULL THEN
    new_invoice := TRUE;
  ELSE
	  BEGIN
	    EXECUTE 'SELECT * FROM "invoice" WHERE id = $1'
	      INTO STRICT invoice_row USING opt_invoice_id;
	    EXCEPTION
	      WHEN NO_DATA_FOUND THEN
		new_invoice := true;

	  END;
	  invoice_id := opt_invoice_id;
  END IF;
  -- calculating new sum
  BEGIN
    EXECUTE 'SELECT * FROM "product" WHERE id = $1'
      INTO STRICT product_row USING par_product_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'error, product not found';
  END;
    IF product_row.available_amount < par_quantity THEN
          RAISE EXCEPTION 'error, not enough product';
    END IF;

  IF opt_currency_id IS NULL THEN
    new_currency := product_row.currency_id;
  ELSE
    new_currency := opt_currency_id;
  END IF;
  IF new_invoice = FALSE AND opt_currency_id IS NOT NULL AND opt_currency_id != invoice_row.currency_id THEN
    RAISE EXCEPTION 'error, change currency not allowed';
  END IF;
  IF new_invoice = FALSE AND opt_buyer_id IS NOT NULL AND opt_buyer_id != invoice_row.buyer_id THEN
    RAISE EXCEPTION 'error, change buyer not allowed';
  END IF;
  IF new_invoice THEN
    new_sum := par_quantity * getSum(
      CAST(product_row.price as DECIMAl(9, 2)),
      CAST(now() as TIMESTAMP),
      CAST(new_currency as CHAR(3)),
      CAST(product_row.currency_id as CHAR(3))
    );
  ELSE
    new_sum := invoice_row.sum + CAST(par_quantity * getSum(
      CAST(product_row.price AS DECIMAL(9, 2)),
      CAST(invoice_row.created_at AS TIMESTAMP),
      CAST(invoice_row.currency_id as CHAR(3)),
      CAST(product_row.currency_id as CHAR(3))
    ) as DECIMAL(20));
    new_currency := invoice_row.currency_id;
  END IF;

  -- inserting invoice
  IF (new_invoice = TRUE AND opt_buyer_id IS NOT NULL)
  THEN
    BEGIN
      EXECUTE 'INSERT INTO "invoice"(id, buyer_id, currency_id, sum)
        VALUES(COALESCE($1, $5), $2, $3, $4) RETURNING id'
        INTO invoice_id
        USING invoice_id, opt_buyer_id, new_currency, new_sum, getMaxInoviceId() + 1;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'error, check opt_buyer_id';
    END;
  END IF;
  IF new_invoice = FALSE THEN
    BEGIN
      EXECUTE 'UPDATE "invoice" SET sum = $1 WHERE id = $2'
        USING invoice_row.sum + CAST(new_sum as DECIMAL(20)), invoice_row.id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE EXCEPTION 'error while updating invoice';
    END;
  END IF;
  -- updating product in invoice
  new_invoice_product := FALSE;
  BEGIN
    EXECUTE 'SELECT * FROM "invoice_product"
      WHERE invoice_id = $1 AND
        product_id = $2' INTO STRICT invoice_product_row USING invoice_id, par_product_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          new_invoice_product := TRUE;
  END;
  IF (new_invoice_product = TRUE) THEN
    BEGIN
      EXECUTE 'INSERT INTO "invoice_product" (product_id, invoice_id, quantity)
        VALUES ($1,$2,$3)' USING par_product_id, invoice_id, par_quantity;
    END;
  ELSE
    BEGIN
      EXECUTE 'UPDATE "invoice_product" SET quantity = $1 WHERE product_id = $2 AND
        invoice_id = $3'
      USING par_quantity + invoice_product_row.quantity, par_product_id, invoice_id;
    END;
  END IF;
  BEGIN
    EXECUTE 'UPDATE "product" SET available_amount = $1 WHERE id = $2'
      USING product_row.available_amount - par_quantity, par_product_id;
  END;

  RETURN invoice_id;
END
$$
  LANGUAGE 'plpgsql';


COMMIT;
