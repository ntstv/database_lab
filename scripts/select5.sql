/**
* Вывести с разбивкой по месяцам количество продаж за последний год.
* В случае если в каком-то месяце не было продаж вывести ноль
*/

SELECT period, sum(count) as "количество продаж" FROM (
(
SELECT to_char(invoice.created_at, 'MM YYYY') AS period, count(invoice.id)
FROM invoice
GROUP BY period
)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '0 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '1 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '2 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '3 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '4 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '5 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '6 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '7 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '8 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '9 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '10 month', 'MM YYYY') AS period, 0 as count)
UNION
(SELECT to_char(date_trunc('year', now()) + interval '11 month', 'MM YYYY') AS period, 0 as count)
) as S0
GROUP BY period
ORDER BY period
