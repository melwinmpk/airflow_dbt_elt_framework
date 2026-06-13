{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.order_payments ( 
            order_id VARCHAR(32),
            payment_sequential INTEGER,
            payment_type VARCHAR(11),
            payment_installments INTEGER,
            payment_value NUMERIC(10,2),
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_order_payments_partitions(get_partition_months('order_payments')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('order_payments') }}"]
) }}

select
    order_id
    ,payment_sequential
    ,payment_type
    ,payment_installments
    ,payment_value
    ,partition_key
from {{ source('bronze_layer', 'order_payments') }}