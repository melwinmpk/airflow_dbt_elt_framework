{{ config(
    materialized='table'
    ,schema='gold'
) }}

WITH seller_orders AS (

    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(*) AS total_items_sold,
        SUM(oi.price) AS total_sales,
        SUM(oi.freight_value) AS total_freight,
        AVG(oi.price) AS average_item_price
    FROM {{ ref('fact_order_items') }} oi
    GROUP BY
        oi.seller_id

),

seller_reviews AS (

    SELECT
        oi.seller_id,
        AVG(orv.review_score) AS average_review_score
    FROM {{ ref('fact_order_items') }} oi
    INNER JOIN {{ ref('fact_reviews') }} orv
        ON oi.order_id = orv.order_id
    GROUP BY
        oi.seller_id

)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,

    so.total_orders,
    so.total_items_sold,

    ROUND(so.total_sales, 2) AS total_sales,
    ROUND(so.total_freight, 2) AS total_freight,
    ROUND(so.average_item_price, 2) AS average_item_price,

    ROUND(COALESCE(sr.average_review_score, 0), 2) AS average_review_score

FROM {{ ref('dim_sellers') }} s

LEFT JOIN seller_orders so
    ON s.seller_id = so.seller_id

LEFT JOIN seller_reviews sr
    ON s.seller_id = sr.seller_id

ORDER BY
    total_sales DESC NULLS LAST