USE Marketplace360;
GO

SET NOCOUNT ON;
GO

IF SCHEMA_ID('analytics') IS NULL
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO

-- Script tekrar çalıştırılabilsin diye mevcut analiz tablolarını kaldırır.
DROP TABLE IF EXISTS analytics.fact_order_items;
DROP TABLE IF EXISTS analytics.fact_orders;
DROP TABLE IF EXISTS analytics.dim_date;
DROP TABLE IF EXISTS analytics.dim_sellers;
DROP TABLE IF EXISTS analytics.dim_products;
DROP TABLE IF EXISTS analytics.dim_customers;
GO


-- Customer dimension
CREATE TABLE analytics.dim_customers
(
    customer_unique_id       CHAR(32)      NOT NULL,
    customer_zip_code_prefix CHAR(5)       NULL,
    customer_city            NVARCHAR(120) NULL,
    customer_state           CHAR(2)       NULL,
    first_order_date         DATE          NULL,
    last_order_date          DATE          NULL,
    order_count              INT           NOT NULL,

    CONSTRAINT PK_dim_customers
        PRIMARY KEY (customer_unique_id)
);
GO


-- Product dimension
CREATE TABLE analytics.dim_products
(
    product_id                 CHAR(32)       NOT NULL,
    category_name_original     NVARCHAR(255)  NULL,
    category_name_english      NVARCHAR(255)  NOT NULL,
    product_name_length        INT            NULL,
    product_description_length INT            NULL,
    product_photos_qty         INT            NULL,
    product_weight_g           DECIMAL(18, 2) NULL,
    product_length_cm          DECIMAL(18, 2) NULL,
    product_height_cm          DECIMAL(18, 2) NULL,
    product_width_cm           DECIMAL(18, 2) NULL,
    product_volume_cm3         DECIMAL(18, 2) NULL,

    CONSTRAINT PK_dim_products
        PRIMARY KEY (product_id)
);
GO


-- Seller dimension
CREATE TABLE analytics.dim_sellers
(
    seller_id              CHAR(32)      NOT NULL,
    seller_zip_code_prefix CHAR(5)       NULL,
    seller_city            NVARCHAR(120) NULL,
    seller_state           CHAR(2)       NULL,

    CONSTRAINT PK_dim_sellers
        PRIMARY KEY (seller_id)
);
GO


-- Date dimension
CREATE TABLE analytics.dim_date
(
    date_key           INT          NOT NULL,
    full_date          DATE         NOT NULL,
    calendar_year      SMALLINT     NOT NULL,
    calendar_quarter   TINYINT      NOT NULL,
    month_number       TINYINT      NOT NULL,
    month_name         VARCHAR(10)  NOT NULL,
    year_month         CHAR(7)      NOT NULL,
    iso_week_number    TINYINT      NOT NULL,
    day_of_month       TINYINT      NOT NULL,
    day_of_week_number TINYINT      NOT NULL,
    day_name           VARCHAR(10)  NOT NULL,
    is_weekend         BIT          NOT NULL,

    CONSTRAINT PK_dim_date
        PRIMARY KEY (date_key),

    CONSTRAINT UQ_dim_date_full_date
        UNIQUE (full_date)
);
GO


-- One row per order
CREATE TABLE analytics.fact_orders
(
    order_id                      CHAR(32)       NOT NULL,
    customer_unique_id            CHAR(32)       NOT NULL,
    purchase_date_key             INT            NOT NULL,
    order_status                  VARCHAR(20)     NOT NULL,

    order_purchase_timestamp      DATETIME2(0)   NOT NULL,
    order_approved_at             DATETIME2(0)   NULL,
    order_delivered_carrier_date  DATETIME2(0)   NULL,
    order_delivered_customer_date DATETIME2(0)   NULL,
    estimated_delivery_date       DATETIME2(0)   NULL,

    item_count                    INT            NOT NULL,
    distinct_product_count        INT            NOT NULL,
    distinct_seller_count         INT            NOT NULL,

    item_value                    DECIMAL(18, 2) NOT NULL,
    freight_value                 DECIMAL(18, 2) NOT NULL,
    gross_order_value             DECIMAL(18, 2) NOT NULL,

    payment_value                 DECIMAL(18, 2) NOT NULL,
    payment_count                 INT            NOT NULL,
    payment_method_count          INT            NOT NULL,
    maximum_installments          INT            NULL,
    primary_payment_type          VARCHAR(30)     NULL,

    review_id                     CHAR(32)        NULL,
    review_score                  TINYINT         NULL,
    review_count                  INT             NOT NULL,
    has_conflicting_reviews       BIT             NOT NULL,

    approval_hours                DECIMAL(10, 2) NULL,
    delivery_days                 DECIMAL(10, 2) NULL,
    carrier_to_customer_days      DECIMAL(10, 2) NULL,
    estimated_delivery_days       DECIMAL(10, 2) NULL,
    delivery_delay_days           DECIMAL(10, 2) NULL,

    is_delivered                  BIT NOT NULL,
    is_canceled                   BIT NOT NULL,
    is_late_delivery              BIT NULL,
    is_delivery_sequence_valid    BIT NULL,
    has_non_positive_payment      BIT NOT NULL,

    CONSTRAINT PK_fact_orders
        PRIMARY KEY (order_id)
);
GO


