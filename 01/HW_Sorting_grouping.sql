--Задание №1.1:

SELECT 
    city,
    age,
    COUNT(id) AS users_count
FROM 
    users
GROUP BY 
    city, age
ORDER BY 
    city, users_count DESC;

-- Дополнительный вариант для группировки по возарстным категориям:
SELECT city, CASE
    WHEN age BETWEEN 0 AND 20 THEN 'young'
    WHEN age BETWEEN 21 AND 49 THEN 'adult'
    ELSE 'old'
END as age_category,
COUNT(id) as user_count
FROM users
GROUP BY
city, age_category
ORDER BY
city,
user_count DESC;

--Задание №1.2

SELECT category, ROUND(AVG(price), 2) AS avg_price
FROM products
WHERE name LIKE '%Hair%' OR name LIKE '%Home%'
GROUP BY 
category;