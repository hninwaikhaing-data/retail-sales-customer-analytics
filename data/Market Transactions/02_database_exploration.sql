/* Database Exploration
 Check tables, row counts, columns, data types, grain, date coverage
 ============================================================
	This step is used to understand the structure, size, coverage,
   and basic characteristics of the imported retail datasets before
   performing data quality assessment, cleaning, and analysis.

   1. Review available tables and column structures
   2. Check row counts and records
   3. Examine date coverage
   4. Understand the overall scale and grain of the data
   5. Explore important categorical values
   6. Review basic numeric ranges
   ============================================================ */

USE retail_db;

/* 1. Review available tables and column structures */
-- Check all tables available in the database.
SHOW TABLES;

-- Check the structure and data types of each raw table.
DESCRIBE raw_sales_1997;
DESCRIBE raw_sales_1998;
DESCRIBE raw_customers;
DESCRIBE raw_products;
DESCRIBE raw_stores;
DESCRIBE raw_regions;
DESCRIBE raw_returns;
DESCRIBE raw_calendar;


/* 2. Check row counts and records */
-- Check the total number of rows in each raw table.
SELECT 'raw_sales_1997' AS table_name, COUNT(*) AS row_count
FROM raw_sales_1997

UNION ALL
SELECT 'raw_sales_1998', COUNT(*)
FROM raw_sales_1998

UNION ALL
SELECT 'raw_customers', COUNT(*)
FROM raw_customers

UNION ALL
SELECT 'raw_products', COUNT(*)
FROM raw_products

UNION ALL
SELECT 'raw_stores', COUNT(*)
FROM raw_stores

UNION ALL
SELECT 'raw_regions', COUNT(*)
FROM raw_regions

UNION ALL
SELECT 'raw_returns', COUNT(*)
FROM raw_returns

UNION ALL
SELECT 'raw_calendar', COUNT(*)
FROM raw_calendar;

-- Preview records from each raw table.
SELECT * FROM raw_sales_1997 LIMIT 10;
SELECT * FROM raw_sales_1998 LIMIT 10;
SELECT * FROM raw_customers LIMIT 10;
SELECT * FROM raw_products LIMIT 10;
SELECT * FROM raw_stores LIMIT 10;
SELECT * FROM raw_regions LIMIT 10;
SELECT * FROM raw_returns LIMIT 10;
SELECT * FROM raw_calendar LIMIT 10;

/*  3. Examine date coverage */
-- Check sales transaction date coverage.
SELECT
    MIN(transaction_date) AS start_date,
    MAX(transaction_date) AS end_date
FROM raw_sales_1997;

SELECT
    MIN(transaction_date) AS start_date,
    MAX(transaction_date) AS end_date
FROM raw_sales_1998;


-- Check overall transaction date coverage across both sales tables.
SELECT
    MIN(transaction_date) AS overall_start_date,
    MAX(transaction_date) AS overall_end_date
FROM (
    SELECT transaction_date
    FROM raw_sales_1997

    UNION ALL

    SELECT transaction_date
    FROM raw_sales_1998
) AS sales;


-- Check stock date coverage.
SELECT
    MIN(stock_date) AS stock_start_date,
    MAX(stock_date) AS stock_end_date
FROM (
    SELECT stock_date
    FROM raw_sales_1997

    UNION ALL

    SELECT stock_date
    FROM raw_sales_1998
) AS sales;


-- Check return date coverage.
SELECT
    MIN(return_date) AS return_start_date,
    MAX(return_date) AS return_end_date
FROM raw_returns;


-- 9. Check calendar date coverage.
SELECT
    MIN(`date`) AS calendar_start_date,
    MAX(`date`) AS calendar_end_date
FROM raw_calendar;

/* 4. Understand the overall scale and grain of the data */
-- Understand the overall scale of sales activity.
SELECT
    COUNT(*) AS total_sales_rows,
    SUM(quantity) AS total_units_sold,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT store_id) AS unique_stores
FROM (
    SELECT product_id, customer_id, store_id, quantity
    FROM raw_sales_1997

    UNION ALL

    SELECT product_id, customer_id, store_id, quantity
    FROM raw_sales_1998
) AS sales;

-- Understand the scale of return activity.
SELECT
    COUNT(*) AS total_return_rows,
    SUM(quantity) AS total_returned_units,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT store_id) AS stores_with_returns
FROM raw_returns;

/*  5. Explore important categorical values */
-- Check key customer categories.
SELECT customer_country, COUNT(*) AS customer_count
FROM raw_customers
GROUP BY customer_country
ORDER BY customer_count DESC;

SELECT member_card, COUNT(*) AS customer_count
FROM raw_customers
GROUP BY member_card
ORDER BY customer_count DESC;

SELECT gender, COUNT(*) AS customer_count
FROM raw_customers
GROUP BY gender
ORDER BY customer_count DESC;

SELECT yearly_income, COUNT(*) AS customer_count
FROM raw_customers
GROUP BY yearly_income
ORDER BY customer_count DESC;


-- Check key store categories.
SELECT store_country, COUNT(*) AS store_count
FROM raw_stores
GROUP BY store_country
ORDER BY store_count DESC;

SELECT store_type, COUNT(*) AS store_count
FROM raw_stores
GROUP BY store_type
ORDER BY store_count DESC;


-- Check region structure.
SELECT sales_region, COUNT(*) AS region_count
FROM raw_regions
GROUP BY sales_region
ORDER BY region_count DESC;

SELECT sales_district, COUNT(*) AS district_count
FROM raw_regions
GROUP BY sales_district
ORDER BY district_count DESC;

/* 6. Review basic numeric ranges */
-- Check basic product price and cost ranges.
SELECT
    MIN(product_retail_price) AS min_retail_price,
    MAX(product_retail_price) AS max_retail_price,
    MIN(product_cost) AS min_product_cost,
    MAX(product_cost) AS max_product_cost,
    MIN(product_weight) AS min_product_weight,
    MAX(product_weight) AS max_product_weight
FROM raw_products;


-- Check sales quantity range.
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity
FROM (
    SELECT quantity
    FROM raw_sales_1997

    UNION ALL

    SELECT quantity
    FROM raw_sales_1998
) AS sales;


-- Check return quantity range.
SELECT
    MIN(quantity) AS min_return_quantity,
    MAX(quantity) AS max_return_quantity
FROM raw_returns;