-- One row per product line in an order
CREATE TABLE analytics.fact_order_items
(
    order_id               CHAR(32)       NOT NULL,
    order_item_id          INT            NOT NULL,
    customer_unique_id     CHAR(32)       NOT NULL,
    product_id             CHAR(32)       NOT NULL,
    seller_id              CHAR(32)       NOT NULL,
    purchase_date_key      INT            NOT NULL,
    shipping_limit_date    DATETIME2(0)   NULL,
    item_price             DECIMAL(18, 2) NOT NULL,
    freight_value          DECIMAL(18, 2) NOT NULL,
    total_line_value       DECIMAL(18, 2) NOT NULL,

    CONSTRAINT PK_fact_order_items
        PRIMARY KEY (order_id, order_item_id)
);
GO


-- Customer dimension data
WITH customer_history AS
(
    SELECT
        c.customer_unique_id,
        c.customer_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        TRY_CONVERT(DATE, o.order_purchase_timestamp) AS order_date,

        ROW_NUMBER() OVER
        (
            PARTITION BY c.customer_unique_id
            ORDER BY
                TRY_CONVERT(DATETIME2(0), o.order_purchase_timestamp) DESC,
                c.customer_id DESC
        ) AS row_number,

        MIN(TRY_CONVERT(DATE, o.order_purchase_timestamp))
            OVER (PARTITION BY c.customer_unique_id) AS first_order_date,

        MAX(TRY_CONVERT(DATE, o.order_purchase_timestamp))
            OVER (PARTITION BY c.customer_unique_id) AS last_order_date,

        COUNT(*)
            OVER (PARTITION BY c.customer_unique_id) AS order_count
    FROM stg.customers AS c
    LEFT JOIN stg.orders AS o
        ON c.customer_id = o.customer_id
)
INSERT INTO analytics.dim_customers
(
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    first_order_date,
    last_order_date,
    order_count
)
SELECT
    CAST(customer_unique_id AS CHAR(32)),
    CAST(customer_zip_code_prefix AS CHAR(5)),
    customer_city,
    CAST(customer_state AS CHAR(2)),
    first_order_date,
    last_order_date,
    order_count
FROM customer_history
WHERE row_number = 1;
GO


-- Product dimension data
INSERT INTO analytics.dim_products
(
    product_id,
    category_name_original,
    category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
)
SELECT
    CAST(p.product_id AS CHAR(32)),
    p.product_category_name,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'unknown'
        WHEN t.product_category_name_english IS NOT NULL
            THEN t.product_category_name_english
        WHEN p.product_category_name = 'pc_gamer'
            THEN 'pc_gamer'
        WHEN p.product_category_name =
             'portateis_cozinha_e_preparadores_de_alimentos'
            THEN 'kitchen_portables_and_food_preparers'
        ELSE p.product_category_name
    END,

    TRY_CONVERT(INT, p.product_name_lenght),
    TRY_CONVERT(INT, p.product_description_lenght),
    TRY_CONVERT(INT, p.product_photos_qty),
    TRY_CONVERT(DECIMAL(18, 2), p.product_weight_g),
    TRY_CONVERT(DECIMAL(18, 2), p.product_length_cm),
    TRY_CONVERT(DECIMAL(18, 2), p.product_height_cm),
    TRY_CONVERT(DECIMAL(18, 2), p.product_width_cm),

    TRY_CONVERT(DECIMAL(18, 2), p.product_length_cm)
        * TRY_CONVERT(DECIMAL(18, 2), p.product_height_cm)
        * TRY_CONVERT(DECIMAL(18, 2), p.product_width_cm)
