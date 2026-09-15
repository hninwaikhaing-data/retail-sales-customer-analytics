/* ============================================================
   05_DATA_TRANSFORMATION_MODELING.SQL

   Transform the cleaned retail data into an analysis-ready structure by integrating related datasets, defining fact and
   dimension tables, and creating analytical measures required for EDA, business analysis, and Power BI reporting.

   1. Select the project database
   2. Combine yearly sales data
   3. Create Customer Dimension
   4. Create Product Dimension
   5. Create Store Dimension and integrate Region information
   6. Create Date Dimension
   7. Create Sales Fact Table
   8. Create Returns Fact Table
   9. Validate the analytical data model
   ============================================================ */

/* ============================================================
   STEP 1: SELECT PROJECT DATABASE

   Select the retail project database to ensure that all data transformation and modeling operations are performed using the correct project tables.
   ============================================================ */

USE retail_db;
/* ============================================================
   STEP 2: COMBINE YEARLY SALES DATA
   ============================================================ */

DROP TABLE IF EXISTS sales_yearly;

CREATE TABLE sales_yearly AS
SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM sales_1997_clean

UNION ALL

SELECT
    transaction_date,
    stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM sales_1998_clean;

-- describe first transaction data and last transaction date of sales
SELECT
    COUNT(*) AS total_sales_records,
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date
FROM sales_yearly;

/* Validate the sales data consolidation by comparing the row counts of the 1997 and 1998 sales tables with the combined yearly sales table 
	to ensure that all transaction records were preserved.
*/
SELECT
    (SELECT COUNT(*) FROM sales_1997_clean) AS sales_1997_rows,
    (SELECT COUNT(*) FROM sales_1998_clean) AS sales_1998_rows,
    (SELECT COUNT(*) FROM sales_yearly) AS combined_sales_rows;

-- 1997 Sales       =  86,837
-- 1998 Sales       = 182,883 
-- Combined yearly salses records = 269,720 

/* ============================================================
   STEP 3: CREATE CUSTOMER DIMENSION
   ============================================================ */

DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer AS
SELECT
    customer_id,
    customer_city,
    customer_state_province,
    customer_country,
    birthdate,
    marital_status,
    yearly_income,
    gender,
    total_children,
    num_children_at_home,
    education,
    acct_open_date,
    member_card,
    occupation,
    homeowner
FROM customers_clean;

-- Compare the total rows with unique customer IDs to confirm that the Customer Dimension contains one record per customer.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM dim_customer;

-- Check for duplicate customer IDs that could cause an invalid one-to-many relationship between dim_customer and fact_sales.
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

/* ============================================================
   Transform the cleaned retail data into an analysis-ready dimensional model by separating descriptive business entities
   into dimension tables and measurable business events into fact tables.

   This structure reduces data repetition, improves consistency and supports efficient SQL analysis and Power BI reporting.
   STEP 4: CREATE PRODUCT DIMENSION
   ============================================================ */

DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product AS
SELECT
    product_id,
    product_brand,
    product_name,
    product_sku,
    product_retail_price,
    product_cost,
    product_weight,
    recyclable,
    low_fat
FROM products_clean;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM dim_product;

SELECT
    product_id,
    COUNT(*) AS record_count
FROM dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

/* ============================================================
   STEP 5: CREATE STORE DIMENSION
   ============================================================ */

DROP TABLE IF EXISTS dim_store;

CREATE TABLE dim_store AS
SELECT
    s.store_id,
    s.region_id,
    s.store_type,
    s.store_name,
    s.store_city,
    s.store_state,
    s.store_country,
    s.first_opened_date,
    s.last_remodel_date,
    s.total_sqft,
    s.grocery_sqft,
    r.sales_district,
    r.sales_region
FROM stores_clean AS s
LEFT JOIN regions_clean AS r
    ON s.region_id = r.region_id;

SELECT
    COUNT(*) AS total_stores,
    COUNT(DISTINCT store_id) AS unique_stores,
    SUM(sales_district IS NULL) AS missing_district,
    SUM(sales_region IS NULL) AS missing_region
FROM dim_store;

SELECT
    store_id,
    COUNT(*) AS record_count
FROM dim_store
GROUP BY store_id
HAVING COUNT(*) > 1;

select * from dim_store;
/* ============================================================
   STEP 6: CREATE DATE DIMENSION
   ============================================================ */

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT
    `date`,
    YEAR(`date`) AS year,
    QUARTER(`date`) AS quarter,
    MONTH(`date`) AS month_number,
    MONTHNAME(`date`) AS month_name,
    DATE_FORMAT(`date`, '%Y-%m') AS yearmonth,
    DAY(`date`) AS day_of_month,
    DAYNAME(`date`) AS day_name
FROM calendar_clean;

SELECT
    COUNT(*) AS total_dates,
    COUNT(DISTINCT `date`) AS unique_dates,
    MIN(`date`) AS first_date,
    MAX(`date`) AS last_date
FROM dim_date;

select * from dim_date;
/* ============================================================
   STEP 7: CREATE SALES FACT TABLE
   ============================================================ */

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales AS
SELECT
    s.transaction_date,
    s.stock_date,
    s.product_id,
    s.customer_id,
    s.store_id,
    s.quantity,
    p.product_retail_price,
    p.product_cost,
    ROUND(s.quantity * p.product_retail_price, 2) AS estimated_sales,
    ROUND(s.quantity * p.product_cost, 2) AS estimated_cogs,
    ROUND(
        (s.quantity * p.product_retail_price)
        - (s.quantity * p.product_cost),
        2
    ) AS estimated_gross_profit
FROM sales_yearly AS s
LEFT JOIN dim_product AS p
    ON s.product_id = p.product_id;

