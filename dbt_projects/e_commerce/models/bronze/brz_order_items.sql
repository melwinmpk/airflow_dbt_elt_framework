{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.order_items ( 
            order_id VARCHAR(32),
            order_item_id INTEGER,
            product_id VARCHAR(32),
            seller_id VARCHAR(32),
            shipping_limit_date TIMESTAMP,
            price NUMERIC(9,2),
            freight_value NUMERIC(8,2),
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_order_items_partitions(get_partition_months('order_items')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('order_items') }}"]
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
from {{ source('bronze_layer', 'order_items') }}