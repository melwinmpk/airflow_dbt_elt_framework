{% macro generate_order_items_partitions(month) %}
    {#--{% for month in months_list %} #}
        
    -- 1. Create the Foreign Table
    CREATE FOREIGN TABLE IF NOT EXISTS Bronze.ext_order_items_{{ month }} (
        order_id VARCHAR(32),
        order_item_id INTEGER,
        product_id VARCHAR(32),
        seller_id VARCHAR(32),
        shipping_limit_date TIMESTAMP,
        price NUMERIC(9,2),
        freight_value NUMERIC(8,2),
        partition_key VARCHAR(6)
    )
    SERVER pg_local_files
    OPTIONS ( 
        filename '/home/de24/S3_BUCKET/RAW/ecomm/order_items/{{ month }}/data.csv', 
        format 'csv', 
        header 'true' 
    );

    -- 2. Safe Attach
    DO $$ 
    BEGIN 
        IF NOT EXISTS (
            SELECT 1 FROM pg_inherits 
            WHERE inhrelid = 'Bronze.ext_order_items_{{ month }}'::regclass
        ) THEN
            ALTER TABLE Bronze.order_items 
            ATTACH PARTITION Bronze.ext_order_items_{{ month }} 
            FOR VALUES IN ('{{ month }}');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Optional: If it's already attached via a different name or fails, skip it
        NULL;
    END $$;

    {#--{% endfor %} #}
{% endmacro %}