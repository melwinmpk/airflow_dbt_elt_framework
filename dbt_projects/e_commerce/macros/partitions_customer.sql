{% macro generate_customer_partitions(month) %}
    {#--{% for month in months_list %} #}
    -- 1. Create the Foreign Table
    CREATE FOREIGN TABLE IF NOT EXISTS Bronze.ext_cust_{{ month }} (
        customer_id VARCHAR(32),
        customer_unique_id VARCHAR(32),
        customer_zip_code_prefix INTEGER,
        customer_city VARCHAR(32),
        customer_state VARCHAR(2),
        partition_key VARCHAR(6)
    )
    SERVER pg_local_files
    OPTIONS ( 
        filename '/home/de24/S3_BUCKET/RAW/ecomm/customer/{{ month }}/data.csv', 
        format 'csv', 
        header 'true' 
    );

    -- 2. Safe Attach
    DO $$ 
    BEGIN 
        IF NOT EXISTS (
            SELECT 1 FROM pg_inherits 
            WHERE inhrelid = 'Bronze.ext_cust_{{ month }}'::regclass
        ) THEN
            ALTER TABLE Bronze.customer 
            ATTACH PARTITION Bronze.ext_cust_{{ month }} 
            FOR VALUES IN ('{{ month }}');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Optional: If it's already attached via a different name or fails, skip it
        NULL;
    END $$;
    {#--{% endfor %} #}
{% endmacro %}