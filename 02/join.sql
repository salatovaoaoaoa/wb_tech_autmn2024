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
FROM customers_new_3 AS c
LEFT JOIN delayed_orders AS delord ON c.customer_id = delord.customer_id
LEFT JOIN cancell_orders AS co ON c.customer_id = co.customer_id
LEFT JOIN customer_totals AS ct ON c.customer_id = ct.customer_id
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

--Задание №2.1

--1 Вычислит общую сумму продаж для каждой категории продуктов

SELECT p.product_category,
(SELECT SUM(o.order_ammount) 
 FROM orders_2 AS o 
 WHERE o.product_id IN (
   SELECT product_id 
   FROM products_3 
   WHERE product_category = p.product_category
 )) AS total_sales
FROM products_3 AS p
GROUP BY p.product_category;

-- Мне все же кажется, тут гораздо лучше подойдет JOIN, запрос будет короче и эффективнее
-- потому что сейчас у нас идет повторное вычислению суммы для каждой строки в таблице `Products`, 
-- так как подзапрос выполняется для каждой категории отдельно.

SELECT p.product_category, SUM(o.order_ammount) AS sum_product
FROM orders_2 as o
JOIN products_3 as p ON o.product_id = p.product_id
GROUP BY p.product_category

--2 пределит категорию продукта с наибольшей общей суммой продаж.

SELECT product_category
FROM (SELECT p.product_category,
(SELECT SUM(o.order_ammount) 
 FROM orders_2 AS o 
 WHERE o.product_id IN (
   SELECT product_id 
   FROM products_3 
   WHERE product_category = p.product_category
 )) AS total_sales
FROM products_3 AS p
GROUP BY p.product_category) AS category_sales
ORDER BY total_sales DESC
LIMIT 1;

--Также с джоином

SELECT product_category
FROM (SELECT p.product_category, SUM(o.order_ammount) AS sum_product
FROM products_3 as p
JOIN orders_2 as o ON p.product_id = o.product_id
GROUP BY p.product_category) AS category_sales
ORDER BY sum_product DESC
LIMIT 1;

--3 Для каждой категории продуктов, определит продукт с максимальной суммой продаж в этой категории.

WITH product_sales AS (
    SELECT p.product_id, p.product_name, p.product_category,
    SUM(o.order_ammount) AS total_sales
    FROM products_3 as p
    JOIN orders_2 as o ON p.product_id = o.product_id
    GROUP BY p.product_id, p.product_name, p.product_category
),

ranked_sales AS (
    SELECT
    ps.product_category,
    ps.product_id,
    ps.product_name,
    ps.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ps.product_category ORDER BY ps.total_sales DESC) AS rn
    FROM product_sales ps
)
SELECT
    product_category,
    product_id,
    product_name,
    total_sales
FROM ranked_sales
WHERE rn = 1;

--4 Из всех трех запросов можно составить сложный подзапрос:

WITH sales_cat AS (
    SELECT p.product_category, SUM(o.order_ammount) AS total_category_sales
    FROM products_3 AS p
    JOIN orders_2 AS o ON p.product_id = o.product_id
    GROUP BY p.product_category
),

top_categ AS (
    SELECT product_category, total_category_sales
    FROM sales_cat
    ORDER BY total_category_sales DESC
    LIMIT 1
),

sale_prod AS (
    SELECT p.product_category,
    p.product_id,
    p.product_name,
    SUM(o.order_ammount) AS total_product_sales,
    ROW_NUMBER() OVER (
        PARTITION BY p.product_category 
        ORDER BY SUM(o.order_ammount) DESC
        ) AS rank_within_category
    FROM products_3 AS p
    JOIN orders_2 AS o ON p.product_id = o.product_id
    GROUP BY p.product_category, p.product_id, p.product_name
),

top_prod AS (
    SELECT product_category,
        product_id,
        product_name,
        total_product_sales
    FROM sale_prod
    WHERE rank_within_category = 1
)

SELECT cs.product_category,
    cs.total_category_sales,
    tp.product_id,
    tp.product_name,
    tp.total_product_sales,
    (SELECT tc.product_category FROM top_categ AS tc) AS top_sales_category
FROM sales_cat AS cs
LEFT JOIN top_prod AS tp ON cs.product_category = tp.product_category;

