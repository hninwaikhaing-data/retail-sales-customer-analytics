/*   
-- Database Setup & Data Import Workflow
-- 1. Create the project database
-- 2. Create raw tables that match the source data structure
-- 3. Load source CSV files into the corresponding raw tables
-- 4. Convert and standardize date values during data loading
-- 5. Validate the data import using row counts and sample records                            
*/

-- 1. Create the project database
DROP DATABASE IF EXISTS retail_db;
CREATE DATABASE retail_db;
USE retail_db;
SHOW TABLES;
/* Database created.*/

-- 2. Create raw tables that match the source data structure
CREATE TABLE raw_sales_1997 (
    transaction_date VARCHAR(20),
    stock_date VARCHAR(20),
    product_id INT,
    customer_id INT,
    store_id INT,
    quantity INT
);

CREATE TABLE raw_sales_1998 (
    transaction_date VARCHAR(20),
    stock_date VARCHAR(20),
    product_id INT,
    customer_id INT,
    store_id INT,
    quantity INT
);

CREATE TABLE raw_customers (
    customer_id INT,
    customer_acct_num BIGINT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    customer_address VARCHAR(255),
    customer_city VARCHAR(100),
    customer_state_province VARCHAR(100),
    customer_postal_code VARCHAR(30),
    customer_country VARCHAR(100),
    birthdate DATE,
    marital_status VARCHAR(20),
    yearly_income VARCHAR(50),
    gender VARCHAR(20),
    total_children INT,
    num_children_at_home INT,
    education VARCHAR(100),
    acct_open_date DATE,
    member_card VARCHAR(50),
    occupation VARCHAR(100),
    homeowner VARCHAR(20)
);

CREATE TABLE raw_products (
    product_id INT,
    product_brand VARCHAR(100),
    product_name VARCHAR(255),
    product_sku BIGINT,
    product_retail_price DECIMAL(10,2),
    product_cost DECIMAL(10,2),
    product_weight DECIMAL(10,2),
    recyclable TINYINT NULL,
    low_fat TINYINT NULL
);
CREATE TABLE raw_stores (
    store_id INT,
    region_id INT,
    store_type VARCHAR(100),
    store_name VARCHAR(150),
    store_street_address VARCHAR(255),
    store_city VARCHAR(100),
    store_state VARCHAR(100),
    store_country VARCHAR(100),
    store_phone VARCHAR(50),
    first_opened_date DATE,
    last_remodel_date DATE,
    total_sqft INT,
    grocery_sqft INT
);

CREATE TABLE raw_regions (
    region_id INT,
    sales_district VARCHAR(100),
    sales_region VARCHAR(100)
);

CREATE TABLE raw_returns (
    return_date DATE,
    product_id INT,
    store_id INT,
    quantity INT
);

CREATE TABLE raw_calendar (`date` DATE);
/* created tables */

-- 3. Load source CSV files into the corresponding raw tables
-- 4. Convert and standardize date values during data loading
USE retail_db;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- Import the 1998 retail transaction data from the source CSV file into the raw_sales_1998 and 1997 tables for further processing and analysis.
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market Transactions/Market_Transactions_1998.csv'
INTO TABLE raw_sales_1998
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @transaction_date,
    @stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
)
SET
    transaction_date = STR_TO_DATE(TRIM(@transaction_date), '%m/%d/%Y'),
    stock_date = STR_TO_DATE(TRIM(@stock_date), '%m/%d/%Y');
    
select * from raw_sales_1998;

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market Transactions/Market_Transactions_1997.csv'
INTO TABLE raw_sales_1997
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @transaction_date,
    @stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
)
SET
    transaction_date = STR_TO_DATE(TRIM(@transaction_date), '%m/%d/%Y'),
    stock_date = STR_TO_DATE(TRIM(@stock_date), '%m/%d/%Y');

SELECT *
FROM raw_sales_1997
LIMIT 10;

-- Import calendar data and convert the source date values into MySQL DATE format.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Calendar.csv'
INTO TABLE raw_calendar
CHARACTER SET utf8mb4
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@date)
SET `date` = STR_TO_DATE(TRIM(@date), '%m/%d/%Y');

select * from raw_calendar;

