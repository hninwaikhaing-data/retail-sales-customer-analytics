/* Data Quality Assignment 
 Check NULLs, duplicates, invalid values, PK/FK issues, category inconsistencies
 
 ============================================================
	The quality of the raw retail data to identify potential issues before performing data cleaning.

   1. Check missing and NULL values
   2. Check duplicate records
   3. Check key uniqueness
   4. Check inconsistent categorical values
   5. Check invalid numeric values and ranges
   6. Check invalid or unusual dates
   7. Check primary and foreign key relationships
   8. Summarize identified data quality issues
   ============================================================
 */
 
-- 1. CHECK MISSING AND NULL VALUES
-- ============================================================
-- Check missing values in customer data.
SELECT
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(customer_acct_num IS NULL) AS account_number_nulls,
    SUM(first_name IS NULL OR TRIM(first_name) = '') AS first_name_missing,
    SUM(last_name IS NULL OR TRIM(last_name) = '') AS last_name_missing,
    SUM(customer_country IS NULL OR TRIM(customer_country) = '') AS country_missing,
    SUM(birthdate IS NULL) AS birthdate_nulls,
    SUM(yearly_income IS NULL OR TRIM(yearly_income) = '') AS income_missing,
    SUM(gender IS NULL OR TRIM(gender) = '') AS gender_missing,
    SUM(member_card IS NULL OR TRIM(member_card) = '') AS member_card_missing
FROM raw_customers;


-- Check missing values in product data.
SELECT
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(product_brand IS NULL OR TRIM(product_brand) = '') AS brand_missing,
    SUM(product_name IS NULL OR TRIM(product_name) = '') AS product_name_missing,
    SUM(product_retail_price IS NULL) AS retail_price_nulls,
    SUM(product_cost IS NULL) AS cost_nulls,
    SUM(product_weight IS NULL) AS weight_nulls,
    SUM(recyclable IS NULL) AS recyclable_nulls,
    SUM(low_fat IS NULL) AS low_fat_nulls
FROM raw_products;


-- Check missing values in store data.
SELECT
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(region_id IS NULL) AS region_id_nulls,
    SUM(store_type IS NULL OR TRIM(store_type) = '') AS store_type_missing,
    SUM(store_name IS NULL OR TRIM(store_name) = '') AS store_name_missing,
    SUM(store_country IS NULL OR TRIM(store_country) = '') AS country_missing,
    SUM(total_sqft IS NULL) AS total_sqft_nulls,
    SUM(grocery_sqft IS NULL) AS grocery_sqft_nulls
FROM raw_stores;


-- Check missing values in region data.
SELECT
    SUM(region_id IS NULL) AS region_id_nulls,
    SUM(sales_district IS NULL OR TRIM(sales_district) = '') AS district_missing,
    SUM(sales_region IS NULL OR TRIM(sales_region) = '') AS region_missing
FROM raw_regions;


-- Check missing values in 1997 sales transactions.
SELECT
    SUM(transaction_date IS NULL) AS transaction_date_nulls,
    SUM(stock_date IS NULL) AS stock_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM raw_sales_1997;


-- Check missing values in 1998 sales transactions.
SELECT
    SUM(transaction_date IS NULL) AS transaction_date_nulls,
    SUM(stock_date IS NULL) AS stock_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM raw_sales_1998;


-- Check missing values in return data.
SELECT
    SUM(return_date IS NULL) AS return_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM raw_returns;


-- Check missing values in calendar data.
SELECT
    SUM(`date` IS NULL) AS date_nulls
FROM raw_calendar;

-- 2. CHECK DUPLICATE RECORDS
-- ============================================================
-- Check duplicate customer IDs.
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check duplicate product IDs.
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM raw_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check duplicate store IDs.
SELECT
    store_id,
    COUNT(*) AS duplicate_count
FROM raw_stores
GROUP BY store_id
HAVING COUNT(*) > 1;


-- Check duplicate region IDs.
SELECT
    region_id,
    COUNT(*) AS duplicate_count