FROM stg.products AS p
LEFT JOIN stg.product_category_translation AS t
    ON p.product_category_name = t.product_category_name;
GO


-- Seller dimension data
INSERT INTO analytics.dim_sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    CAST(seller_id AS CHAR(32)),
    CAST(seller_zip_code_prefix AS CHAR(5)),
    seller_city,
    CAST(seller_state AS CHAR(2))
FROM stg.sellers;
GO


-- Date dimension data
DECLARE @start_date DATE =
(
    SELECT MIN(TRY_CONVERT(DATE, order_purchase_timestamp))
    FROM stg.orders
);

DECLARE @end_date DATE =
(
    SELECT MAX(date_value)
    FROM
    (
        SELECT TRY_CONVERT(DATE, order_purchase_timestamp)
        FROM stg.orders

        UNION ALL

        SELECT TRY_CONVERT(DATE, order_delivered_customer_date)
        FROM stg.orders

        UNION ALL

        SELECT TRY_CONVERT(DATE, order_estimated_delivery_date)
        FROM stg.orders
    ) AS dates(date_value)
);

WITH date_list AS
(
    SELECT @start_date AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM date_list
    WHERE full_date < @end_date
)
INSERT INTO analytics.dim_date
(
    date_key,
    full_date,
    calendar_year,
    calendar_quarter,
    month_number,
    month_name,
    year_month,
    iso_week_number,
    day_of_month,
    day_of_week_number,
    day_name,
    is_weekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), full_date, 112)),
    full_date,
    DATEPART(YEAR, full_date),
    DATEPART(QUARTER, full_date),
    DATEPART(MONTH, full_date),

    CASE DATEPART(MONTH, full_date)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END,

    LEFT(CONVERT(CHAR(10), full_date, 23), 7),
    DATEPART(ISO_WEEK, full_date),
    DATEPART(DAY, full_date),

    (DATEDIFF(DAY, '19000101', full_date) % 7) + 1,

    CASE (DATEDIFF(DAY, '19000101', full_date) % 7) + 1
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END,

    CASE
        WHEN (DATEDIFF(DAY, '19000101', full_date) % 7) + 1
             IN (6, 7)
            THEN 1
        ELSE 0
    END
FROM date_list
OPTION (MAXRECURSION 0);
GO


