{{ config(
    materialized='table'
    ,schema='silver'
    ,pre_hook=[
        "CREATE TABLE IF NOT EXISTS silver.dim_sellers ( 
            seller_id VARCHAR(32),
            seller_zip_code_prefix INTEGER,
            seller_city VARCHAR(40),
            seller_state VARCHAR(2),
            partition_key VARCHAR(6),
            record_hash VARCHAR(700),
            created_date TIMESTAMP,
            expired_date TIMESTAMP,
            is_latest BOOLEAN
        );",
        "{{ load_dimension(ref('brz_sellers').schema, ref('brz_sellers').identifier, 'silver', this.identifier) }}"
    ]
    
) }}

SELECT 
seller_id
,seller_zip_code_prefix
,seller_city
,seller_state
,partition_key
,record_hash
,created_date
,expired_date
,is_latest
FROM silver.dim_sellers


