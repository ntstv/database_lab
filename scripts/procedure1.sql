/**
* Процедура добавления товара
*/

BEGIN;

CREATE OR REPLACE FUNCTION insertProduct(
  opt_id INTEGER,
  opt_article CHAR(20),
  opt_available_amount INTEGER,
  opt_name VARCHAR(60),
  opt_certeficate_id CHAR(20),
  opt_packaging VARCHAR(20),
  opt_fabricator VARCHAR(60),
  opt_price DECIMAL(9,2),
  opt_currency_id CHAR(3)
) RETURNS INTEGER AS $$
DECLARE
  id INTEGER;
  need_new BOOLEAN;
BEGIN
need_new := false;
id := NULL;
IF opt_id IS NOT NULL THEN
  BEGIN
    EXECUTE 'SELECT * FROM "product" WHERE id = $1' INTO STRICT product_row USING $1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        need_new := true;
        id := opt_id;      
  END;
  IF (opt_available_amount == 0 AND)
  BEGIN
    EXECUTE 'UPDATE "product" SET 
      article          = COALESCE($2, article),
      available_amount = COALESCE($3, available_amount),
      name             = COALESCE($4, name),
      certeficate_id   = COALESCE($5, certeficate_id),
      packaging        = COALESCE($6, packaging),
      fabricator       = COALESCE($7, fabricator),
      price            = COALESCE($8, price),
      currency_id      = COALESCE($9, currency_id)
    WHERE id = $1' USING $1,$2,$3,$4,$5,$6,$7,$8,$9;
  END;
  id := opt_id;
END IF;  
IF opt_id IS NULL OR need_new = TRUE THEN
  BEGIN
  EXECUTE  
    'INSERT INTO product(id,
          article, available_amount, name, certeficate_id, packaging,
          fabricator, price, currency_id)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id' INTO id USING id,$2,$3,$4,$5,$6,$7,$8,$9;
   END;
END IF;
RAISE NOTICE 'wow % %', opt_id, need_new;
RETURN id;    
END
$$
  LANGUAGE 'plpgsql';

COMMIT;
