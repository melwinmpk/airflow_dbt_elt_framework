{{ config(
    materialized='incremental'
    ,unique_key='seller_id'
    ,schema='silver'
) }}

select
    md5(seller_id) as seller_sk,
    seller_id,
    seller_zip_code_prefix,
    upper(trim(seller_city)) as seller_city,
    upper(trim(seller_state)) as seller_state,
    partition_key,
    current_timestamp() as created_at
from {{ ref('brz_sellers') }} 
{% if is_incremental() %}
    where partition_key > (    select max(partition_key) from {{ this }}  )
{% endif %}

merge into silver.dim_sellers target
using (
    with source_data as (
            select *
            from bronze.sellers
            where partition_key >
            (
                -- change it and get it from Meta Data table
                select coalesce(max(partition_key),0) 
                from silver.dim_sellers
            )
    ),
    source_hashed as (
        select
            *,
            -- the md5 is not feasiable if we have more columns in dim there could be 400 or more coulmns this is what i think or use sha5
            -- but using it is really Good
            -- this is needed if we get a record non of the column values changed exept the updated column because of the data reprocess in source 
            -- we could avoid the unwanted versions/expiry for the same record

            sha2(
                concat_ws('|',
                    coalesce(cast(seller_zip_code_prefix as varchar),''),
                    coalesce(cast(seller_city as varchar),''),
                    coalesce(cast(seller_state as varchar),'')
                ),
                256
            ) as record_hash
        from source_data
    ),
    target_active as (
        -- we could get only those records which is present in the Delta changes from the source_data
        select tgt.*
        from silver.dim_sellers tgt
        join (
            select distinct seller_id
            from source_data
        ) src
        on tgt.seller_id = src.seller_id
        where is_latest = true
    ),
    changes as (
        -- this is needed if we get a record non of the column values changed exept the updated column because of the data reprocess in source 
        -- we could avoid the unwanted versions/expiry for the same record
        select
            src.*,
            tgt.record_hash as target_hash,
            case
                when tgt.record_hash is null
                    then 'NEW'
                when src.record_hash <> tgt.record_hash
                    then 'CHANGED'
                else 'UNCHANGED'
            end as change_type
        from source_hashed src
        left join target_active tgt
            on src.seller_id = tgt.seller_id
    ),
    expired_versions as (
        -- this is Good approach 
    select
        tgt.seller_sk,
        tgt.seller_id,
        tgt.seller_zip_code_prefix,
        tgt.seller_city,
        tgt.seller_state,
        tgt.partition_key,
        tgt.record_hash,
        tgt.created_date,
        current_timestamp() as expired_date,
        false as is_latest,
        'EXPIRED' as change_type
    from target_active tgt
    join changes ch
        on tgt.seller_id = ch.seller_id
    where ch.change_type = 'CHANGED'
    ),
    new_versions as (
    select

        md5(
            concat(
                cast(seller_id as varchar),
                current_timestamp()
            )
        ) as seller_sk,
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        partition_key,
        record_hash,
        current_timestamp() as created_date,
        null as expired_date,
        true as is_latest
    from changes
    where change_type in ('NEW','CHANGED')
    )
    select *,
    'INSERT' as action
    from new_versions

    union all

    select *,
    'EXPIRE' as action
    from expired_versions
) source
on target.seller_id = source.seller_id 
and target.is_latest = true 
AND source.action='EXPIRE'
WHEN MATCHED
THEN UPDATE
SET
    is_latest = FALSE,
    expired_date = CURRENT_TIMESTAMP() 
WHEN NOT MATCHED
THEN INSERT (
        seller_sk,
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        partition_key,
        record_hash,
        created_date,
        expired_date,
        is_latest) 
 VALUES (source.seller_sk,
         source.seller_id,
         source.seller_zip_code_prefix,
         source.seller_city,
         source.seller_state,
         source.partition_key,
         source.record_hash,
         source.created_date,
         source.expired_date,
         source.is_latest)


