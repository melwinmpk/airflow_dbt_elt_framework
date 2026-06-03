{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.orders ( 
            order_id VARCHAR(32),
            customer_id VARCHAR(32),
            order_status VARCHAR(11),
            order_purchase_timestamp TIMESTAMP,
            order_approved_at TIMESTAMP,
            order_delivered_carrier_date TIMESTAMP,
            order_delivered_customer_date TIMESTAMP,
            order_estimated_delivery_date TIMESTAMP,
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_orders_partitions(get_partition_months('orders')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('orders') }}"]
) }}

select 
    order_id
    ,customer_id
    ,order_status
    ,order_purchase_timestamp
    ,order_approved_at
    ,order_delivered_carrier_date
    ,order_delivered_customer_date
    ,partition_key as yyyymm  -- This will now be populated correctly!
from {{ source('bronze_layer', 'orders') }}