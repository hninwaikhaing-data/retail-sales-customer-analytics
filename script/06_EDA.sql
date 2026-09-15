/* ============================================================
   06_EDA.SQL
   EXPLORATORY DATA ANALYSIS

   Explore the transformed retail data to understand its overall structure, distributions, trends, customer characteristics, product performance, store patterns, 
   geographic differences, estimated profitability, and return activity.

   EDA is used to discover important patterns and unusual behavior before performing the final business-question analysis.

   1. Review analytical tables
   2. Review date coverage and overall data scale
   3. Explore sales quantity and financial distributions
   4. Explore sales trends over time
   5. Explore customer characteristics
   6. Explore product and brand performance
   7. Explore store and geographic patterns
   8. Explore return activity
   9. Compare sales and returns at compatible aggregation levels
   10. Summarize EDA findings
   ============================================================ */


-- Select the retail project database to ensure all EDA queries
-- are executed against the correct analytical tables.

USE retail_db;

/* ============================================================
   STEP 1: REVIEW ANALYTICAL TABLES

   Review the analytical fact and dimension tables created during the transformation and modeling stage to understand their
   structure and available fields before beginning EDA.
   ============================================================ */

SHOW TABLES;

-- Review records from the Sales Fact Table.
SELECT *
FROM fact_sales
LIMIT 10;

-- Review records from the Returns Fact Table.
SELECT *
FROM fact_returns
LIMIT 10;

-- Review records from the Customer Dimension.
SELECT *
FROM dim_customer
LIMIT 10;

-- Review records from the Product Dimension.
SELECT *
FROM dim_product
LIMIT 10;

-- Review records from the Store Dimension.
SELECT *
FROM dim_store
LIMIT 10;

-- Review records from the Date Dimension.
SELECT *
FROM dim_date
LIMIT 10;


/* ============================================================
   STEP 2: CHECK DATE COVERAGE AND DATA SCALE

   Understand the reporting period and overall size of the analytical dataset before exploring detailed business patterns.
   ============================================================ */

-- Check the sales reporting period and number of active sales days.
SELECT
    MIN(transaction_date) AS first_sales_date,
    MAX(transaction_date) AS last_sales_date,
    COUNT(DISTINCT transaction_date) AS active_sales_days
FROM fact_sales;

-- Check the return date coverage to confirm the period represented in the returns data and understand how many days recorded return activity.
SELECT
    MIN(return_date) AS first_return_date,
    MAX(return_date) AS last_return_date,
    COUNT(DISTINCT return_date) AS active_return_days
FROM fact_returns;

-- Review the overall scale of sales activity.
SELECT
    COUNT(*) AS sales_records,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(DISTINCT product_id) AS products_sold,
    COUNT(DISTINCT store_id) AS active_stores
FROM fact_sales;

-- Review the overall estimated financial scale of the retail business.
SELECT
    ROUND(SUM(estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(estimated_cogs), 2) AS estimated_cogs,
    ROUND(SUM(estimated_gross_profit), 2) AS estimated_gross_profit,
    ROUND(
        SUM(estimated_gross_profit)
        / NULLIF(SUM(estimated_sales), 0) * 100,
        2
    ) AS estimated_gross_margin_pct
FROM fact_sales;

-- Review the overall scale of return activity.
-- measures the total number of return records, total units returned, number of unique products with returns, and number of stores that recorded return activity.
SELECT
    COUNT(*) AS return_records,
    SUM(returned_quantity) AS returned_units,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT store_id) AS stores_with_returns
FROM fact_returns;


/* ============================================================
   STEP 3: EXPLORE SALES QUANTITY AND FINANCIAL DISTRIBUTIONS

   Examine the range, frequency, and average of key transaction-level sales and financial measures to understand their general
   distributions and identify potentially unusual observations.

   Unusual values are investigated rather than automatically removed because they may represent valid business behavior.
   ============================================================ */

