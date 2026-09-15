/* ============================================================
   04_DATA_CLEANING.SQL

   Now we clean the retail data by following a few key steps:
   1. Check duplicate records and remove only confirmed duplicates
   2. Standardize inconsistent data and fix identified errors
   3. Review NULL and missing values and decide the appropriate treatment
   4. Remove unnecessary columns or rows that are not needed for analysis
   5. Validate the cleaned data before moving to transformation and modeling
   ============================================================ */

USE retail_db;


/* ============================================================
   STEP 1: CHECK DUPLICATES
   Check for duplicate records to prevent repeated observations from distorting analytical results, and remove only duplicates that can be confirmed as invalid.
   ============================================================ */

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

/*
To detect potential duplicate transaction and return records that could cause double counting, while avoiding deletion unless the repeated records can be confirmed as true duplicates. 
*/
-- Check for duplicate-looking records in the sales and returns tables by identifying identical combinations of transaction attributes.
-- Check duplicate-looking rows in 1997 sales data.
-- Do not remove automatically because there is no transaction_id.
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


-- Check duplicate-looking rows in 1998 sales data.
-- Do not remove automatically because there is no transaction_id.
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


-- Check duplicate-looking return rows.
-- Do not remove automatically because there is no return_id.
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



/* ============================================================
   STEP 2: STANDARDIZE DATA AND FIX ERRORS
   Standardize inconsistent formats, categories, and values to ensure that equivalent data is represented consistently throughout the dataset.
   -- Use TRIM() to remove unnecessary leading and trailing spaces and NULLIF() to convert blank text values into NULL, ensuring consistent text formatting
	and a standard representation of missing values in the cleaned dataset.
   ============================================================ */

-- Create a clean customer table and standardize inconsistent text and categorical values for analysis.
DROP TABLE IF EXISTS customers_clean;

CREATE TABLE customers_clean AS
SELECT
    customer_id,
    customer_acct_num,
    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(last_name), '') AS last_name,
    NULLIF(TRIM(customer_address), '') AS customer_address,
    NULLIF(TRIM(customer_city), '') AS customer_city,
    NULLIF(TRIM(customer_state_province), '') AS customer_state_province,
    NULLIF(TRIM(customer_postal_code), '') AS customer_postal_code,

    CASE
        WHEN UPPER(TRIM(customer_country)) IN
             ('USA', 'U.S.A.', 'UNITED STATES')
            THEN 'USA'
        WHEN UPPER(TRIM(customer_country)) = 'CANADA'
            THEN 'Canada'
        WHEN UPPER(TRIM(customer_country)) = 'MEXICO'
            THEN 'Mexico'
        ELSE NULLIF(TRIM(customer_country), '')
    END AS customer_country,
    birthdate,
    UPPER(NULLIF(TRIM(marital_status), '')) AS marital_status,
    NULLIF(TRIM(yearly_income), '') AS yearly_income,
    UPPER(NULLIF(TRIM(gender), '')) AS gender,
    total_children,
    num_children_at_home,
    NULLIF(TRIM(education), '') AS education,
    acct_open_date,

    CASE
        WHEN LOWER(TRIM(member_card)) = 'bronze'
            THEN 'Bronze'
        WHEN LOWER(TRIM(member_card)) = 'silver'
            THEN 'Silver'
        WHEN LOWER(TRIM(member_card)) = 'golden'
            THEN 'Golden'
        WHEN LOWER(TRIM(member_card)) = 'normal'
            THEN 'Normal'
        ELSE NULLIF(TRIM(member_card), '')
    END AS member_card,
    NULLIF(TRIM(occupation), '') AS occupation,
    UPPER(NULLIF(TRIM(homeowner), '')) AS homeowner
FROM raw_customers;



-- Create clean product table.

DROP TABLE IF EXISTS products_clean;

