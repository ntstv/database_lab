/**
* Получать 5 наиболее плохо продаваемых товаров след. вида
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
  S0.name as "название товара",
  S0.article as "артикул",
  COALESCE((
      SELECT sum(invoice_product.product_id * invoice_product.quantity) + S0.available_amount
      FROM invoice_product
      WHERE invoice_product.product_id = S0.id
  ), 0) + S0.available_amount
  as "общее количество которое было на складе",
  COALESCE(S1.sum, 0) as "количество проданных товаров",
  format('%s %s', S0.price, S0.currency_id) as "цена товара + денежная единица",
  COALESCE((
     SELECT invoice.created_at
     FROM invoice
     JOIN invoice_product ON invoice_product.invoice_id = invoice.id
     WHERE invoice_product.product_id = S0.id
     ORDER BY invoice.created_at DESC
     LIMIT 1
  )::VARCHAR(255),'Не было продаж') as "дата последней продажи",
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
  ) as "фирма покупатель, которая чаще всего покупала"

FROM product as S0
LEFT OUTER JOIN (
   SELECT invoice_product.product_id, sum(invoice_product.product_id * invoice_product.quantity)
   FROM invoice_product
   GROUP BY invoice_product.product_id
) as S1
ON S1.product_id = S0.id
ORDER BY COALESCE(S1.sum, 0) ASC
LIMIT 5;
