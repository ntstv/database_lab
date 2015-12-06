/**
* Вывести для каждой фирмы покупателя след. статистику
* ==============================================================================
* название фирмы-покупателя
* категория
* SORT:↓ вывести среднее арифметическое оплаты товаров за последний год (вывести
*            в наиболее часто используемой валюте)
* производителя, чьи товары чаще всего покупают
* SORT:↓ среднее количество покупок в месяц за все время
* ==============================================================================
*/

SELECT
  S0.name as "название фирмы-покупателя",
  S0.category as "категория",
  format('%s %s', S1.sum, S1.currency) as "среднее арифм. оплаты тов. за год",
  (
      SELECT product.fabricator FROM invoice
      JOIN invoice_product ON invoice_product.invoice_id = invoice.id
      JOIN product ON invoice_product.product_id = product.id
      WHERE invoice.buyer_id = S0.id
      GROUP BY product.fabricator
      ORDER BY count(product.id) DESC
      LIMIT 1
  ) as "популярный производитель",
  S2.count as "среднее количество покупок за месяц"
FROM buyer as S0
JOIN (
    SELECT
      S4.buyer_id,
      (
        SELECT invoice.currency_id FROM invoice
        WHERE S4.buyer_id = invoice.buyer_id AND invoice.created_at <= now() AND invoice.created_at >= now() - interval '1 year'
        GROUP BY invoice.currency_id
        ORDER BY count(invoice.currency_id) DESC
        LIMIT 1
      ) as currency,
      avg(getSum(S4.sum, now()::TIMESTAMP, S4.currency_id,
      (
        SELECT invoice.currency_id FROM invoice
        WHERE S4.buyer_id = invoice.buyer_id AND invoice.created_at <= now() AND invoice.created_at >= now() - interval '1 year'
        GROUP BY invoice.currency_id
        ORDER BY count(invoice.currency_id) DESC
        LIMIT 1
      )
      ))::DECIMAL(20,2) as sum
    FROM invoice as S4
    WHERE S4.created_at <= now() AND S4.created_at >= now() - interval '1 year'
    GROUP BY S4.buyer_id
) as S1
ON S1.buyer_id = S0.id
JOIN (
  SELECT S22.buyer_id, avg(S22.count)::DECIMAL(20,2) as count
  FROM
  (
    SELECT
      invoice.buyer_id,
      to_char(invoice.created_at, 'Mon') as m,
      to_char(invoice.created_at, 'YYYY') as y,
      count(invoice.id) as count
    FROM invoice
    GROUP BY invoice.buyer_id, m, y
  ) as S22
  GROUP BY S22.buyer_id
) as S2
ON S2.buyer_id = S0.id
ORDER BY S1.sum DESC, S2.count DESC
