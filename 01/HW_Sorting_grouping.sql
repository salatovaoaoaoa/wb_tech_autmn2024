--Задание №1.1:

SELECT
city,
age,
COUNT(id) AS users_count
FROM users
GROUP BY city, age
ORDER BY city, users_count DESC;

-- Дополнительный вариант для группировки по возарстным категориям:
SELECT city,
    CASE
        WHEN age BETWEEN 0 AND 20 THEN 'young'
        WHEN age BETWEEN 21 AND 49 THEN 'adult'
        ELSE 'old'
    END AS age_category,
COUNT(id) AS user_count
FROM users
GROUP BY
city, age_category
ORDER BY city, user_count DESC;

--Задание №1.2

SELECT category, ROUND(AVG(price)::NUMERIC, 2) AS avg_price
FROM products
WHERE name LIKE '%Hair%' OR name LIKE '%Home%'
GROUP BY
category;

--Задание № 2.1

SELECT seller_id,
COUNT(DISTINCT category) AS total_categ,
AVG(rating) AS avg_rating,
SUM(revenue) AS total_revenue,
    CASE
        WHEN SUM(revenue) > 50000 THEN 'rich'
        ELSE 'poor'
    END AS seller_type
FROM sellers
WHERE category != 'Bedding'
GROUP BY seller_id
HAVING COUNT(DISTINCT category) > 1
ORDER BY seller_id ASC;

-- AVG можно округлить с помощью ROUND, так, мне кажется, на данные приятнее смотреть, но так как в задании
--нет установки на это, я не стала округлять. Вдруг потом эти данные используются для расчета статистик
--Можно еще попробовать через подзапрос, хотя, мне кажется, это более громоздко и сложнее

WITH SellerStats AS (
    SELECT seller_id,
    COUNT(DISTINCT category) AS total_categ,
    AVG(rating) AS avg_rating,
    SUM(revenue) AS total_revenue
    FROM sellers
    WHERE category != 'Bedding'
    GROUP BY seller_id
)

SELECT seller_id,
total_categ,
avg_rating,
total_revenue,
    CASE
        WHEN total_categ > 1 AND total_revenue > 50000 THEN 'rich'
        ELSE 'poor'
    END AS seller_type
FROM SellerStats
WHERE total_categ > 1
ORDER BY seller_id;

--Задание № 2.2

--За дату регистрации продавца беру самую раннюю дату, то есть его первичную регистрацию на маркетплейсе

WITH poor_salers_stat AS (
  SELECT seller_id,
  MIN(TO_DATE(date_reg, 'DD/MM/YYYY')) AS date_reg,
  MAX(delivery_days) AS max_delivery_days,
  MIN(delivery_days) AS min_delivery_days
  FROM sellers
  WHERE category != 'Bedding'
  GROUP BY seller_id
  HAVING COUNT(DISTINCT category) > 1 AND SUM(revenue) < 50000
)

SELECT seller_id,
FLOOR((CURRENT_DATE - date_reg)/30) AS month_from_registration,
	(SELECT MAX(max_delivery_days) - MIN(min_delivery_days) FROM poor_salers_stat) AS max_delivery_difference
FROM poor_salers_stat
ORDER BY seller_id;

--Задание № 2.3

--Здесь уже учитываю все даты регистрации, ну логично, просто на всякий случай сказала
WITH sellers_2_cat AS (
    SELECT seller_id,
    ARRAY_AGG(DISTINCT category ORDER BY category) AS categories,
    SUM(revenue) AS total_revenue
    FROM sellers
    WHERE category != 'Bedding' AND EXTRACT(YEAR FROM TO_DATE(date_reg, 'DD-MM-YYYY')) = 2022
    GROUP BY seller_id
    HAVING COUNT(DISTINCT category) = 2 AND SUM(revenue) > 75000
)
SELECT seller_id,
    categories[1] || ' - ' || categories[2] AS category_pair
FROM sellers_2_cat
ORDER BY seller_id;