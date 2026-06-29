{{ config(
    materialized='ephemeral'
) }}

{% if execute %}
    {# 1. Create physical table if it doesn't exist #}
    {% set create_table_sql %}
        CREATE TABLE IF NOT EXISTS silver.dim_sellers ( 
            seller_id VARCHAR(32),
            seller_zip_code_prefix INTEGER,
            seller_city VARCHAR(40),
            seller_state VARCHAR(2),
            partition_key VARCHAR(6),
            record_hash VARCHAR(700),
            created_date TIMESTAMP,
            expired_date TIMESTAMP,
            is_latest BOOLEAN
        );
    {% endset %}
    {% do run_query(create_table_sql) %}

    {# 2. Run the custom merge script #}
    {% set merge_sql %}
        {{ load_dimension('bronze', 'sellers', 'silver', 'dim_sellers') }}
    {% endset %}

    {# 3. FIXED: Explicitly commit the transaction so PostgreSQL keeps the data #}
    {#
        PostgreSQL transaction is not committed automatically when executing
        MERGE via run_query() in this execution pattern.
        An explicit COMMIT is required to persist the changes.
    #}
    {% do run_query("COMMIT;") %}
    
{% endif %}

SELECT NULL LIMIT 0
