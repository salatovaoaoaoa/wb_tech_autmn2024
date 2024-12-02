-- Задание №1
-- Максимальная зарплата без оконных функций

SELECT first_name,
last_name,
salary,
industry,
CONCAT(first_name, ' ', last_name) AS name_ighest_sal
FROM salary
WHERE (industry, salary) 
IN (SELECT industry, MAX(salary)
FROM salary
GROUP BY industry)
ORDER BY name_ighest_sal;

-- Минимальная зарплата без оконных функций

SELECT first_name,
last_name,
salary,
industry,
CONCAT(first_name, ' ', last_name) AS name_lowest_sal
FROM salary
WHERE (industry, salary) 
IN (SELECT industry, MIN(salary)
FROM salary
GROUP BY industry)
ORDER BY name_lowest_sal;

-- Максимальная зарплата с оконными функциями
--Я использую здесь DISTINCT, потому что если будут два сотрудника с одинаковой ЗП, они не продублировались.
-- Я использую order by name_ighest_sal, чтобы проверить, что два запроса выдают один и тот же результат 
--(по salary не подходит, потому что он по- разному сравнивет через окна и через вложенный запрос)

SELECT DISTINCT 
first_name,
last_name,
salary,
industry,
CONCAT(first_name, ' ', last_name) AS name_ighest_sal
FROM (
    SELECT
        first_name,
        last_name,
        salary,
        industry,
        FIRST_VALUE(salary) OVER (PARTITION BY industry
        ORDER BY salary DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS max_salary
    FROM salary
) subquery
WHERE salary = max_salary
ORDER BY name_ighest_sal;

-- Минимальная зарплата с оконными функциями

SELECT DISTINCT 
first_name,
last_name,
salary,
industry,
CONCAT(first_name, ' ', last_name) AS name_lowest_sal
FROM (
  SELECT
  first_name,
  last_name,
  salary,
  industry,
  LAST_VALUE(salary) OVER (PARTITION BY industry
  ORDER BY salary DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS min_salary
  FROM salary
) subquery
WHERE salary = min_salary
ORDER BY name_lowest_sal;

-- Задание №2

--1.
-- У меня выдавало ошибку "Error 22003 smallint out of range", потому что столбец QTY имеет тип smallint
ALTER TABLE SALES ALTER COLUMN QTY TYPE INTEGER;

SELECT DISTINCT ON (sa.shopnumber)
sa.shopnumber,
sh.city,
sh.address,
SUM(sa.qty) OVER (PARTITION BY sa.shopnumber) AS sum_qty,
SUM(sa.qty * g.price) OVER (PARTITION BY sa.shopnumber) AS sum_qty_price
FROM sales AS sa
JOIN goods AS g ON sa.id_good = g.id_good
JOIN shops AS sh ON sa.shopnumber = sh.shopnumber
WHERE sa.date = '02.01.2016'
ORDER BY sa.shopnumber;

--2.

WITH sales_sum AS (
  SELECT
  sa.date,
  sh.city,
  SUM(sa.qty * g.price) OVER (PARTITION BY sa.date) AS total_sales,
  SUM(sa.qty * g.price) OVER (PARTITION BY sa.date, sh.city) AS city_sales
  FROM sales as sa
  JOIN goods AS g ON sa.id_good = g.id_good
  JOIN shops as sh ON sa.shopnumber = sh.shopnumber
  WHERE g.category = 'ЧИСТОТА'
)

SELECT DISTINCT
date AS date_,
city,
city_sales * 1.0 / total_sales AS SUM_SALES_REL
FROM sales_sum
ORDER BY date, city;

-- Я понимаю, что задание на оконные функции, но можно значительно сократить запрос, используя GROUP BY:
-- + я его дополнительно использовала для перепроверки

SELECT
    sa.date AS date_,
    sh.city,
    SUM(sa.qty * g.price) * 1.0 / SUM(SUM(sa.qty * g.price)) OVER (PARTITION BY sa.date) AS SUM_SALES_REL
FROM sales AS sa
JOIN goods AS g ON sa.id_good = g.id_good
JOIN shops AS sh ON sa.shopnumber = sh.shopnumber
WHERE g.category = 'ЧИСТОТА'
GROUP BY sa.date, sh.city
ORDER BY sa.date, sh.city;

--3.

WITH ranked_sales AS (
  SELECT
  sa.date AS date_,
  sa.shopnumber,
  sa.id_good,
  SUM(sa.qty) AS total_qty,
  DENSE_RANK() OVER (PARTITION BY sa.shopnumber, sa.date ORDER BY SUM(sa.qty) DESC) AS rank
  FROM SALES AS sa
  GROUP BY sa.date, sa.shopnumber, sa.id_good
)

SELECT
    date_,
    shopnumber,
    id_good
FROM ranked_sales
WHERE rank <= 3
ORDER BY DATE_ DESC, shopnumber, rank;

--4.
-- в условии сказано "за предыдущую", но тогда нет смысла использовать оконные функции, 
-- можно было бы просто отсортировать, поэтому я решила использовать накопительную сумму
-- то есть учитывается сумма всех продаж до текущей даты (не включая). Мне кажется, это более практичный результат
-- так мы будем видеть нарастающую сумму продаж

SELECT
s.date AS date_,
s.shopnumber,
g.category,
COALESCE(SUM(s.QTY * g.PRICE)
OVER (PARTITION BY s.SHOPNUMBER, g.CATEGORY ORDER BY s.DATE ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)
AS PREV_SALES
FROM sales AS s
JOIN goods AS g ON s.id_good = g.id_good
JOIN shops sh ON s.shopnumber = sh.shopnumber
WHERE sh.city = 'СПб'
ORDER BY s.shopnumber, g.category, s.date;

-- но я на всякий случай также реализовала запрос,
-- где выводится только за предыдущий день

SELECT
s.date AS date_,
s.shopnumber,
g.category,
COALESCE(SUM(s.QTY * g.PRICE)
OVER (PARTITION BY s.shopnumber, g.category
      ORDER BY s.date ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING), 0) AS prev_sales
FROM sales AS s
JOIN goods AS g ON s.id_good = g.id_good
JOIN shops AS sh ON s.shopnumber = sh.shopnumber
WHERE sh.city = 'СПб'
ORDER BY s.shopnumber, g.category, s.date;

-- Задание №3

CREATE TABLE query (
    searchid SERIAL PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    userid INT,
    ts BIGINT,
    devicetype TEXT,
    deviceid TEXT,
    query TEXT
);

INSERT INTO query (year, month, day, userid, ts, devicetype, deviceid, query)
VALUES
(2022, 08, 23, 1, 1661252400, 'android', '101', 'к'),
(2022, 08, 23, 1, 1661252410, 'android', '101', 'ку'),
(2022, 08, 23, 1, 1661252420, 'android', '101', 'куп'),
(2022, 08, 23, 1, 1661252430, 'android', '101', 'купить'),
(2022, 08, 23, 1, 1661253610, 'android', '101', 'купить кур'),
(2022, 08, 23, 1, 1661253620, 'android', '101', 'купить курт'),
(2022, 08, 23, 1, 1661253640, 'android', '101', 'купить куртку'),
(2022, 08, 23, 1, 1661253680, 'android', '101', 'купить куртку жен'),

(2023, 09, 30, 2, 1696061580, 'iphone', '102', 'сумка'),
(2023, 09, 30, 2, 1696061700, 'iphone', '102', 'сумка кожаная'),
(2023, 09, 30, 2, 1696061730, 'iphone', '102', 'сумка кожаная черная'),
(2023, 09, 30, 2, 1696061850, 'iphone', '102', 'сумка кожаная черная женская'),

(2023, 10, 19, 3, 1697735970, 'android', '103', 'телефон samsung galaxy s21'),
(2023, 10, 19, 3, 1697736090, 'android', '103', 'телефон samsung'),
(2023, 10, 19, 3, 1697736110, 'android', '103', 'телефон samsung smart'),
(2023, 10, 19, 3, 1697736150, 'android', '103', 'телефон samsung smart s21'),

(2023, 11, 12, 4, 1699772450, 'iphone', '104', 'ге'),
(2023, 11, 12, 4, 1699772490, 'iphone', '104', 'гель для'),
(2023, 11, 12, 4, 1699773050, 'iphone', '104', 'гель для душа Палмолив'),

(2024, 12, 12, 5, 1734009050, 'iphone', '104', 'гель для душа Палмолив'),

(2024, 12, 21, 6, 1734791110, 'android', '105', 'стоматология спб');


WITH conditions AS (
  SELECT year,
  month,
  day,
  userid,
  ts,
  devicetype,
  deviceid,
  query,
  LENGTH(query) AS query_length,
  LEAD(query) OVER (PARTITION BY userid, devicetype ORDER BY ts) AS next_query,
  LEAD(ts) OVER (PARTITION BY userid, devicetype ORDER BY ts) AS next_ts,
  LEAD(LENGTH(query)) OVER (PARTITION BY userid, devicetype ORDER BY ts) AS next_query_length
  FROM query)
SELECT *
FROM (
  SELECT 
  year,
  month,
  day,
  userid,
  ts,
  devicetype,
  deviceid,
  query,
  next_query,
  CASE
  WHEN next_query IS NULL THEN 1
  WHEN next_ts - ts > 180 THEN 1
  WHEN next_query IS NOT NULL 
  AND next_query_length < query_length
  AND next_ts - ts > 60 THEN 2
  ELSE 0
  END AS is_final
FROM conditions
) filtered_data
WHERE devicetype = 'android'
  AND year = 2023
  AND month = 10
  AND day = 19
  AND is_final IN (1, 2);