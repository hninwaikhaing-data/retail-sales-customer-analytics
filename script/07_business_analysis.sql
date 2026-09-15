/* ============================================================
   07_BUSINESS_ANALYSIS.SQL
   RETAIL SALES & CUSTOMER PERFORMANCE ANALYTICS

   Answer the project's five defined business questions using the analysis-ready fact and dimension tables.

   BQ1 Overall Business Performance
   BQ2 Customer Performance & Segmentation
   BQ3 Product & Brand Performance
   BQ4 Store & Geographic Performance
   BQ5 Return Analysis

   Notes:
   - Financial measures are labeled Estimated because retail price is used as the analytical price proxy.
   - Returns contain no customer_id or original transaction_id.
   - Sales and returns must be aggregated separately before comparison.
   ============================================================ */

USE retail_db;

/* ============================================================
   BQ1: OVERALL BUSINESS PERFORMANCE

   How is the retail business performing overall, and how has performance changed over time?
   ============================================================ */

-- Measure core KPIs to establish the overall business-performance baseline.
SELECT
    COUNT(*) AS sales_records,
    SUM(quantity) AS total_units_sold,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(DISTINCT product_id) AS products_sold,
    COUNT(DISTINCT store_id) AS active_stores,
    ROUND(SUM(estimated_sales),2) AS estimated_sales,
    ROUND(SUM(estimated_cogs),2) AS estimated_cogs,
    ROUND(SUM(estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(estimated_gross_profit) /
          NULLIF(SUM(estimated_sales),0) * 100,2) AS estimated_gross_margin_pct
FROM fact_sales;

-- Compare yearly performance to understand changes in sales and profitability.
SELECT
    YEAR(transaction_date) AS year,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(estimated_sales),2) AS estimated_sales,
    ROUND(SUM(estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(estimated_gross_profit) /
          NULLIF(SUM(estimated_sales),0) * 100,2) AS estimated_gross_margin_pct
FROM fact_sales
GROUP BY YEAR(transaction_date)
ORDER BY year;

-- Calculate year-over-year Estimated Sales growth.
WITH yearly_sales AS (
    SELECT YEAR(transaction_date) AS year,
           SUM(estimated_sales) AS estimated_sales
    FROM fact_sales
    GROUP BY YEAR(transaction_date)
),
growth AS (
    SELECT year, estimated_sales,
           LAG(estimated_sales) OVER (ORDER BY year) AS previous_year_sales
    FROM yearly_sales
)
SELECT
    year,
    ROUND(estimated_sales,2) AS estimated_sales,
    ROUND(previous_year_sales,2) AS previous_year_sales,
    ROUND((estimated_sales - previous_year_sales) /
          NULLIF(previous_year_sales,0) * 100,2) AS sales_growth_pct
FROM growth
ORDER BY year;

-- Analyze monthly performance to identify changes and seasonal patterns.
SELECT
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS monthnumber,
    MONTHNAME(transaction_date) AS month_name,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(estimated_sales),2) AS estimated_sales,
    ROUND(SUM(estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales
GROUP BY YEAR(transaction_date),
         MONTH(transaction_date),
         MONTHNAME(transaction_date)
ORDER BY year, monthnumber;


/* ============================================================
   BQ2: CUSTOMER PERFORMANCE & SEGMENTATION

   Which customer groups contribute most to business performance, and how does purchasing performance differ across segments?
   ============================================================ */

-- Establish average customer purchasing performance as a comparison baseline.
WITH customer_performance AS (
    SELECT customer_id,
           SUM(quantity) AS units_purchased,
           SUM(estimated_sales) AS estimated_sales,
           SUM(estimated_gross_profit) AS estimated_gross_profit
    FROM fact_sales
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS active_customers,
    ROUND(AVG(units_purchased),2) AS avg_units_per_customer,
    ROUND(AVG(estimated_sales),2) AS avg_sales_per_customer,
    ROUND(AVG(estimated_gross_profit),2) AS avg_profit_per_customer
FROM customer_performance;

-- Compare purchasing contribution across membership groups.
SELECT
    c.member_card,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(COUNT(DISTINCT f.customer_id),0),2) AS avg_sales_per_customer
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.member_card
ORDER BY estimated_sales DESC;

-- Measure membership groups' share of total Estimated Sales.
WITH segment_sales AS (
    SELECT c.member_card,
           SUM(f.estimated_sales) AS estimated_sales
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.member_card
)
SELECT
    member_card,
    ROUND(estimated_sales,2) AS estimated_sales,
    ROUND(estimated_sales /
          NULLIF(SUM(estimated_sales) OVER (),0) * 100,2) AS sales_share_pct
FROM segment_sales
ORDER BY estimated_sales DESC;

-- Compare purchasing performance across income groups.
SELECT
    c.yearly_income,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(COUNT(DISTINCT f.customer_id),0),2) AS avg_sales_per_customer
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.yearly_income
ORDER BY estimated_sales DESC;

-- Compare purchasing performance across occupations.
SELECT
    c.occupation,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(COUNT(DISTINCT f.customer_id),0),2) AS avg_sales_per_customer
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.occupation
ORDER BY estimated_sales DESC;

