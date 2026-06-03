{{ config(
    materialized='view',
    pre_hook=[
        "CREATE TABLE IF NOT EXISTS Bronze.order_reviews ( 
            review_id VARCHAR(32),
            order_id VARCHAR(32),
            review_score INTEGER,
            review_comment_title VARCHAR(26),
            review_comment_message VARCHAR(208),
            review_creation_date TIMESTAMP,
            review_answer_timestamp TIMESTAMP,
            partition_key VARCHAR(6)
        ) PARTITION BY LIST (partition_key);",
        "{% if execute %}{{ generate_order_reviews_partitions(get_partition_months('order_reviews')) }}{% endif %}"
    ],
    post_hook=["{{ update_metadata('order_reviews') }}"]
) }}

select
    review_id
    ,order_id
    ,review_score
    ,review_comment_title
    ,review_comment_message
    ,review_creation_date
    ,review_answer_timestamp
    ,partition_key as yyyymm 
from {{ source('bronze_layer', 'order_reviews') }}