FROM raw_regions
GROUP BY region_id
HAVING COUNT(*) > 1;


-- Check duplicate calendar dates.
SELECT
    `date`,
    COUNT(*) AS duplicate_count
FROM raw_calendar
GROUP BY `date`
HAVING COUNT(*) > 1;


-- Check exact duplicate-looking records in 1997 sales data.
-- These records are investigated only and should not be automatically removed
-- because the dataset does not contain a unique transaction ID.

SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity,
    COUNT(*) AS duplicate_count
FROM raw_sales_1997
GROUP BY
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
HAVING COUNT(*) > 1;


-- Check exact duplicate-looking records in 1998 sales data.
SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity,
    COUNT(*) AS duplicate_count
FROM raw_sales_1998
GROUP BY
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
HAVING COUNT(*) > 1;


-- Check exact duplicate-looking return records.
-- Do not automatically remove them because no unique return ID is available.

SELECT
    return_date,
    product_id,
    store_id,
    quantity,
    COUNT(*) AS duplicate_count
FROM raw_returns
GROUP BY
    return_date,
    product_id,
    store_id,
    quantity
HAVING COUNT(*) > 1;

-- 3. CHECK KEY UNIQUENESS
-- ============================================================
-- Compare total rows with unique IDs in dimension tables.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM raw_customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM raw_products;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_id) AS unique_store_ids
FROM raw_stores;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT region_id) AS unique_region_ids
FROM raw_regions;

-- 4. CHECK CATEGORICAL VALUES
-- ============================================================

-- Review customer categorical values for inconsistent labels.
SELECT gender, COUNT(*) AS record_count
FROM raw_customers
GROUP BY gender
ORDER BY gender;

SELECT marital_status, COUNT(*) AS record_count
FROM raw_customers
GROUP BY marital_status
ORDER BY marital_status;

SELECT member_card, COUNT(*) AS record_count
FROM raw_customers
GROUP BY member_card
ORDER BY member_card;

SELECT yearly_income, COUNT(*) AS record_count
FROM raw_customers
GROUP BY yearly_income
ORDER BY yearly_income;

SELECT education, COUNT(*) AS record_count
FROM raw_customers
GROUP BY education
ORDER BY education;

SELECT occupation, COUNT(*) AS record_count
FROM raw_customers
GROUP BY occupation
ORDER BY occupation;

SELECT homeowner, COUNT(*) AS record_count
FROM raw_customers
GROUP BY homeowner
ORDER BY homeowner;

SELECT customer_country, COUNT(*) AS record_count
FROM raw_customers
GROUP BY customer_country
ORDER BY customer_country;


-- Review product flag values.
SELECT recyclable, COUNT(*) AS record_count
FROM raw_products
GROUP BY recyclable
ORDER BY recyclable;

SELECT low_fat, COUNT(*) AS record_count
FROM raw_products
GROUP BY low_fat
ORDER BY low_fat;


-- Review store categorical values.
SELECT store_type, COUNT(*) AS record_count
FROM raw_stores
GROUP BY store_type
ORDER BY store_type;

SELECT store_country, COUNT(*) AS record_count
FROM raw_stores
GROUP BY store_country
ORDER BY store_country;

-- 5. CHECK NUMERIC VALUES AND RANGES
-- ============================================================

-- Check product price, cost, and weight ranges.
SELECT
    MIN(product_retail_price) AS min_retail_price,
    MAX(product_retail_price) AS max_retail_price,
    MIN(product_cost) AS min_cost,
    MAX(product_cost) AS max_cost,
    MIN(product_weight) AS min_weight,
    MAX(product_weight) AS max_weight
FROM raw_products;


-- Check for invalid product values.
SELECT *
FROM raw_products
WHERE product_retail_price <= 0
   OR product_cost < 0
   OR product_weight <= 0
   OR product_cost > product_retail_price;


-- Check sales quantity ranges.
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity
FROM raw_sales_1997;

SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity
FROM raw_sales_1998;


-- Check invalid sales quantities.
SELECT *
FROM raw_sales_1997
WHERE quantity <= 0;

SELECT *
FROM raw_sales_1998
WHERE quantity <= 0;


-- Check return quantity range and invalid values.
SELECT
    MIN(quantity) AS min_return_quantity,
    MAX(quantity) AS max_return_quantity
FROM raw_returns;

SELECT *
FROM raw_returns
WHERE quantity <= 0;


-- Check store size ranges.
SELECT
    MIN(total_sqft) AS min_total_sqft,
    MAX(total_sqft) AS max_total_sqft,
    MIN(grocery_sqft) AS min_grocery_sqft,
    MAX(grocery_sqft) AS max_grocery_sqft
FROM raw_stores;


-- Check logically invalid store size values.
SELECT *
FROM raw_stores
WHERE total_sqft <= 0
   OR grocery_sqft <= 0
   OR grocery_sqft > total_sqft;

-- 6. CHECK DATE QUALITY
-- ============================================================

-- Check for invalid zero dates created by unsuccessful date conversion.
SELECT *
FROM raw_sales_1997
WHERE transaction_date = '0000-00-00'
   OR stock_date = '0000-00-00';

SELECT *
FROM raw_sales_1998
WHERE transaction_date = '0000-00-00'
   OR stock_date = '0000-00-00';


-- Check whether stock dates occur after transaction dates.
SELECT *
FROM raw_sales_1997
WHERE stock_date > transaction_date;

SELECT *
FROM raw_sales_1998
WHERE stock_date > transaction_date;

/*
-- Check invalid return dates.// error
SELECT *
FROM raw_returns
WHERE return_date = '0000-00-00';


-- Check invalid calendar dates.
SELECT *
FROM raw_calendar
WHERE `date` = '0000-00-00';
*/
-- 7. CHECK FOREIGN KEY / ORPHAN RECORDS
-- ============================================================

-- Check whether sales product IDs exist in the product table.
SELECT COUNT(*) AS orphan_product_ids
FROM (
    SELECT product_id FROM raw_sales_1997
    UNION ALL
    SELECT product_id FROM raw_sales_1998
) s
LEFT JOIN raw_products p
    ON s.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Check whether sales customer IDs exist in the customer table.
SELECT COUNT(*) AS orphan_customer_ids
FROM (
    SELECT customer_id FROM raw_sales_1997
    UNION ALL
    SELECT customer_id FROM raw_sales_1998
) s
LEFT JOIN raw_customers c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Check whether sales store IDs exist in the store table.
SELECT COUNT(*) AS orphan_store_ids
FROM (
    SELECT store_id FROM raw_sales_1997
    UNION ALL
    SELECT store_id FROM raw_sales_1998
) s
LEFT JOIN raw_stores st
    ON s.store_id = st.store_id
WHERE st.store_id IS NULL;


-- Check whether return product IDs exist in the product table.
SELECT COUNT(*) AS orphan_return_product_ids
FROM raw_returns r
LEFT JOIN raw_products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Check whether return store IDs exist in the store table.
SELECT COUNT(*) AS orphan_return_store_ids
FROM raw_returns r
LEFT JOIN raw_stores s
    ON r.store_id = s.store_id
WHERE s.store_id IS NULL;


-- Check whether store region IDs exist in the region table.
SELECT COUNT(*) AS orphan_region_ids
FROM raw_stores s
LEFT JOIN raw_regions r
    ON s.region_id = r.region_id
WHERE r.region_id IS NULL;

-- DATA QUALITY ASSESSMENT COMPLETE
-- ============================================================

-- After identifying the data quality issues, the next step is to
-- investigate and resolve confirmed issues in 04_data_cleaning.sql.
SELECT
    store_id,
    COUNT(*) AS duplicate_count
FROM raw_stores
GROUP BY store_id
HAVING COUNT(*) > 1;