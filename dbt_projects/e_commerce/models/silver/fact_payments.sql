{{ config(
    materialized='incremental'
    ,unique_key='order_id'
    ,schema='silver'
) }}

select
    order_id ,
    CASE WHEN payment_type IN ('debit_card','credit_card') THEN 'CARD'
         WHEN payment_type = 'voucher' THEN 'Voucher'
         WHEN payment_type = 'boleto' THEN 'Bank Transfer'   
    END AS  payment_type,    
    payment_installments ,
    case
        when payment_installments = 1 then 'Single'
        when payment_installments <= 6 then 'Medium'
        else 'High'
    end as installment_flag,
    SUM(payment_value),
    partition_key
from {{ ref('brz_order_payments') }} 
{% if is_incremental() %}
    where partition_key > (    select COALESCE(MAX(partition_key), '190001')  from {{ this }}  )
{% endif %}
GROUP BY order_id, payment_type, payment_installments, partition_key