-- Explore the sales quantity distribution to understand how frequently each quantity occurs and identify any unusual transaction quantities.
-- Analyze the distribution of sales quantities to identify typical purchasing patterns and detect unusual quantity values for further investigation.
SELECT
    quantity,
    COUNT(*) AS record_count
FROM fact_sales
GROUP BY quantity
ORDER BY quantity;

-- Explore the return quantity distribution to understand how frequently each returned quantity occurs and identify any unusual return values.
-- For each returned quantity, how many return records have that quantity
SELECT
    returned_quantity,
    COUNT(*) AS record_count
FROM fact_returns
GROUP BY returned_quantity
ORDER BY returned_quantity;

-- Review transaction-level Estimated Sales distribution.
SELECT
    ROUND(MIN(estimated_sales), 2) AS min_estimated_sales,
    ROUND(AVG(estimated_sales), 2) AS avg_estimated_sales,
    ROUND(MAX(estimated_sales), 2) AS max_estimated_sales
FROM fact_sales;

-- Review transaction-level Estimated COGS distribution.
SELECT
    ROUND(MIN(estimated_cogs), 2) AS min_estimated_cogs,
    ROUND(AVG(estimated_cogs), 2) AS avg_estimated_cogs,
    ROUND(MAX(estimated_cogs), 2) AS max_estimated_cogs
FROM fact_sales;

-- Review transaction-level Estimated Gross Profit distribution.
SELECT
    ROUND(MIN(estimated_gross_profit), 2) AS min_estimated_gross_profit,
    ROUND(AVG(estimated_gross_profit), 2) AS avg_estimated_gross_profit,
    ROUND(MAX(estimated_gross_profit), 2) AS max_estimated_gross_profit
FROM fact_sales;

-- Review records with the highest transaction-level Estimated Sales
-- to investigate unusual observations without automatically removing them.
SELECT
    transaction_date,
    product_id,
    customer_id,
    store_id,
    quantity,
    estimated_sales,
    estimated_cogs,
    estimated_gross_profit
FROM fact_sales
ORDER BY estimated_sales DESC
LIMIT 20;


/* ============================================================
   STEP 4: EXPLORE SALES TRENDS OVER TIME

   Explore how sales volume and estimated financial performance change across years, months, and days of the week to identify
   temporal patterns and possible seasonality.
   ============================================================ */

