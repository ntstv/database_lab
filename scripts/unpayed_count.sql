SELECT count(*) FROM
(
  SELECT DISTINCT invoice.*
  FROM invoice
  LEFT OUTER JOIN payment_order
  ON invoice.id = payment_order.invoice_id
  WHERE invoice.buyer_id = 1 AND
    payment_order.invoice_id is NULL
) tmp
