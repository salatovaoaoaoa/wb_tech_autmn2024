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
date AS DATE_,
city AS CITY,
city_sales * 1.0 / total_sales AS SUM_SALES_REL
FROM sales_sum
ORDER BY date, city;

-- Я понимаю, что задание на оконные функции, но можно значительно сократить запрос, используя GROUP BY:
-- + я его дополнительно использовала для перепроверки

SELECT
    sa.date AS DATE_,
    sh.city AS CITY,
    SUM(sa.qty * g.price) * 1.0 / SUM(SUM(sa.qty * g.price)) OVER (PARTITION BY sa.date) AS SUM_SALES_REL
FROM sales AS sa
JOIN GOODS AS g ON sa.id_good = g.id_good
JOIN SHOPS AS sh ON sa.shopnumber = sh.shopnumber
WHERE g.category = 'ЧИСТОТА'
GROUP BY sa.date, sh.city
ORDER BY sa.date, sh.city;

--3.

WITH ranked_sales AS (
  SELECT
  sa.date AS DATE_,
  sa.shopnumber,
  sa.id_good,
  SUM(sa.qty) AS total_qty,
  DENSE_RANK() OVER (PARTITION BY sa.shopnumber, sa.date ORDER BY SUM(sa.qty) DESC) AS rank
  FROM SALES AS sa
  GROUP BY sa.date, sa.shopnumber, sa.id_good
)

SELECT 
    DATE_,
    shopnumber,
    id_good
FROM ranked_sales
WHERE rank <= 3
ORDER BY DATE_ DESC, shopnumber, rank;