-- Order level summaries
WITH item_summary AS
(
    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT product_id) AS distinct_product_count,
        COUNT(DISTINCT seller_id) AS distinct_seller_count,
        SUM(TRY_CONVERT(DECIMAL(18, 2), price)) AS item_value,
        SUM(TRY_CONVERT(DECIMAL(18, 2), freight_value))
            AS freight_value
    FROM stg.order_items
    GROUP BY order_id
),
payment_prepared AS
(
    SELECT
        order_id,
        TRY_CONVERT(INT, payment_sequential) AS payment_sequential,
        payment_type,
        TRY_CONVERT(INT, payment_installments) AS payment_installments,
        TRY_CONVERT(DECIMAL(18, 2), payment_value) AS payment_value
    FROM stg.order_payments
),
payment_ranked AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY order_id
            ORDER BY
                payment_value DESC,
                payment_sequential ASC
        ) AS payment_rank
    FROM payment_prepared
),
payment_summary AS
(
    SELECT
        order_id,
        SUM(payment_value) AS payment_value,
        COUNT(*) AS payment_count,
        COUNT(DISTINCT payment_type) AS payment_method_count,
        MAX(payment_installments) AS maximum_installments,

        MAX(
            CASE
                WHEN payment_rank = 1 THEN payment_type
            END
        ) AS primary_payment_type,

        MAX(
            CASE
                WHEN payment_value <= 0 THEN 1
                ELSE 0
            END
        ) AS has_non_positive_payment
    FROM payment_ranked
    GROUP BY order_id
),
review_prepared AS
(
    SELECT
        review_id,
        order_id,
        TRY_CONVERT(TINYINT, review_score) AS review_score,
        TRY_CONVERT(DATETIME2(0), review_creation_date)
            AS review_creation_date,
        TRY_CONVERT(DATETIME2(0), review_answer_timestamp)
            AS review_answer_timestamp
    FROM stg.order_reviews
),
review_summary AS
(
    SELECT
        order_id,
        COUNT(*) AS review_count,
        MIN(review_score) AS minimum_review_score,
        MAX(review_score) AS maximum_review_score
    FROM review_prepared
    GROUP BY order_id
),
review_ranked AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_creation_date DESC,
                review_id DESC
        ) AS review_rank
    FROM review_prepared
),
orders_prepared AS
(
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        TRY_CONVERT(DATETIME2(0), o.order_purchase_timestamp)
            AS purchase_timestamp,
        TRY_CONVERT(DATETIME2(0), o.order_approved_at)
            AS approved_at,
        TRY_CONVERT(DATETIME2(0), o.order_delivered_carrier_date)
            AS delivered_carrier_date,
        TRY_CONVERT(DATETIME2(0), o.order_delivered_customer_date)
            AS delivered_customer_date,
        TRY_CONVERT(DATETIME2(0), o.order_estimated_delivery_date)
            AS estimated_delivery_date
    FROM stg.orders AS o
)
INSERT INTO analytics.fact_orders
(
    order_id,
    customer_unique_id,
    purchase_date_key,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    estimated_delivery_date,
    item_count,
    distinct_product_count,
    distinct_seller_count,
    item_value,
    freight_value,
    gross_order_value,
    payment_value,
    payment_count,
    payment_method_count,
    maximum_installments,
    primary_payment_type,
    review_id,
    review_score,
    review_count,
    has_conflicting_reviews,
    approval_hours,
    delivery_days,
    carrier_to_customer_days,
    estimated_delivery_days,
    delivery_delay_days,
    is_delivered,
    is_canceled,
    is_late_delivery,
    is_delivery_sequence_valid,
    has_non_positive_payment
)
SELECT
    CAST(o.order_id AS CHAR(32)),
    CAST(c.customer_unique_id AS CHAR(32)),

    CONVERT(
        INT,
        CONVERT(CHAR(8), CAST(o.purchase_timestamp AS DATE), 112)
    ),

    o.order_status,
    o.purchase_timestamp,
    o.approved_at,
    o.delivered_carrier_date,
    o.delivered_customer_date,
    o.estimated_delivery_date,

    COALESCE(i.item_count, 0),
    COALESCE(i.distinct_product_count, 0),
    COALESCE(i.distinct_seller_count, 0),

    COALESCE(i.item_value, 0),
    COALESCE(i.freight_value, 0),
    COALESCE(i.item_value, 0) + COALESCE(i.freight_value, 0),

    COALESCE(p.payment_value, 0),
    COALESCE(p.payment_count, 0),
    COALESCE(p.payment_method_count, 0),
    p.maximum_installments,
    p.primary_payment_type,

    CAST(r.review_id AS CHAR(32)),
    r.review_score,
    COALESCE(rs.review_count, 0),

    CAST(
        CASE
            WHEN rs.minimum_review_score <> rs.maximum_review_score
                THEN 1
            ELSE 0
        END
        AS BIT
    ),

    CASE
        WHEN o.approved_at >= o.purchase_timestamp
        THEN DATEDIFF(MINUTE, o.purchase_timestamp, o.approved_at)
             / 60.0
    END,

    CASE
        WHEN o.delivered_customer_date >= o.purchase_timestamp
        THEN DATEDIFF(
                 MINUTE,
                 o.purchase_timestamp,
                 o.delivered_customer_date
             ) / 1440.0
    END,

    CASE
        WHEN o.delivered_customer_date >= o.delivered_carrier_date
        THEN DATEDIFF(
                 MINUTE,
                 o.delivered_carrier_date,
                 o.delivered_customer_date
             ) / 1440.0
    END,

    CASE
        WHEN o.estimated_delivery_date >= o.purchase_timestamp
        THEN DATEDIFF(
                 MINUTE,
                 o.purchase_timestamp,
                 o.estimated_delivery_date
             ) / 1440.0
    END,

    CASE
        WHEN o.delivered_customer_date IS NOT NULL
         AND o.estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(
                 MINUTE,
                 o.estimated_delivery_date,
                 o.delivered_customer_date
             ) / 1440.0
    END,

    CAST(
        CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END
        AS BIT
    ),

    CAST(
        CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END
        AS BIT
    ),

    CAST(
        CASE
            WHEN o.delivered_customer_date IS NULL
              OR o.estimated_delivery_date IS NULL
                THEN NULL
            WHEN o.delivered_customer_date > o.estimated_delivery_date
                THEN 1
            ELSE 0
        END
        AS BIT
    ),

    CAST(
        CASE
            WHEN o.delivered_customer_date IS NULL
              OR o.delivered_carrier_date IS NULL
                THEN NULL
            WHEN o.delivered_customer_date >= o.delivered_carrier_date
                THEN 1
            ELSE 0
        END
        AS BIT
    ),

    CAST(COALESCE(p.has_non_positive_payment, 0) AS BIT)