-- Import customer data and convert source date values into MySQL DATE format.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Customers.csv'
INTO TABLE raw_customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    customer_id,
    customer_acct_num,
    first_name,
    last_name,
    customer_address,
    customer_city,
    customer_state_province,
    customer_postal_code,
    customer_country,
    @birthdate,
    marital_status,
    yearly_income,
    gender,
    total_children,
    num_children_at_home,
    education,
    @acct_open_date,
    member_card,
    occupation,
    homeowner
)
SET
    birthdate = STR_TO_DATE(TRIM(@birthdate), '%m/%d/%Y'),
    acct_open_date = STR_TO_DATE(TRIM(@acct_open_date), '%m/%d/%Y');
    
-- Import product master data from the source CSV file into the raw products table.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Products.csv'
INTO TABLE raw_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_id,
    product_brand,
    product_name,
    product_sku,
    product_retail_price,
    product_cost,
    product_weight,
    recyclable,
    low_fat
);

-- Import store data and convert source date values into MySQL DATE format.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Stores.csv'
INTO TABLE raw_stores
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    store_id,
    region_id,
    store_type,
    store_name,
    store_street_address,
    store_city,
    store_state,
    store_country,
    store_phone,
    @first_opened_date,
    @last_remodel_date,
    total_sqft,
    grocery_sqft
)
SET
    first_opened_date = STR_TO_DATE(TRIM(@first_opened_date), '%m/%d/%Y'),
    last_remodel_date = STR_TO_DATE(TRIM(@last_remodel_date), '%m/%d/%Y');
    
TRUNCATE TABLE raw_stores;
-- Import store data and convert source date values into MySQL DATE format.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Stores.csv'
INTO TABLE raw_stores
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    store_id,
    region_id,
    store_type,
    store_name,
    store_street_address,
    store_city,
    store_state,
    store_country,
    store_phone,
    @first_opened_date,
    @last_remodel_date,
    total_sqft,
    grocery_sqft
)
SET
    first_opened_date = STR_TO_DATE(TRIM(@first_opened_date), '%m/%d/%Y'),
    last_remodel_date = STR_TO_DATE(TRIM(@last_remodel_date), '%m/%d/%Y');
    
select * from raw_stores;
-- Import regional reference data from the source CSV file into the raw regions table.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Regions.csv'
INTO TABLE raw_regions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    region_id,
    sales_district,
    sales_region
);

-- Import product return data and convert the source return date into MySQL DATE format.
LOAD DATA LOCAL INFILE
'C:/Users/User/Desktop/Application_2026/Project_Series/Retail_business_Insight/data/Market_Returns_1997-1998.csv'
INTO TABLE raw_returns
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @return_date,
    product_id,
    store_id,
    quantity
)
SET
    return_date = STR_TO_DATE(TRIM(@return_date), '%m/%d/%Y');
    
-- 5. Validate the data import using row counts and records          
                  
-- Validate the data import by checking the total row count of each raw table.
SELECT 'raw_sales_1997' table_name, COUNT(*) row_count FROM raw_sales_1997
UNION ALL SELECT 'raw_sales_1998', COUNT(*) FROM raw_sales_1998
UNION ALL SELECT 'raw_customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'raw_products', COUNT(*) FROM raw_products
UNION ALL SELECT 'raw_stores', COUNT(*) FROM raw_stores
UNION ALL SELECT 'raw_regions', COUNT(*) FROM raw_regions
UNION ALL SELECT 'raw_returns', COUNT(*) FROM raw_returns
UNION ALL SELECT 'raw_calendar', COUNT(*) FROM raw_calendar;

-- Expected source row counts for this project:
-- sales_1997=86837, sales_1998=182883, customers=10281,
-- products=1560, stores=48, regions=109, returns=7087, calendar=730.

SELECT * FROM raw_sales_1997;
SELECT * FROM raw_sales_1998 LIMIT 10;
SELECT * FROM raw_calendar LIMIT 10;
SELECT * FROM raw_returns LIMIT 10;
SELECT * FROM raw_regions LIMIT 10;
SELECT * FROM raw_stores LIMIT 10;
SELECT * FROM raw_customers LIMIT 10;
SELECT * FROM raw_products LIMIT 10;

