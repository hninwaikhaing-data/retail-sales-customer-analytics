USE retail_analytics;

SHOW TABLES;

DESCRIBE raw_sales_1997;
DESCRIBE raw_sales_1998;
DESCRIBE raw_customers;
DESCRIBE raw_products;
DESCRIBE raw_stores;
DESCRIBE raw_regions;
DESCRIBE raw_returns;
DESCRIBE raw_calendar;

SELECT 'sales_1997' AS dataset, COUNT(*) AS rows FROM raw_sales_1997
UNION ALL SELECT 'sales_1998', COUNT(*) FROM raw_sales_1998
UNION ALL SELECT 'customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'products', COUNT(*) FROM raw_products
UNION ALL SELECT 'stores', COUNT(*) FROM raw_stores
UNION ALL SELECT 'regions', COUNT(*) FROM raw_regions
UNION ALL SELECT 'returns', COUNT(*) FROM raw_returns
UNION ALL SELECT 'calendar', COUNT(*) FROM raw_calendar;

SELECT MIN(transaction_date) AS min_transaction_date,
       MAX(transaction_date) AS max_transaction_date
FROM (
    SELECT transaction_date FROM raw_sales_1997
    UNION ALL
    SELECT transaction_date FROM raw_sales_1998
) s;

SELECT MIN(return_date) AS min_return_date,
       MAX(return_date) AS max_return_date
FROM raw_returns;

SELECT MIN(`date`) AS min_calendar_date,
       MAX(`date`) AS max_calendar_date
FROM raw_calendar;

SELECT
    COUNT(*) AS sales_rows,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT product_id) AS products,
    COUNT(DISTINCT store_id) AS stores
FROM (
    SELECT * FROM raw_sales_1997
    UNION ALL
    SELECT * FROM raw_sales_1998
) s;

SELECT customer_country, COUNT(*) AS customers
FROM raw_customers
GROUP BY customer_country
ORDER BY customers DESC;

SELECT member_card, COUNT(*) AS customers
FROM raw_customers
GROUP BY member_card
ORDER BY customers DESC;

SELECT store_type, COUNT(*) AS stores
FROM raw_stores
GROUP BY store_type
ORDER BY stores DESC;
