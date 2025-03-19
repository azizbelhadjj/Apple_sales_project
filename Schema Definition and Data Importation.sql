--- Apple Sales SQL project ----- 

--- DROPPING EXISTING TABLES -----
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS category; -- parent
DROP TABLE IF EXISTS warranty;
DROP TABLE IF EXISTS stores; -- parent

--- CREATE TABLE COMMANDS ---- 
DROP TABLE IF EXISTS stores;
CREATE TABLE stores(
store_id VARCHAR (5) PRIMARY KEY,
store_name VARCHAR (30),
city VARCHAR (30),
country VARCHAR (30)
);
DROP TABLE IF EXISTS category;
CREATE TABLE category(
category_id VARCHAR (10) PRIMARY KEY, 
category_name VARCHAR (30)
);
DROP TABLE IF EXISTS products; 
CREATE TABLE products (
product_id VARCHAR (10) PRIMARY KEY,
product_name VARCHAR (35),
category_id VARCHAR (10), 
launch_date DATE,
price FLOAT, 
CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES category (category_id)
);
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
sale_id VARCHAR (10) PRIMARY KEY,
sale_date DATE, 
store_id VARCHAR (10),
product_id VARCHAR (10),
quantity INT,
CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES stores (store_id),
CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);
DROP TABLE IF EXISTS warranty; 
CREATE TABLE warranty (
claim_id VARCHAR (10) PRIMARY KEY,
claim_date DATE, 
sale_id VARCHAR (10),
repair_status VARCHAR (20),
CONSTRAINT fk_sale FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);

