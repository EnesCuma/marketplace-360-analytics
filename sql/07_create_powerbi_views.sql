USE Marketplace360;
GO

/* =========================================================
   Power BI semantic views
   Staging ve analytics tabloları değiştirilmez.
   ========================================================= */


-- =========================================================
-- 1. Orders view: one row per order
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_orders
AS
SELECT
    fo.order_id,
    fo.customer_unique_id,
    fo.purchase_date_key,
    fo.order_status,

    fo.order_purchase_timestamp,
    fo.order_approved_at,
    fo.order_delivered_carrier_date,
    fo.order_delivered_customer_date,
    fo.estimated_delivery_date,

    fo.item_count,
    fo.distinct_product_count,
    fo.distinct_seller_count,

    fo.item_value,
    fo.freight_value,
    fo.gross_order_value,

    fo.payment_value,
    fo.payment_count,
    fo.payment_method_count,
    fo.maximum_installments,
    fo.primary_payment_type,

    CAST(
        fo.payment_value - fo.gross_order_value
        AS DECIMAL(18, 2)
    ) AS payment_difference,

    CAST(
        CASE
            WHEN ABS(fo.payment_value - fo.gross_order_value) > 0.01
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS has_payment_difference,

    CAST(
        CASE
            WHEN fo.gross_order_value > 0
                THEN fo.freight_value * 100.0
                     / fo.gross_order_value
            ELSE NULL
        END
        AS DECIMAL(10, 2)
    ) AS freight_share_percent,

    fo.review_id,
    fo.review_score,
    fo.review_count,
    fo.has_conflicting_reviews,

    CASE
        WHEN fo.review_score IS NULL
            THEN 'No Review'
        WHEN fo.review_score IN (1, 2)
            THEN 'Low'
        WHEN fo.review_score = 3
            THEN 'Neutral'
        WHEN fo.review_score IN (4, 5)
            THEN 'High'
    END AS review_group,

    fo.approval_hours,
    fo.delivery_days,
    fo.carrier_to_customer_days,
    fo.estimated_delivery_days,
    fo.delivery_delay_days,

    fo.is_delivered,
    fo.is_canceled,
    fo.is_late_delivery,
    fo.is_delivery_sequence_valid,
    fo.has_non_positive_payment,

    -- Satış analizine yalnızca ürün içeren teslim edilmiş siparişler girer.
    CAST(
        CASE
            WHEN fo.order_status = 'delivered'
             AND fo.item_count > 0
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS include_in_sales_analysis,

    -- Açık şekilde hatalı tarih sırası olan kayıtlar dışarıda bırakılır.
    -- Taşıyıcı tarihi eksik olsa bile diğer teslimat tarihleri
    -- kullanılabiliyorsa kayıt analize alınır.
    CAST(
        CASE
            WHEN fo.order_status = 'delivered'
             AND fo.delivery_days IS NOT NULL
             AND fo.is_late_delivery IS NOT NULL
             AND
             (
                 fo.is_delivery_sequence_valid = 1
                 OR fo.is_delivery_sequence_valid IS NULL
             )
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS include_in_delivery_analysis,

    CASE
        WHEN fo.order_status <> 'delivered'
            THEN 'Not Delivered'

        WHEN fo.is_delivery_sequence_valid = 0
            THEN 'Invalid Date Sequence'

        WHEN fo.delivery_days IS NULL
          OR fo.is_late_delivery IS NULL
            THEN 'Delivery Date Missing'

        WHEN fo.is_late_delivery = 1
            THEN 'Late'

        WHEN fo.is_late_delivery = 0
            THEN 'On Time'

        ELSE 'Delivery Date Missing'
    END AS delivery_performance_group

FROM analytics.fact_orders AS fo;
GO


-- =========================================================
-- 2. Order items view: one row per order item
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_order_items
AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.customer_unique_id,
    oi.product_id,
    oi.seller_id,
    oi.purchase_date_key,
    oi.shipping_limit_date,

    oi.item_price,
    oi.freight_value,
    oi.total_line_value,

    fo.order_status,
    fo.is_delivered,

    CAST(
        CASE
            WHEN fo.order_status = 'delivered'
             AND fo.item_count > 0
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS include_in_sales_analysis

FROM analytics.fact_order_items AS oi
INNER JOIN analytics.fact_orders AS fo
    ON oi.order_id = fo.order_id;
GO


-- =========================================================
-- 3. Customer dimension view
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_customers
AS
SELECT
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    first_order_date,
    last_order_date,
    order_count,

    CASE
        WHEN order_count > 1
            THEN 'Repeat Customer'
        ELSE 'One-time Customer'
    END AS customer_type,

    CAST(
        CASE
            WHEN order_count > 1
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS is_repeat_customer,

    DATEDIFF(
        DAY,
        first_order_date,
        last_order_date
    ) AS customer_lifetime_days

FROM analytics.dim_customers;
GO


-- =========================================================
-- 4. Product dimension view
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_products
AS
SELECT
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
    product_volume_cm3,

    CASE
        WHEN category_name_english = 'unknown'
            THEN 'Missing Category'

        WHEN category_name_english IN
        (
            'pc_gamer',
            'kitchen_portables_and_food_preparers'
        )
            THEN 'Manual Translation'

        ELSE 'Official Translation'
    END AS category_quality_group

FROM analytics.dim_products;
GO


-- =========================================================
-- 5. Seller dimension view
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_sellers
AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state

FROM analytics.dim_sellers;
GO


-- =========================================================
-- 6. Date dimension view
-- =========================================================
CREATE OR ALTER VIEW analytics.vw_pbi_date
AS
SELECT
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
    is_weekend,

    calendar_year * 100
        + month_number AS year_month_sort_key,

    LEFT(month_name, 3) AS short_month_name

FROM analytics.dim_date;
GO


-- =========================================================
-- 7. View row-count validation
-- =========================================================
SELECT
    'vw_pbi_orders' AS view_name,
    COUNT(*) AS row_count
FROM analytics.vw_pbi_orders

UNION ALL

SELECT
    'vw_pbi_order_items',
    COUNT(*)
FROM analytics.vw_pbi_order_items

UNION ALL

SELECT
    'vw_pbi_customers',
    COUNT(*)
FROM analytics.vw_pbi_customers

UNION ALL

SELECT
    'vw_pbi_products',
    COUNT(*)
FROM analytics.vw_pbi_products

UNION ALL

SELECT
    'vw_pbi_sellers',
    COUNT(*)
FROM analytics.vw_pbi_sellers

UNION ALL

SELECT
    'vw_pbi_date',
    COUNT(*)
FROM analytics.vw_pbi_date;
GO


-- =========================================================
-- 8. Business filter validation
-- =========================================================
SELECT
    SUM(
        CASE
            WHEN include_in_sales_analysis = 1
                THEN 1
            ELSE 0
        END
    ) AS sales_analysis_orders,

    SUM(
        CASE
            WHEN include_in_delivery_analysis = 1
                THEN 1
            ELSE 0
        END
    ) AS delivery_analysis_orders,

    SUM(
        CASE
            WHEN delivery_performance_group = 'Late'
                THEN 1
            ELSE 0
        END
    ) AS late_delivery_orders,

    SUM(
        CASE
            WHEN delivery_performance_group = 'On Time'
                THEN 1
            ELSE 0
        END
    ) AS on_time_delivery_orders

FROM analytics.vw_pbi_orders;
GO