SELECT
    COUNT(*) AS total_sales_records,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(estimated_sales), 2) AS total_estimated_sales,
    ROUND(SUM(estimated_cogs), 2) AS total_estimated_cogs,
    ROUND(SUM(estimated_gross_profit), 2) AS total_estimated_gross_profit
FROM fact_sales;

SELECT COUNT(*) AS unmatched_product_records
FROM fact_sales
WHERE product_retail_price IS NULL
   OR product_cost IS NULL;

/* ============================================================
   STEP 8: CREATE RETURNS FACT TABLE
   ============================================================ */

DROP TABLE IF EXISTS fact_returns;

CREATE TABLE fact_returns AS
SELECT
    return_date,
    product_id,
    store_id,
    quantity AS returned_quantity
FROM returns_clean;

/*
	Validate the Returns Fact Table by summarizing the total return records,returned quantity, unique returned products, and stores 
    with return activity to confirm that the transformed return data is complete and ready for analysis.
*/
SELECT
    COUNT(*) AS total_return_records,
    SUM(returned_quantity) AS total_returned_quantity,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT store_id) AS stores_with_returns
FROM fact_returns;

/* ============================================================
   TABLE RELATIONSHIPS

   The analytical model follows a star-schema structure where fact tables contain measurable business events and
   dimension tables provide descriptive attributes for those events.

   Sales Fact Relationships:
   - fact_sales.customer_id      → dim_customer.customer_id
   - fact_sales.product_id       → dim_product.product_id
   - fact_sales.store_id         → dim_store.store_id
   - fact_sales.transaction_date → dim_date.date

   Returns Fact Relationships:
   - fact_returns.product_id     → dim_product.product_id
   - fact_returns.store_id       → dim_store.store_id
   - fact_returns.return_date    → dim_date.date

   Each dimension record can relate to many fact records, creating one-to-many (1:*) relationships.

   The Returns Fact Table does not connect to dim_customer because the source returns dataset does not contain customer_id.
   ============================================================ */

/* ============================================================
   STEP 9: VALIDATE FACT-TO-DIMENSION RELATIONSHIPS
   
   Validate the relationships between fact and dimension tables to ensure that every foreign key in the fact tables has 
   a corresponding record in the related dimension table.

   This step helps identify unmatched records that could cause missing, inaccurate, or incomplete results in SQL analysis and Power BI reporting.
   ============================================================ */

SELECT COUNT(*) AS unmatched_customers
FROM fact_sales AS f
LEFT JOIN dim_customer AS c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS unmatched_products
FROM fact_sales AS f
LEFT JOIN dim_product AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS unmatched_stores
FROM fact_sales AS f
LEFT JOIN dim_store AS s
    ON f.store_id = s.store_id
WHERE s.store_id IS NULL;

SELECT COUNT(*) AS unmatched_sales_dates
FROM fact_sales AS f
LEFT JOIN dim_date AS d
    ON f.transaction_date = d.`date`
WHERE d.`date` IS NULL;

SELECT COUNT(*) AS unmatched_return_products
FROM fact_returns AS r
LEFT JOIN dim_product AS p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS unmatched_return_stores
FROM fact_returns AS r
LEFT JOIN dim_store AS s
    ON r.store_id = s.store_id
WHERE s.store_id IS NULL;

SELECT COUNT(*) AS unmatched_return_dates
FROM fact_returns AS r
LEFT JOIN dim_date AS d
    ON r.return_date = d.`date`
WHERE d.`date` IS NULL;

/* ============================================================
   STEP 10: VALIDATE BUSINESS RULES
   
    Validate key business rules and analytical measures to ensure that the transformed data is logically consistent and suitable
   for reliable analysis and reporting.

   This step checks for invalid quantities, negative financial values, and inconsistencies in calculated measures that could
   produce misleading business insights.
   ============================================================ */

-- Check for invalid sales records where the quantity is zero because a valid sales transaction should contain at least one unit sold.
SELECT COUNT(*) AS invalid_sales_quantity
FROM fact_sales
WHERE quantity <= 0;

-- Check for invalid return records where the returned quantity is zero because a valid return transaction should contain at least one returned unit.
SELECT COUNT(*) AS invalid_return_quantity
FROM fact_returns
WHERE returned_quantity <= 0;

-- Check for negative Estimated Sales or Estimated COGS values that could indicate invalid source data or errors in the financial calculations.
SELECT COUNT(*) AS invalid_financial_records
FROM fact_sales
WHERE estimated_sales < 0
   OR estimated_cogs < 0;

/* Validate the Estimated Gross Profit calculation by checking for records where gross profit does not equal Estimated Sales minus Estimated COGS,
 allowing a small tolerance of 0.01 for decimal rounding differences. */

-- Use ABS() to measure the difference regardless of its positive or negative direction, ensuring that all profit inconsistencies are detected.
SELECT COUNT(*) AS inconsistent_profit_records
FROM fact_sales
WHERE ABS(
    estimated_gross_profit -
    (estimated_sales - estimated_cogs)
) > 0.01;

/* ============================================================
   STEP 11: FINAL MODEL VALIDATION
   Perform a final validation of the analytical data model by reviewing the row counts of all fact and dimension tables.

   This step confirms that the required analytical tables were created successfully and contain the expected data before
   proceeding to EDA, business analysis, and Power BI reporting.
   ============================================================ */

SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count
FROM dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL
SELECT 'fact_returns', COUNT(*) FROM fact_returns;

/* ============================================================
   TRANSFORMATION & MODELING RESULT

   Final Dimensions:
   - dim_customer
   - dim_product
   - dim_store
   - dim_date

   Final Facts:
   - fact_sales
   - fact_returns

   The analytical model is ready for:
   06_EDA.sql
   ============================================================ */
