-- models/staging/stg_customers.sql

{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.customer (
            customer_id VARCHAR(32),
            customer_unique_id VARCHAR(32),
            customer_zip_code_prefix INTEGER,
            customer_city VARCHAR(32),
            customer_state VARCHAR(2),
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_customer_partitions(get_partition_months('customer')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('customer') }}"]
) }}

select 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    partition_key as yyyymm 
from {{ source('bronze_layer', 'customer') }}