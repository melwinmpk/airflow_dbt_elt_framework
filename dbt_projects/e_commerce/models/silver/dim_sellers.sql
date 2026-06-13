{{ config(
    materialized='incremental'
    ,unique_key='seller_id'
    ,schema='silver'
) }}

select
    md5(seller_id) as seller_sk,
    seller_id,
    seller_zip_code_prefix,
    upper(trim(seller_city)) as seller_city,
    upper(trim(seller_state)) as seller_state,
    partition_key,
    current_timestamp as created_at
from {{ ref('brz_sellers') }} 
{% if is_incremental() %}
    where partition_key > (    select max(partition_key) from {{ this }}  )
{% endif %}