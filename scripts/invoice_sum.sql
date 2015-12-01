  SELECT invoice.buyer_id,invoice.currency_id,sum(getSum(invoice.sum, now()::TIMESTAMP, invoice.currency_id, 'РУБ'))
  FROM invoice
  LEFT OUTER JOIN payment_order
  ON invoice.id = payment_order.invoice_id
  WHERE invoice.buyer_id = 2 AND
    payment_order.invoice_id is NULL
  GROUP BY invoice.currency_id,buyer_id