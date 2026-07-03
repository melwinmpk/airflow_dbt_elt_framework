{{ config(
    materialized='table'
    ,schema='gold'
) }}


WITH order_summary AS (

    SELECT
        oi.order_id,
        SUM(oi.price) AS total_sales,
        SUM(oi.freight_value) AS total_freight,
        COUNT(*) AS total_items
    FROM {{ ref('fact_order_items') }} oi
    GROUP BY oi.order_id

),

sales_summary AS (

    SELECT
        CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        SUM(os.total_sales) AS total_sales,
        SUM(os.total_freight) AS total_freight,
        SUM(os.total_items) AS total_items,
        ROUND(AVG(os.total_sales), 2) AS average_order_value
    FROM {{ ref('fact_orders') }} o
    JOIN order_summary os
        ON o.order_id = os.order_id
    GROUP BY CAST(o.order_purchase_timestamp AS DATE)

)

SELECT *
FROM sales_summary
ORDER BY purchase_date