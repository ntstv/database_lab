/**
* Вывести фирмы покупатели, которые не оплатили товары за все время
* ==============================================
* название фирмы покупателя
* категория
* количество неоплаченных накладных
* сумма задолженности (рубли)
* дату оформления ранней неоплаченной наклданой
* общее количество покупок за все время
* наиболее часто используемая валюта
* =============================================
*/


SELECT
  S0.name as "название фирмы покупателя",
  S0.category as "категория",
  (
    SELECT count(invoice.id)
    FROM invoice
    LEFT OUTER JOIN payment_order
    ON invoice.id = payment_order.invoice_id
    WHERE invoice.buyer_id = S0.id AND
      payment_order.invoice_id is NULL
  ) as "количество неоплаченных накладных",
  (
    SELECT sum(getSum(invoice.sum, now()::TIMESTAMP, invoice.currency_id, 'РУБ'))
    FROM invoice
    LEFT OUTER JOIN payment_order
    ON invoice.id = payment_order.invoice_id
    WHERE invoice.buyer_id = S0.id AND
      payment_order.invoice_id IS NULL
  ) as "сумма задолженности (рубли)",
  (
    SELECT invoice.created_at
    FROM invoice
    LEFT OUTER JOIN payment_order
    ON invoice.id = payment_order.invoice_id
    WHERE invoice.buyer_id = S0.id AND
      payment_order.invoice_id IS NULL
    ORDER BY invoice.created_at ASC
    LIMIT 1
  ) as "дата оформления ранней неоплаченной накладной",
  (
    SELECT count(invoice.id)
    FROM invoice
    WHERE invoice.buyer_id = S0.id
  ) as "общее количество покупок за все время",
  (
    SELECT invoice.currency_id
    FROM invoice
    WHERE invoice.buyer_id = 1
    GROUP BY invoice.currency_id
    ORDER BY count(invoice.currency_id) DESC
    LIMIT 1
  ) as "наиболее часто используемая валюта"
FROM buyer as S0
