/**
* Вывести информацияю о 3 фирмах покупателей, которые потратили больше всего
* денег за последний год:
* =========================================
* название фирмы покупателя
* категория фирмы покупателя
* потраченная сумма денег в рублях
* название самого покупаемого товара за год
* стоимость купленного товара
* =========================================
*/

SELECT
S0.name,
S0.category,
S1.sum as sum_rub,
(
  SELECT product.name FROM product
  JOIN invoice_product ON product.id = invoice_product.product_id
  JOIN invoice ON invoice.id = invoice_product.invoice_id
  WHERE invoice.buyer_id = S0.id AND invoice.created_at <= now() AND invoice.created_at >= now() - interval '1 year'
  GROUP BY (product.id)
  ORDER BY count(product.id) DESC
  LIMIT 1
) as most_product_name,

(
  SELECT sum(getSum(product.price, now()::TIMESTAMP, product.currency_id, 'РУБ')) FROM invoice_product
  JOIN product ON invoice_product.product_id = product.id
  JOIN invoice ON invoice_product.invoice_id = invoice.id
  WHERE invoice.buyer_id = S0.id
) as price_rub

FROM buyer as S0

JOIN (
SELECT invoice.buyer_id, sum(getSum(invoice.sum, now()::TIMESTAMP, invoice.currency_id, 'РУБ'))
FROM invoice
LEFT OUTER JOIN payment_order
ON invoice.id = payment_order.invoice_id
WHERE
  payment_order.invoice_id is NOT NULL
GROUP BY invoice.buyer_id
) as S1
ON S0.id = S1.buyer_id
ORDER BY sum_rub DESC
 LIMIT 3 
