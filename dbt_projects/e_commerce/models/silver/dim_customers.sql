{{ config(
    materialized='incremental'
    ,unique_key='customer_id'
    ,schema='silver'
) }}

{# This is Normal Incremental Load #}

select
    md5(customer_id) as customer_sk,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    upper(trim(customer_city)) as customer_city,
    upper(trim(customer_state)) as customer_state,
    partition_key,
    current_timestamp as created_at
from {{ ref('brz_customers') }} 
{% if is_incremental() %}
    where partition_key > (    select COALESCE(MAX(partition_key), '190001') from {{ this }}  )
{% endif %}