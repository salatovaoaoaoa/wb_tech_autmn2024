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