-- Explore yearly sales performance.
SELECT
    YEAR(transaction_date) AS year,
    COUNT(*) AS sales_records,
    SUM(quantity) AS units_sold,
    ROUND(SUM(estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales
GROUP BY YEAR(transaction_date)
ORDER BY year;

-- Explore monthly sales trends across the reporting period.
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS yearmonth,
    COUNT(*) AS sales_records,
    SUM(quantity) AS units_sold,
    ROUND(SUM(estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY yearmonth;

-- Explore month-of-year patterns across all available years.
SELECT
    MONTH(transaction_date) AS month_number,
    MONTHNAME(transaction_date) AS month_name,
    SUM(quantity) AS units_sold,
    ROUND(SUM(estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales
GROUP BY
    MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY month_number;

select * from fact_sales;
-- Explore sales activity by day of the week to understand how transaction volume, units sold, and Estimated Sales vary
-- across weekdays and identify possible weekly purchasing patterns.
SELECT
    DAYNAME(transaction_date) AS day_name,
    COUNT(*) AS sales_records,
    SUM(quantity) AS units_sold,
    ROUND(SUM(estimated_sales), 2) AS estimated_sales
FROM fact_sales
GROUP BY
    WEEKDAY(transaction_date),
    DAYNAME(transaction_date)
ORDER BY
    WEEKDAY(transaction_date);


/* ============================================================
   STEP 5: EXPLORE CUSTOMER CHARACTERISTICS

   Explore customer composition and purchasing behavior across important customer attributes to understand how purchasing
   patterns differ between customer groups.
   ============================================================ */

-- Explore customer distribution by membership type.
SELECT
    member_card,
    COUNT(*) AS customer_count
FROM dim_customer
GROUP BY member_card
ORDER BY customer_count DESC;

-- Explore customer distribution by country.
SELECT
    customer_country,
    COUNT(*) AS customer_count
FROM dim_customer
GROUP BY customer_country
ORDER BY customer_count DESC;

-- Explore customer distribution by gender.
SELECT
    gender,
    COUNT(*) AS customer_count
FROM dim_customer
GROUP BY gender
ORDER BY customer_count DESC;

-- Explore customer distribution by yearly income.
SELECT
    yearly_income,
    COUNT(*) AS customer_count
FROM dim_customer
GROUP BY yearly_income
ORDER BY customer_count DESC;

-- Explore customer distribution by occupation.
SELECT
    occupation,
    COUNT(*) AS customer_count
FROM dim_customer
GROUP BY occupation
ORDER BY customer_count DESC;

-- Explore purchasing behavior by membership type.
SELECT
    c.member_card,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_customer AS c
    ON f.customer_id = c.customer_id
GROUP BY c.member_card
ORDER BY estimated_sales DESC;

-- Explore purchasing behavior by income group.
SELECT
    c.yearly_income,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales
FROM fact_sales AS f
JOIN dim_customer AS c
    ON f.customer_id = c.customer_id
GROUP BY c.yearly_income
ORDER BY estimated_sales DESC;


/* ============================================================
   STEP 6: EXPLORE PRODUCT AND BRAND PERFORMANCE

   Explore sales volume, Estimated Sales, and Estimated Gross
   Profit across products and brands to identify high-performing,
   low-performing, and potentially unusual product patterns.
   ============================================================ */

-- Review the number of products and brands in the Product Dimension.
SELECT
    COUNT(DISTINCT product_id) AS total_products,
    COUNT(DISTINCT product_brand) AS total_brands
FROM dim_product;

-- Explore the top 10 products by Estimated Sales.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_product AS p
    ON f.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.product_brand
ORDER BY estimated_sales DESC
LIMIT 10;

-- Explore the bottom 10 products by Estimated Sales among products sold.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_product AS p
    ON f.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.product_brand
ORDER BY estimated_sales ASC
LIMIT 10;

-- Explore performance by product brand.
SELECT
    p.product_brand,
    COUNT(DISTINCT p.product_id) AS products_sold,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_product AS p
    ON f.product_id = p.product_id
GROUP BY p.product_brand
ORDER BY estimated_sales DESC;


/* ============================================================
   STEP 7: EXPLORE STORE AND GEOGRAPHIC PATTERNS

   Explore how business activity varies across stores, store
   formats, countries, districts, and regions to understand
   operational and geographic performance differences.
   ============================================================ */

-- Explore store distribution by store format.
SELECT
    store_type,
    COUNT(*) AS store_count
FROM dim_store
GROUP BY store_type
ORDER BY store_count DESC;

-- Explore performance across individual stores.
SELECT
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_country,
    s.total_sqft,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_store AS s
    ON f.store_id = s.store_id
GROUP BY
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_country,
    s.total_sqft
ORDER BY estimated_sales DESC;

-- Explore performance by store format.
SELECT
    s.store_type,
    COUNT(DISTINCT s.store_id) AS stores,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_store AS s
    ON f.store_id = s.store_id
GROUP BY s.store_type
ORDER BY estimated_sales DESC;

-- Explore performance by store country.
SELECT
    s.store_country,
    COUNT(DISTINCT s.store_id) AS stores,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_store AS s
    ON f.store_id = s.store_id
GROUP BY s.store_country
ORDER BY estimated_sales DESC;

-- Explore performance by sales region.
SELECT
    s.sales_region,
    COUNT(DISTINCT s.store_id) AS stores,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales), 2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit), 2) AS estimated_gross_profit
FROM fact_sales AS f
JOIN dim_store AS s
    ON f.store_id = s.store_id
GROUP BY s.sales_region
ORDER BY estimated_sales DESC;


/* ============================================================
   STEP 8: EXPLORE RETURN ACTIVITY

   Explore return volume and concentration across time, products, stores, and locations to identify return patterns requiring
   deeper investigation.

   Customer-level return analysis is not performed because the Returns Fact Table does not contain customer_id.
   ============================================================ */

-- Review overall return activity.
SELECT
    COUNT(*) AS return_records,
    SUM(returned_quantity) AS returned_units,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT store_id) AS stores_with_returns
FROM fact_returns;

-- Explore monthly return activity.
SELECT
    DATE_FORMAT(return_date, '%Y-%m') AS yearmonth,
    COUNT(*) AS return_records,
    SUM(returned_quantity) AS returned_units
FROM fact_returns
GROUP BY DATE_FORMAT(return_date, '%Y-%m')
ORDER BY yearmonth;

-- Explore products with the highest returned quantity.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns AS r
JOIN dim_product AS p
    ON r.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.product_brand
ORDER BY returned_units DESC
LIMIT 10;

-- Explore return activity by store.
SELECT
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_country,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns AS r
JOIN dim_store AS s
    ON r.store_id = s.store_id
GROUP BY
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_country
ORDER BY returned_units DESC;

-- Explore return activity by country.
SELECT
    s.store_country,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns AS r
JOIN dim_store AS s
    ON r.store_id = s.store_id
GROUP BY s.store_country
ORDER BY returned_units DESC;


/* ============================================================
   STEP 9: EXPLORE SALES VS RETURNS AT COMPATIBLE GRAIN

   Sales and returns must be aggregated separately before they are joined because the two fact tables do not share the same transaction-level grain.

   Both tables are aggregated to Product + Store level to avoid  many-to-many row multiplication and misleading return metrics.
   ============================================================ */

WITH sales_summary AS (
    SELECT
        product_id,
        store_id,
        SUM(quantity) AS units_sold,
        SUM(estimated_sales) AS estimated_sales
    FROM fact_sales
    GROUP BY
        product_id,
        store_id
),
returns_summary AS (
    SELECT
        product_id,
        store_id,
        SUM(returned_quantity) AS returned_units
    FROM fact_returns
    GROUP BY
        product_id,
        store_id
)
SELECT
    s.product_id,
    s.store_id,
    s.units_sold,
    ROUND(s.estimated_sales, 2) AS estimated_sales,
    COALESCE(r.returned_units, 0) AS returned_units,
    ROUND(
        COALESCE(r.returned_units, 0)
        / NULLIF(s.units_sold, 0) * 100,
        2
    ) AS return_rate_pct
FROM sales_summary AS s
LEFT JOIN returns_summary AS r
    ON s.product_id = r.product_id
   AND s.store_id = r.store_id
ORDER BY return_rate_pct DESC;


/* ============================================================
   STEP 10: SUMMARIZE EDA FINDINGS

   The EDA stage has explored the major patterns and characteristics of the analytical retail dataset before formal business analysis.

   Areas reviewed:
   - Analytical table structure
   - Reporting period and overall data scale
   - Sales quantity and financial distributions
   - Potential unusual observations
   - Sales trends over time
   - Customer characteristics and purchasing patterns
   - Product and brand performance
   - Store and geographic patterns
   - Return activity
   - Sales and returns at compatible aggregation levels

   Important EDA Principle:
   extreme values are not automatically removed because they may represent valid and meaningful business behavior.
   Any suspicious observations should first be investigated and corrected only when confirmed as data-quality problems.

  Now ready for: 07_business_analysis.sql

   The Business Analysis stage will use the EDA findings and KPI
   framework to answer the defined business questions.
   ============================================================ */
