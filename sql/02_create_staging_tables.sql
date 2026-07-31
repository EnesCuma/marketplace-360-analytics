USE Marketplace360;
GO

/* =========================================================
   MARKETPLACE 360 ANALYTICS
   Staging schemas and raw data tables

   Raw CSV values are initially stored as text.
   Data type conversion and cleaning will be performed
   in the transformation layer.
   ========================================================= */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO


/* Existing staging tables are removed so that
   this script can be executed more than once. */

DROP TABLE IF EXISTS stg.order_reviews;
DROP TABLE IF EXISTS stg.order_payments;
DROP TABLE IF EXISTS stg.order_items;
DROP TABLE IF EXISTS stg.orders;
DROP TABLE IF EXISTS stg.products;
DROP TABLE IF EXISTS stg.customers;
DROP TABLE IF EXISTS stg.sellers;
DROP TABLE IF EXISTS stg.geolocation;
DROP TABLE IF EXISTS stg.product_category_translation;
GO


/* =========================================================
   CUSTOMERS
   ========================================================= */

CREATE TABLE stg.customers
(
    customer_id              NVARCHAR(64)  NULL,
    customer_unique_id       NVARCHAR(64)  NULL,
    customer_zip_code_prefix NVARCHAR(20)  NULL,
    customer_city            NVARCHAR(255) NULL,
    customer_state           NVARCHAR(10)  NULL
);
GO


/* =========================================================
   GEOLOCATION
   ========================================================= */

CREATE TABLE stg.geolocation
(
    geolocation_zip_code_prefix NVARCHAR(20)  NULL,
    geolocation_lat             NVARCHAR(50)  NULL,
    geolocation_lng             NVARCHAR(50)  NULL,
    geolocation_city            NVARCHAR(255) NULL,
    geolocation_state           NVARCHAR(10)  NULL
);
GO


/* =========================================================
   ORDERS
   ========================================================= */

CREATE TABLE stg.orders
(
    order_id                       NVARCHAR(64) NULL,
    customer_id                    NVARCHAR(64) NULL,
    order_status                   NVARCHAR(50) NULL,
    order_purchase_timestamp       NVARCHAR(50) NULL,
    order_approved_at              NVARCHAR(50) NULL,
    order_delivered_carrier_date   NVARCHAR(50) NULL,
    order_delivered_customer_date  NVARCHAR(50) NULL,
    order_estimated_delivery_date  NVARCHAR(50) NULL
);
GO


/* =========================================================
   ORDER ITEMS
   ========================================================= */

CREATE TABLE stg.order_items
(
    order_id            NVARCHAR(64) NULL,
    order_item_id       NVARCHAR(20) NULL,
    product_id          NVARCHAR(64) NULL,
    seller_id           NVARCHAR(64) NULL,
    shipping_limit_date NVARCHAR(50) NULL,
    price               NVARCHAR(50) NULL,
    freight_value       NVARCHAR(50) NULL
);
GO


/* =========================================================
   ORDER PAYMENTS
   ========================================================= */

CREATE TABLE stg.order_payments
(
    order_id             NVARCHAR(64) NULL,
    payment_sequential   NVARCHAR(20) NULL,
    payment_type         NVARCHAR(50) NULL,
    payment_installments NVARCHAR(20) NULL,
    payment_value        NVARCHAR(50) NULL
);
GO


/* =========================================================
   ORDER REVIEWS
   ========================================================= */

CREATE TABLE stg.order_reviews
(
    review_id               NVARCHAR(64)  NULL,
    order_id                NVARCHAR(64)  NULL,
    review_score            NVARCHAR(20)  NULL,
    review_comment_title    NVARCHAR(1000) NULL,
    review_comment_message  NVARCHAR(MAX) NULL,
    review_creation_date    NVARCHAR(50)  NULL,
    review_answer_timestamp NVARCHAR(50)  NULL
);
GO


/* =========================================================
   PRODUCTS

   The original Olist column names contain the word
   "lenght" instead of "length". The source names are
   preserved in the staging layer.
   ========================================================= */

CREATE TABLE stg.products
(
    product_id                 NVARCHAR(64)  NULL,
    product_category_name      NVARCHAR(255) NULL,
    product_name_lenght        NVARCHAR(20)  NULL,
    product_description_lenght NVARCHAR(20)  NULL,
    product_photos_qty         NVARCHAR(20)  NULL,
    product_weight_g           NVARCHAR(50)  NULL,
    product_length_cm          NVARCHAR(50)  NULL,
    product_height_cm          NVARCHAR(50)  NULL,
    product_width_cm           NVARCHAR(50)  NULL
);
GO


/* =========================================================
   SELLERS
   ========================================================= */

CREATE TABLE stg.sellers
(
    seller_id              NVARCHAR(64)  NULL,
    seller_zip_code_prefix NVARCHAR(20)  NULL,
    seller_city            NVARCHAR(255) NULL,
    seller_state           NVARCHAR(10)  NULL
);
GO


/* =========================================================
   PRODUCT CATEGORY TRANSLATION
   ========================================================= */

CREATE TABLE stg.product_category_translation
(
    product_category_name         NVARCHAR(255) NULL,
    product_category_name_english NVARCHAR(255) NULL
);
GO


/* =========================================================
   CONTROL QUERY
   ========================================================= */

SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name IN ('stg', 'analytics')
ORDER BY
    s.name,
    t.name;
GO