-- Identify high-value customers based on total Estimated Sales.
SELECT
    f.customer_id,
    c.member_card,
    c.yearly_income,
    c.occupation,
    c.customer_country,
    SUM(f.quantity) AS units_purchased,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY f.customer_id, c.member_card, c.yearly_income,
         c.occupation, c.customer_country
ORDER BY estimated_sales DESC
LIMIT 20;


/* ============================================================
   BQ3: PRODUCT & BRAND PERFORMANCE

   Which products and brands drive sales and estimated profitability, and which areas are underperforming?
   ============================================================ */

-- Identify top products by Estimated Sales and profitability.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(f.estimated_gross_profit) /
          NULLIF(SUM(f.estimated_sales),0) * 100,2) AS estimated_gross_margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY estimated_sales DESC
LIMIT 20;

-- Identify products with the lowest Estimated Sales contribution.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY estimated_sales ASC
LIMIT 20;

-- Compare brand performance.
SELECT
    p.product_brand,
    COUNT(DISTINCT p.product_id) AS products_sold,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(f.estimated_gross_profit) /
          NULLIF(SUM(f.estimated_sales),0) * 100,2) AS estimated_gross_margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_brand
ORDER BY estimated_sales DESC;

-- Identify products generating the highest Estimated Gross Profit.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY estimated_gross_profit DESC
LIMIT 20;


/* ============================================================
   BQ4: STORE & GEOGRAPHIC PERFORMANCE

   How does business performance vary across stores, store formats and geographic markets?
   ============================================================ */

-- Compare individual store performance.
SELECT
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_city,
    s.store_country,
    s.sales_region,
    SUM(f.quantity) AS units_sold,
    COUNT(DISTINCT f.customer_id) AS active_customers,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_type,
         s.store_city, s.store_country, s.sales_region
ORDER BY estimated_sales DESC;

-- Compare store formats and average sales per store.
SELECT
    s.store_type,
    COUNT(DISTINCT s.store_id) AS store_count,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(COUNT(DISTINCT s.store_id),0),2) AS avg_sales_per_store,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.store_type
ORDER BY estimated_sales DESC;

-- Compare geographic performance by country.
SELECT
    s.store_country,
    COUNT(DISTINCT s.store_id) AS store_count,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.store_country
ORDER BY estimated_sales DESC;

-- Compare geographic performance by sales region.
SELECT
    s.sales_region,
    COUNT(DISTINCT s.store_id) AS store_count,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(COUNT(DISTINCT s.store_id),0),2) AS avg_sales_per_store,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.sales_region
ORDER BY estimated_sales DESC;

-- Measure store sales efficiency relative to total store size.
SELECT
    s.store_id,
    s.store_name,
    s.store_type,
    s.total_sqft,
    s.grocery_sqft,
    ROUND(SUM(f.estimated_sales),2) AS estimated_sales,
    ROUND(SUM(f.estimated_gross_profit),2) AS estimated_gross_profit,
    ROUND(SUM(f.estimated_sales) /
          NULLIF(s.total_sqft,0),2) AS estimated_sales_per_sqft
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_type,
         s.total_sqft, s.grocery_sqft
ORDER BY estimated_sales_per_sqft DESC;


