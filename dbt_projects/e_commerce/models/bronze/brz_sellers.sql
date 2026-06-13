{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.sellers ( 
            seller_id VARCHAR(32),
            seller_zip_code_prefix INTEGER,
            seller_city VARCHAR(40),
            seller_state VARCHAR(2),
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_sellers_partitions(get_partition_months('sellers')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('sellers') }}"]
) }}

select 
    seller_id
    ,seller_zip_code_prefix
    ,seller_city
    ,seller_state
    ,partition_key 
from {{ source('bronze_layer', 'sellers') }}