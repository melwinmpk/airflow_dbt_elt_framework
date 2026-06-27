{{ config(
    materialized='incremental',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS silver.dim_sellers ( 
            seller_id VARCHAR(32),
            seller_zip_code_prefix INTEGER,
            seller_city VARCHAR(40),
            seller_state VARCHAR(2),
            partition_key VARCHAR(6),
            record_hash VARCHAR(64),
            created_date TIMESTAMP,
            expired_date TIMESTAMP,
            is_latest BOOLEAN
        );" ]
) }}

{#
{{load_dimension( 'bronze', 'sellers', 'silver', 'dim_sellers' ) }}

-- By executing the macro inside a conditional block via run_query, 
-- it runs the MERGE statement directly against the database naked.
#}
{% if execute %}
    {% set merge_sql %}
        {{ load_dimension('bronze', 'sellers', 'silver', 'dim_sellers') }}
    {% endset %}
    {% do run_query(merge_sql) %}
{% endif %}

{#
-- We provide a dummy select statement here so dbt's compiler doesn't break
-- when it tries to run its internal validation wrapper.
#}