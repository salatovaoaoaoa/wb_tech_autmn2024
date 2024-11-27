--Задание №1.1

SELECT
    c.customer_id, c.name, O.order_id, O.order_date, O.shipment_date,
    (O.shipment_date::timestamp - O.order_date::timestamp) AS wait_t
FROM
    customers_new_3 AS c
JOIN
    orders_new_3 AS O ON c.customer_id = O.customer_id
WHERE
    O.shipment_date IS NOT NULL
ORDER BY
    wait_t DESC
LIMIT 1;

--Задание №1.2

WITH cust_orders_stats AS (
SELECT O.customer_id,
COUNT(O.order_id) AS order_count,
AVG(EXTRACT(EPOCH FROM (O.shipment_date::timestamp - O.order_date::timestamp)) / 86400) AS wait_t,
SUM(O.order_ammount) AS total_sum
FROM orders_new_3 AS O
WHERE O.shipment_date IS NOT NULL
GROUP BY
O.customer_id
),

max_ord_count AS (
SELECT MAX(order_count) AS max_orders
FROM cust_orders_stats
)

SELECT c.customer_id,
c.name,
cos.order_count,
cos.wait_t,
cos.total_sum
FROM customers_new_3 AS c
JOIN cust_orders_stats AS cos
ON c.customer_id = cos.customer_id
JOIN max_ord_count moc ON cos.order_count = moc.max_orders
ORDER BY cos.total_sum DESC;

-- Можно переписать немного по - другому (этот вариант мне намного превычнее, просто выше стараюсь
-- экспериментировать с конструкциями WITH, чтобы понять где могу допускать ошибки при создании запросов с ними)

WITH cust_orders_stats AS (
  SELECT c.name AS customer_name,
        COUNT(o.order_id) AS order_count,
        AVG(DATE_PART('day', o.shipment_date::timestamp - o.order_date::timestamp)) AS wait_t,
        SUM(o.order_ammount) AS total_sum
  FROM customers_new_3 as c
  JOIN orders_new_3 as o ON c.customer_id = o.customer_id
  WHERE o.shipment_date IS NOT NULL
  GROUP BY c.name
)

SELECT
    customer_name,
    order_count,
    wait_t,
    total_sum
FROM cust_orders_stats
WHERE order_count = (SELECT MAX(order_count) FROM cust_orders_stats)
ORDER BY total_sum DESC;

--Задание №1.3
--Я считаю, что order_date - изначальная дата доставки, а shipment_date - фактическая дата доставки, поэтому, 
--когда разница между ними будет более, чем 5 дней (>), это и будет являться задержкой.

WITH delayed_orders AS (
      SELECT o.customer_id, COUNT(*) AS delayed_orders_count
      FROM orders_new_3 AS o
      WHERE o.shipment_date IS NOT NULL
      AND DATE_PART('day', o.shipment_date::timestamp - o.order_date::timestamp) > 5
      GROUP BY o.customer_id
 ),
 
 cancell_orders AS (
   SELECT o.customer_id, COUNT(*) AS cancelled_orders_count
   FROM orders_new_3 AS o
   WHERE o.shipment_date IS NOT NULL
   AND o.order_status = 'Cancel'
   GROUP BY o.customer_id
),
 
 customer_totals AS (
   SELECT o.customer_id,
   SUM(o.order_ammount) AS total_order_amount
   FROM orders_new_3 AS o
   GROUP BY o.customer_id
)

SELECT
    c.name,
    COALESCE(delord.delayed_orders_count, 0) AS delayed_orders_count,
    COALESCE(co.cancelled_orders_count, 0) AS cancelled_orders_count,
    COALESCE(ct.total_order_amount, 0) AS total_order_amount
FROM customers_new_3 as c
LEFT JOIN delayed_orders delord ON c.customer_id = delord.customer_id
LEFT JOIN cancell_orders co ON c.customer_id = co.customer_id
LEFT JOIN customer_totals ct ON c.customer_id = ct.customer_id
WHERE delord.customer_id IS NOT NULL OR CO.customer_id IS NOT NULL
ORDER BY total_order_amount DESC;

-- Можно сделать запрос короче, объединив все фильтры в один с помощью CASE:

WITH delay_cancel_ord AS (
  SELECT c.name AS customer_name,
  SUM(CASE WHEN DATE_PART('day', o.shipment_date::timestamp - o.order_date::timestamp) > 5 THEN 1 ELSE 0 END) AS delayed_orders,
  SUM(CASE WHEN o.order_status = 'Cancel' THEN 1 ELSE 0 END) AS cancelled_orders,
  SUM(o.order_ammount) AS total_order_amount
  FROM customers_new_3 AS c
  JOIN orders_new_3 as o ON c.customer_id = o.customer_id
  GROUP BY c.name
)

SELECT 
    customer_name,
    delayed_orders,
    cancelled_orders,
    total_order_amount
FROM delay_cancel_ord
WHERE delayed_orders > 0 OR cancelled_orders > 0
ORDER BY total_order_amount DESC;

