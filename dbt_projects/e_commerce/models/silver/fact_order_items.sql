{{ config(
    materialized='table'
) }}


select
     order_id
    ,order_item_id
    ,product_id
    ,seller_id
    ,shipping_limit_date
    ,price
    ,freight_value
    ,partition_key
from {{ ref('brz_order_items') }}