FROM orders_prepared AS o
INNER JOIN stg.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN payment_summary AS p
    ON o.order_id = p.order_id
LEFT JOIN review_summary AS rs
    ON o.order_id = rs.order_id
LEFT JOIN review_ranked AS r
    ON o.order_id = r.order_id
   AND r.review_rank = 1;
GO


-- Order item fact data
INSERT INTO analytics.fact_order_items
(
    order_id,
    order_item_id,
    customer_unique_id,
    product_id,
    seller_id,
    purchase_date_key,
    shipping_limit_date,
    item_price,
    freight_value,
    total_line_value
)
SELECT
    CAST(oi.order_id AS CHAR(32)),
    TRY_CONVERT(INT, oi.order_item_id),
    CAST(c.customer_unique_id AS CHAR(32)),
    CAST(oi.product_id AS CHAR(32)),
    CAST(oi.seller_id AS CHAR(32)),

    CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            TRY_CONVERT(DATE, o.order_purchase_timestamp),
            112
        )
    ),

    TRY_CONVERT(DATETIME2(0), oi.shipping_limit_date),
    TRY_CONVERT(DECIMAL(18, 2), oi.price),
    TRY_CONVERT(DECIMAL(18, 2), oi.freight_value),

    TRY_CONVERT(DECIMAL(18, 2), oi.price)
        + TRY_CONVERT(DECIMAL(18, 2), oi.freight_value)
FROM stg.order_items AS oi
INNER JOIN stg.orders AS o
    ON oi.order_id = o.order_id
INNER JOIN stg.customers AS c
    ON o.customer_id = c.customer_id;
GO


-- Relationships
ALTER TABLE analytics.fact_orders
ADD CONSTRAINT FK_fact_orders_customer
FOREIGN KEY (customer_unique_id)
REFERENCES analytics.dim_customers(customer_unique_id);
GO

ALTER TABLE analytics.fact_orders
ADD CONSTRAINT FK_fact_orders_purchase_date
FOREIGN KEY (purchase_date_key)
REFERENCES analytics.dim_date(date_key);
GO

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT FK_fact_order_items_order
FOREIGN KEY (order_id)
REFERENCES analytics.fact_orders(order_id);
GO

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT FK_fact_order_items_customer
FOREIGN KEY (customer_unique_id)
REFERENCES analytics.dim_customers(customer_unique_id);
GO

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT FK_fact_order_items_product
FOREIGN KEY (product_id)
REFERENCES analytics.dim_products(product_id);
GO

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT FK_fact_order_items_seller
FOREIGN KEY (seller_id)
REFERENCES analytics.dim_sellers(seller_id);
GO

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT FK_fact_order_items_purchase_date
FOREIGN KEY (purchase_date_key)
REFERENCES analytics.dim_date(date_key);
GO


-- Indexes used by the dashboard
CREATE INDEX IX_fact_orders_purchase_date
ON analytics.fact_orders(purchase_date_key);
GO

CREATE INDEX IX_fact_orders_customer
ON analytics.fact_orders(customer_unique_id);
GO

CREATE INDEX IX_fact_orders_status
ON analytics.fact_orders(order_status);
GO

CREATE INDEX IX_fact_order_items_product
ON analytics.fact_order_items(product_id);
GO

CREATE INDEX IX_fact_order_items_seller
ON analytics.fact_order_items(seller_id);
GO

CREATE INDEX IX_fact_order_items_purchase_date
ON analytics.fact_order_items(purchase_date_key);
GO


-- Final row-count check
SELECT
    'dim_customers' AS table_name,
    COUNT(*) AS row_count
FROM analytics.dim_customers

UNION ALL

SELECT
    'dim_products',
    COUNT(*)
FROM analytics.dim_products

UNION ALL

SELECT
    'dim_sellers',
    COUNT(*)
FROM analytics.dim_sellers

UNION ALL

SELECT
    'dim_date',
    COUNT(*)
FROM analytics.dim_date

UNION ALL

SELECT
    'fact_orders',
    COUNT(*)
FROM analytics.fact_orders

UNION ALL

SELECT
    'fact_order_items',
    COUNT(*)
FROM analytics.fact_order_items;
GO