CREATE TABLE products_clean AS
SELECT
    product_id,
    NULLIF(TRIM(product_brand), '') AS product_brand,
    NULLIF(TRIM(product_name), '') AS product_name,
    product_sku,
    product_retail_price,
    product_cost,
    product_weight,
    recyclable,
    low_fat
FROM raw_products;



-- Create clean store table and standardize country values.

DROP TABLE IF EXISTS stores_clean;

CREATE TABLE stores_clean AS
SELECT
    store_id,
    region_id,
    NULLIF(TRIM(store_type), '') AS store_type,
    NULLIF(TRIM(store_name), '') AS store_name,
    NULLIF(TRIM(store_street_address), '') AS store_street_address,
    NULLIF(TRIM(store_city), '') AS store_city,
    NULLIF(TRIM(store_state), '') AS store_state,

    CASE
        WHEN UPPER(TRIM(store_country)) IN
             ('USA', 'U.S.A.', 'UNITED STATES')
            THEN 'USA'

        WHEN UPPER(TRIM(store_country)) = 'CANADA'
            THEN 'Canada'

        WHEN UPPER(TRIM(store_country)) = 'MEXICO'
            THEN 'Mexico'

        ELSE NULLIF(TRIM(store_country), '')
    END AS store_country,

    NULLIF(TRIM(store_phone), '') AS store_phone,
    first_opened_date,
    last_remodel_date,
    total_sqft,
    grocery_sqft

FROM raw_stores;



-- Create clean region table.

DROP TABLE IF EXISTS regions_clean;

CREATE TABLE regions_clean AS
SELECT
    region_id,
    NULLIF(TRIM(sales_district), '') AS sales_district,
    NULLIF(TRIM(sales_region), '') AS sales_region
FROM raw_regions;



-- Create clean 1997 sales table.
-- Duplicate-looking rows are preserved.

DROP TABLE IF EXISTS sales_1997_clean;

CREATE TABLE sales_1997_clean AS
SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM raw_sales_1997;



-- Create clean 1998 sales table.
-- Duplicate-looking rows are preserved.

DROP TABLE IF EXISTS sales_1998_clean;

CREATE TABLE sales_1998_clean AS
SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM raw_sales_1998;



-- Create clean returns table.

DROP TABLE IF EXISTS returns_clean;

CREATE TABLE returns_clean AS
SELECT
    return_date,
    product_id,
    store_id,
    quantity
FROM raw_returns;



-- Create clean calendar table.

DROP TABLE IF EXISTS calendar_clean;

CREATE TABLE calendar_clean AS
SELECT
    `date`
FROM raw_calendar;



/* ============================================================
   STEP 3: HANDLE MISSING / NULL VALUES
   Review missing and NULL values to understand their significance and apply an appropriate treatment without introducing misleading assumptions.
   ============================================================ */

-- Review customer missing values after standardization.
/*

Check missing values in customer data to identify incomplete customer information and determine whether each missing value should be kept,
corrected, replaced, or excluded based on its analytical importance.
*/

SELECT
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(last_name IS NULL) AS last_name_nulls,
    SUM(customer_country IS NULL) AS country_nulls,
    SUM(birthdate IS NULL) AS birthdate_nulls,
    SUM(yearly_income IS NULL) AS income_nulls,
    SUM(gender IS NULL) AS gender_nulls,
    SUM(member_card IS NULL) AS member_card_nulls
FROM customers_clean;

/*
-- Check missing values in product data to determine whether incomplete product attributes could affect product, pricing, cost, or profitability analysis.
*/
SELECT
    SUM(recyclable IS NULL) AS recyclable_nulls,
    SUM(low_fat IS NULL) AS low_fat_nulls
FROM products_clean;



-- Check missing values in product data to determine whether incomplete
-- product attributes could affect product, pricing, cost, or profitability analysis.

