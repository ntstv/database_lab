/**
* Послучать 5 наиболее плохо продаваемых товаров след. вида
* ================================================================================
* название товара
* артикул
* общее количество которое было на складе
* количество проданных товаров
* цена товара + денежная единица
* дату последней продажи этого товара
* фирма покупатель, которая чаще всего покупала (название или сказать что не было)
* =================================================================================
*/

SELECT
  S0.name,
  S0.article,
  (
      SELECT sum(invoice_product.product_id * invoice_product.quantity) + S0.available_amount
      FROM invoice_product
      WHERE invoice_product.product_id = S0.id
  ) as "total_count",
  (
      SELECT sum(invoice_product.product_id * invoice_product.quantity)
      FROM invoice_product
      WHERE invoice_product.product_id = S0.id
  ) as "sold_count",
  format('%s %s', S0.price, S0.currency_id) as price,
  (
      SELECT invoice.created_at FROM product
      JOIN invoice_product ON product.id = invoice_product.product_id
      JOIN invoice ON invoice.id = invoice_product.invoice_id
      WHERE product.id = S0.id
      ORDER BY invoice.created_at DESC
      LIMIT 1
  ) as last_sold,
  COALESCE(
    (
      SELECT buyer.name
      FROM buyer
      JOIN invoice ON invoice.buyer_id = buyer.id
      JOIN invoice_product ON invoice.id = invoice_product.invoice_id
      WHERE invoice_product.product_id = S0.id
      GROUP BY buyer.name
      ORDER BY count(invoice_product.product_id) DESC
      LIMIT 1
    ),
    'No buyer'
  ) as most_buyer

FROM product as S0
LIMIT 5;
