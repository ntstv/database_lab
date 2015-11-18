/**
* Процедура оформления накладной
* Добавление товара в накладную, при этом если накладная не существует, то она
* создается, иначе меняется сумма товара и сотав товаров. Если товар уже там
* есть, добавляется еще; списывается со склада
*/

BEGIN;

CREATE OR REPLACE FUNCTION addSum(
  par_value DECIMAL(9),
  par_date TIMESTAMP,
  par_from_currency_id CHAR(3),
  par_to_currency_id CHAR(3)
) RETURNS DECIMAL(9) AS $$
DECLARE
  translated_sum DECIMAL(9);
  exchange_rate_row "exchange_rate"%ROWTYPE;
BEGIN
  IF (par_from_currency_id = par_to_currency_id) THEN
    translated_sum := par_value;
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
  par_invoice_id INTEGER,
  product_id INTEGER,
  count INTEGER,
  opt_par_buyer_id INTEGER,
  opt_currency_id CHAR(3)

) RETURNS VOID AS $$
DECLARE
  invoice_row "invoice"%ROWTYPE;
  product_row "product"%ROWTYPE;
  invoice_product_row "invoice_product"%ROWTYPE;
  new_invoice BOOLEAN;
  new_invoice_product BOOLEAN;
  new_sum DECIMAL(9);
  new_currency CHAR(3);
  new_invoice_id INTEGER;
  invoice_id INTEGER;
BEGIN
  IF par_invoice_id IS NULL THEN new_invoice = true;
  ELSE	
	  BEGIN
	    EXECUTE 'SELECT * FROM "invoice" WHERE invoice_id = $1'
	      INTO STRICT invoice_row USING par_invoice_id;
	    EXCEPTION
	      WHEN NO_DATA_FOUND THEN
		new_invoice = true;
	  END;
  END IF;	  
  -- calculating new sum
  BEGIN
    EXECUTE 'SELECT * FROM "product" WHERE product_id = $1'
      INTO STRICT product_row USING product_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'error, product not found';
    IF product_row.available_amount < count THEN
          RAISE EXCEPTION 'error, not enough product';
    END IF;
    IF new_invoice THEN
      new_sum = count * getSum(
        product_row.price,
        now(),
        product_row.currency_id,
        opt_currency_id
      );
      new_currency = opt_currency_id;
    ELSE
      new_sum = invoice_row.sum + count * getSum(product_row.price,
        invoice_row.created_at,
        product_row.currency_id,
        invoice_row.currency_id
      );
    END IF;
  END;
  -- inserting invoice
  IF (new_invoice AND
    opt_par_buyer_id IS NOT NULL AND
    opt_currency_id IS NOT NULL)
  THEN
    BEGIN
      EXECUTE 'INSERT INTO "invoice"(buyer_id, currency_id, sum)
        VALUES($1, $2, $3) RETURNING id'
        INTO new_invoice_id
        USING opt_par_buyer_id, opt_currency_id, new_sum;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'error, check opt_par_buyer_id, opt_currency_id';
    END;
  END IF;
  IF new_invoice THEN
    invoice_id := new_invoice_id;
  ELSE
    invoice_id := invoice_row.id;
  END IF;
  -- updating product in invoice
  BEGIN
    EXECUTE 'SELECT * FROM "invoice_product"
      WHERE invoice_id = $1 AND
        product_id = $2' INTO invoice_product_row USING invoice_id, product_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          new_invoice_product = true;
  END;
  IF (new_invoice_product) THEN
    EXECUTE 'INSERT INTO "invoice_product" (product_id, invoice_id, count)
      VALUES ($1,$2,$3)' USING product_id, invoice_id, count;
  ELSE
    EXECUTE 'UPDATE "invoice_product" SET count = $1 WHERE product_id = $2 AND
      invoice_id = $3'
    USING count + invoice_product_row.count, product_id, invoice_id;
  END IF;
  EXECUTE 'UPDATE "product" SET available_amount = $1 WHERE product_id = $2'
    USING product_id, product_row.available_amount - count;
END
$$
  LANGUAGE 'plpgsql';


COMMIT;
