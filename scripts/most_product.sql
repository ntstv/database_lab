SELECT product.name FROM product 
 JOIN invoice_product ON product.id = invoice_product.product_id
 JOIN invoice ON invoice.id = invoice_product.invoice_id
WHERE invoice.buyer_id = 1 AND invoice.created_at <= now() AND invoice.created_at >= now() - interval '1 year'
GROUP BY (product.id)
ORDER BY count(product.id) DESC
LIMIT 1;