/* ============================================================
   BQ5: RETURN ANALYSIS

   Where are product returns concentrated, and which products, stores, locations, and time periods contribute most to return activity?

   Limitation:
   No customer-level return analysis or transaction-level sales-to-return matching is performed because those keys are unavailable.
   ============================================================ */

-- Measure overall return activity.
SELECT
    COUNT(*) AS return_records,
    SUM(returned_quantity) AS returned_units,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT store_id) AS stores_with_returns
FROM fact_returns;

-- Analyze monthly return activity.
SELECT
    YEAR(return_date) AS year,
    MONTH(return_date) AS month_number,
    MONTHNAME(return_date) AS month_name,
    COUNT(*) AS return_records,
    SUM(returned_quantity) AS returned_units
FROM fact_returns
GROUP BY YEAR(return_date), MONTH(return_date), MONTHNAME(return_date)
ORDER BY year, month_number;

-- Identify products with the highest returned-unit volume.
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns r
JOIN dim_product p ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY returned_units DESC
LIMIT 20;

-- Compare return activity across stores.
SELECT
    s.store_id,
    s.store_name,
    s.store_type,
    s.store_country,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns r
JOIN dim_store s ON r.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_type, s.store_country
ORDER BY returned_units DESC;

-- Compare return activity across countries.
SELECT
    s.store_country,
    COUNT(DISTINCT r.store_id) AS stores_with_returns,
    SUM(r.returned_quantity) AS returned_units
FROM fact_returns r
JOIN dim_store s ON r.store_id = s.store_id
GROUP BY s.store_country
ORDER BY returned_units DESC;

-- Calculate the overall aggregate return-rate indicator.
WITH sales_total AS (
    SELECT SUM(quantity) AS units_sold FROM fact_sales
),
returns_total AS (
    SELECT SUM(returned_quantity) AS returned_units FROM fact_returns
)
SELECT
    s.units_sold,
    r.returned_units,
    ROUND(r.returned_units /
          NULLIF(s.units_sold,0) * 100,2) AS aggregate_return_rate_pct
FROM sales_total s
CROSS JOIN returns_total r;

-- Compare product-level sales and returns at a compatible grain.
WITH product_sales AS (
    SELECT product_id,
           SUM(quantity) AS units_sold,
           SUM(estimated_sales) AS estimated_sales
    FROM fact_sales
    GROUP BY product_id
),
product_returns AS (
    SELECT product_id,
           SUM(returned_quantity) AS returned_units
    FROM fact_returns
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    s.units_sold,
    COALESCE(r.returned_units,0) AS returned_units,
    ROUND(COALESCE(r.returned_units,0) /
          NULLIF(s.units_sold,0) * 100,2) AS return_rate_pct,
    ROUND(s.estimated_sales,2) AS estimated_sales
FROM product_sales s
JOIN dim_product p ON s.product_id = p.product_id
LEFT JOIN product_returns r ON s.product_id = r.product_id
ORDER BY return_rate_pct DESC;

-- Compare store-level sales and returns at a compatible grain.
WITH store_sales AS (
    SELECT store_id,
           SUM(quantity) AS units_sold,
           SUM(estimated_sales) AS estimated_sales
    FROM fact_sales
    GROUP BY store_id
),
store_returns AS (
    SELECT store_id,
           SUM(returned_quantity) AS returned_units
    FROM fact_returns
    GROUP BY store_id
)
SELECT
    st.store_id,
    st.store_name,
    st.store_type,
    st.store_country,
    s.units_sold,
    COALESCE(r.returned_units,0) AS returned_units,
    ROUND(COALESCE(r.returned_units,0) /
          NULLIF(s.units_sold,0) * 100,2) AS return_rate_pct,
    ROUND(s.estimated_sales,2) AS estimated_sales
FROM store_sales s
JOIN dim_store st ON s.store_id = st.store_id
LEFT JOIN store_returns r ON s.store_id = r.store_id
ORDER BY return_rate_pct DESC;


/* ============================================================
   FINAL BUSINESS ANALYSIS SUMMARY

   BQ1: Overall performance and time trends
   BQ2: Customer contribution and segment differences
   BQ3: Product and brand performance
   BQ4: Store and geographic performance
   BQ5: Return concentration and aggregate return-rate indicators

   Next:
   Use these outputs to build the Power BI KPI framework, dashboard pages, insights, business implications, and recommendations.
   ============================================================ */