SELECT
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(product_brand IS NULL OR TRIM(product_brand) = '') AS brand_missing,
    SUM(product_name IS NULL OR TRIM(product_name) = '') AS product_name_missing,
    SUM(product_retail_price IS NULL) AS retail_price_nulls,
    SUM(product_cost IS NULL) AS cost_nulls,
    SUM(product_weight IS NULL) AS weight_nulls,
    SUM(recyclable IS NULL) AS recyclable_nulls,
    SUM(low_fat IS NULL) AS low_fat_nulls
FROM products_clean;


-- Check missing values in store data to ensure that key store,
-- geographic, and operational attributes are available for store analysis.

SELECT
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(region_id IS NULL) AS region_id_nulls,
    SUM(store_type IS NULL OR TRIM(store_type) = '') AS store_type_missing,
    SUM(store_name IS NULL OR TRIM(store_name) = '') AS store_name_missing,
    SUM(store_city IS NULL OR TRIM(store_city) = '') AS city_missing,
    SUM(store_country IS NULL OR TRIM(store_country) = '') AS country_missing,
    SUM(total_sqft IS NULL) AS total_sqft_nulls,
    SUM(grocery_sqft IS NULL) AS grocery_sqft_nulls
FROM stores_clean;


-- Check missing values in region data to ensure complete geographic
-- classifications for regional and district-level performance analysis.

SELECT
    SUM(region_id IS NULL) AS region_id_nulls,
    SUM(sales_district IS NULL OR TRIM(sales_district) = '') AS district_missing,
    SUM(sales_region IS NULL OR TRIM(sales_region) = '') AS region_missing
FROM regions_clean;


-- Check missing values in 1997 sales data to ensure that essential
-- transaction fields are complete before sales analysis and modeling.

SELECT
    SUM(transaction_date IS NULL) AS transaction_date_nulls,
    SUM(stock_date IS NULL) AS stock_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM sales_1997_clean;


-- Check missing values in 1998 sales data to ensure that essential
-- transaction fields are complete before sales analysis and modeling.

SELECT
    SUM(transaction_date IS NULL) AS transaction_date_nulls,
    SUM(stock_date IS NULL) AS stock_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM sales_1998_clean;

-- Check missing values in return data to ensure that return events
-- contain the required date, product, store, and quantity information.

SELECT
    SUM(return_date IS NULL) AS return_date_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls
FROM returns_clean;


-- Check missing calendar dates to ensure the date dimension provides
-- complete and reliable time coverage for trend and time-based analysis.

SELECT
    SUM(`date` IS NULL) AS date_nulls
FROM calendar_clean;

-- Result:
-- No missing or NULL values were found in the checked fields.
-- Therefore, no imputation, replacement, or row removal was required.



/* ============================================================
   STEP 4: REMOVE UNNECESSARY DATA
   Remove unnecessary data that does not support the analytical objectives while preserving the original source data in the raw layer.
   ============================================================ */

-- Keep raw and clean staging tables unchanged.
-- Remove unnecessary fields later when creating the analytical customer and store dimensions.

-- Fields that can be excluded from the analytical layer:
-- customer_acct_num
-- first_name
-- last_name
-- customer_address
-- customer_postal_code
-- store_street_address
-- store_phone

-- These fields are not deleted here because preserving source data provides traceability and makes the cleaning process reproducible.

/*
 Review the cleaned dataset to identify columns that are not required for the project objectives, business questions, KPI calculations, or downstream Power BI analysis.
 
  Unnecessary fields are not deleted from the cleaned tables. They will be excluded later when creating the final analytical fact and dimension tables.
   ============================================================ */


	-- Review customer identification and contact fields 
	SELECT
		customer_acct_num,
		first_name,
		last_name,
		customer_address,
		customer_postal_code
	FROM customers_clean
	LIMIT 10;
    
    -- Review store contact and detailed address fields that are not required for store performance and geographic analysis.

	SELECT
		store_street_address,
		store_phone
	FROM stores_clean
	LIMIT 10;
    
    -- Check whether any sales records have missing key fields that would
-- make the records unusable for downstream analysis.

