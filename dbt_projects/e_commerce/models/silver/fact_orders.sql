{{ config(
    materialized='incremental'
    ,unique_key='order_id'
    ,schema='silver'
) }}

select 
    order_id
    ,customer_id
    ,order_status
    ,case
        when order_status='delivered'
            then 'Completed'

        when order_status='canceled'
            then 'Cancelled'

        else 'In Progress'
    end as order_status_group
    ,order_purchase_timestamp
    ,order_approved_at
    ,order_delivered_carrier_date
    ,order_delivered_customer_date
    ,(order_purchase_timestamp::DATE - order_delivered_customer_date::DATE) as  days_to_deliver
    ,case
        when order_delivered_customer_date >
            order_estimated_delivery_date
        then 1
        else 0
    end as is_delayed
    ,partition_key 
from {{ ref('brz_orders') }}
{% if is_incremental() %}
    where partition_key > (    select COALESCE(MAX(partition_key), '190001')  from {{ this }}  )
{% endif %}