/**
* Процедура добавления товара
*/

BEGIN;

CREATE OR REPLACE FUNCTION insetProduct(
  par_article CHAR(20),
  par_available_amount INTEGER,
  par_name VARCHAR(60),
  par_certeficate_id CHAR(20),
  par_packaging VARCHAR(20),
  par_fabricator VARCHAR(60),
  par_price DECIMAL(9),
  par_currency_id CHAR(3)
) RETURNS VOID AS $$
BEGIN
INSERT INTO product(
        article, available_amount, name, certeficate_id, packaging,
        fabricator, price, currency_id)
VALUES (par_article, par_available_amount, par_name, par_certeficate_id, par_packaging,
        par_fabricator, par_price, par_currency_id);
END
$$
  LANGUAGE 'plpgsql';

ROLLBACK;
