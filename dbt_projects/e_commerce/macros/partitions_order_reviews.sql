{% macro generate_order_reviews_partitions(month) %}
    {#--{% for month in months_list %} #}
        
    -- 1. Create the Foreign Table
    CREATE FOREIGN TABLE IF NOT EXISTS Bronze.ext_order_reviews_{{ month }} (
        review_id VARCHAR(32),
        order_id VARCHAR(32),
        review_score INTEGER,
        review_comment_title VARCHAR(26),
        review_comment_message VARCHAR(208),
        review_creation_date TIMESTAMP,
        review_answer_timestamp TIMESTAMP,
        partition_key VARCHAR(6)
    )
    SERVER pg_local_files
    OPTIONS ( 
        filename '/home/de24/S3_BUCKET/RAW/ecomm/order_reviews/{{ month }}/data.csv', 
        format 'csv', 
        header 'true' 
    );

    -- 2. Safe Attach
    DO $$ 
    BEGIN 
        IF NOT EXISTS (
            SELECT 1 FROM pg_inherits 
            WHERE inhrelid = 'Bronze.ext_order_reviews_{{ month }}'::regclass
        ) THEN
            ALTER TABLE Bronze.order_reviews 
            ATTACH PARTITION Bronze.ext_order_reviews_{{ month }} 
            FOR VALUES IN ('{{ month }}');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Optional: If it's already attached via a different name or fails, skip it
        NULL;
    END $$;

    {#--{% endfor %} #}
{% endmacro %}