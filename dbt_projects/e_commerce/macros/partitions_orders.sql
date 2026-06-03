{% macro generate_orders_partitions(month) %}
    {#--{% for month in months_list %} #}
        
    -- 1. Create the Foreign Table
    CREATE FOREIGN TABLE IF NOT EXISTS Bronze.ext_orders_{{ month }} (
        order_id VARCHAR(32),
        customer_id VARCHAR(32),
        order_status VARCHAR(11),
        order_purchase_timestamp TIMESTAMP,
        order_approved_at TIMESTAMP,
        order_delivered_carrier_date TIMESTAMP,
        order_delivered_customer_date TIMESTAMP,
        order_estimated_delivery_date TIMESTAMP,
        partition_key VARCHAR(6)
    )
    SERVER pg_local_files
    OPTIONS ( 
        filename '/home/de24/S3_BUCKET/RAW/ecomm/orders/{{ month }}/data.csv', 
        format 'csv', 
        header 'true' 
    );

    -- 2. Safe Attach
    DO $$ 
    BEGIN 
        IF NOT EXISTS (
            SELECT 1 FROM pg_inherits 
            WHERE inhrelid = 'Bronze.ext_orders_{{ month }}'::regclass
        ) THEN
            ALTER TABLE Bronze.orders 
            ATTACH PARTITION Bronze.ext_orders_{{ month }} 
            FOR VALUES IN ('{{ month }}');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Optional: If it's already attached via a different name or fails, skip it
        NULL;
    END $$;

    {#--{% endfor %} #}
{% endmacro %}