/*
   The cleaned tables are preserved to maintain data traceability
   and allow future analysis if additional fields are required.
   ============================================================ */
   
/* ============================================================
   STEP 5: FINAL VALIDATION
   Validate the cleaned dataset to confirm that identified quality issues were resolved correctly and that the data is ready for transformation and analysis.
   ============================================================ */

-- Validate row counts after cleaning.

SELECT
    'sales_1997_clean' AS table_name,
    COUNT(*) AS row_count
FROM sales_1997_clean

UNION ALL

SELECT
    'sales_1998_clean',
    COUNT(*)
FROM sales_1998_clean

UNION ALL

SELECT
    'customers_clean',
    COUNT(*)
FROM customers_clean

UNION ALL

SELECT
    'products_clean',
    COUNT(*)
FROM products_clean

UNION ALL

SELECT
    'stores_clean',
    COUNT(*)
FROM stores_clean

UNION ALL

SELECT
    'regions_clean',
    COUNT(*)
FROM regions_clean

UNION ALL

SELECT
    'returns_clean',
    COUNT(*)
FROM returns_clean

UNION ALL

SELECT
    'calendar_clean',
    COUNT(*)
FROM calendar_clean;

/* after cleaning data, all row count 
-- Expected source row counts for this project:
-- sales_1997=86837, sales_1998=182883, customers=10281,
-- products=1560, stores=48, regions=109, returns=7087, calendar=730.
*/


-- Validate standardized customer categories.

SELECT
    customer_country,
    COUNT(*) AS record_count
FROM customers_clean
GROUP BY customer_country
ORDER BY customer_country;


SELECT
    member_card,
    COUNT(*) AS record_count
FROM customers_clean
GROUP BY member_card
ORDER BY member_card;


SELECT
    gender,
    COUNT(*) AS record_count
FROM customers_clean
GROUP BY gender
ORDER BY gender;


SELECT
    marital_status,
    COUNT(*) AS record_count
FROM customers_clean
GROUP BY marital_status
ORDER BY marital_status;


SELECT
    homeowner,
    COUNT(*) AS record_count
FROM customers_clean
GROUP BY homeowner
ORDER BY homeowner;



-- Validate product numeric values.

SELECT *
FROM products_clean
WHERE product_retail_price <= 0
   OR product_cost < 0
   OR product_cost > product_retail_price
   OR product_weight <= 0;



-- Validate sales quantities.

SELECT *
FROM sales_1997_clean
WHERE quantity <= 0;

SELECT *
FROM sales_1998_clean
WHERE quantity <= 0;



-- Validate return quantities.

SELECT *
FROM returns_clean
WHERE quantity <= 0;



-- Validate store size logic.

SELECT *
FROM stores_clean
WHERE total_sqft <= 0
   OR grocery_sqft <= 0
   OR grocery_sqft > total_sqft;



-- Validate date values.

SELECT *
FROM sales_1997_clean
WHERE transaction_date IS NULL
   OR stock_date IS NULL;

SELECT *
FROM sales_1998_clean
WHERE transaction_date IS NULL
   OR stock_date IS NULL;

SELECT *
FROM returns_clean
WHERE return_date IS NULL;

SELECT *
FROM calendar_clean
WHERE `date` IS NULL;



-- Validate customer key uniqueness.

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Validate product key uniqueness.

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM products_clean
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Validate store key uniqueness.

SELECT
    store_id,
    COUNT(*) AS duplicate_count
FROM stores_clean
GROUP BY store_id
HAVING COUNT(*) > 1;


-- Validate region key uniqueness.

SELECT
    region_id,
    COUNT(*) AS duplicate_count
FROM regions_clean
GROUP BY region_id
HAVING COUNT(*) > 1;


/* ============================================================
   DATA CLEANING COMPLETE

   The cleaned retail datasets are now ready for:
   05_data_transformation_modeling.sql
   ============================================================ */