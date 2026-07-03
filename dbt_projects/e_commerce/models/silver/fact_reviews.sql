{{ config(
    materialized='incremental'
    ,unique_key='order_id'
    ,schema='silver'
) }}

select
    review_id
    ,order_id
    ,review_score
    ,case
        when review_score >= 4
        then 'Positive'
        when review_score = 3
        then 'Neutral'
        else 'Negative'
        end as sentiments
    ,(review_answer_timestamp::DATE - review_creation_date::DATE) AS Review_Response_Time_Days
    ,review_comment_title
    ,review_comment_message
    ,review_creation_date
    ,review_answer_timestamp
    ,partition_key
from {{ ref('brz_order_reviews') }} 
{% if is_incremental() %}
    where partition_key > (    select COALESCE(MAX(partition_key), '190001')  from {{ this }}  )
{% endif %}

