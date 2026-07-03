{{ config(
    materialized='incremental'
    ,unique_key='order_id'
    ,schema='silver'
) }}

select
     order_id
    ,order_item_id
    ,product_id
    ,seller_id
    ,shipping_limit_date
    ,price
    ,freight_value
    ,price + freight_value as item_total_amount
    ,partition_key
from {{ ref('brz_order_items') }}
{% if is_incremental() %}
    where partition_key > (    select COALESCE(MAX(partition_key), '190001')  from {{ this }}  )
{% endif %}