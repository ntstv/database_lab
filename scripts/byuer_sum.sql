SELECT sum(getSum(product.price, now()::TIMESTAMP, product.currency_id, 'РУБ')) FROM invoice_product
  JOIN product ON invoice_product.product_id = product.id
  JOIN invoice ON invoice_product.invoice_id = invoice.id
 WHERE invoice.buyer_id = 1 