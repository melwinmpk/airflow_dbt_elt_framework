{% macro scd2_load(
    source_schema,
    source_table,
    pk_columns, -- considering source and target have the same primary krys and name
    source_partiton_column,
    tracked_columns, -- considering source and target have the same target column
    target_schema,
    target_table,
    business_keys
) %}

{% set join_condition %}
    {% for key in business_keys %}
        src.{{ key }} = tgt.{{ key }}
        {% if not loop.last %}
            and
        {% endif %}
    {% endfor %}
{% endset %}

merge into silver.dim_sellers target
using (
with source_data as (
    select *
    from {{source_schema}}.{{ source_table }}
    where {{ source_partiton_column }} >
    (
        select extract_date_column
        from {{target_schema}}.table_load_config 
        WHERE target_table = {{target_table}} and 
              target_schema = {{target_schema}}
    )
),
source_hash as (
    select
        *,
        sha2(
            concat_ws(
                '|'
                {% for col in tracked_columns %}
                    ,coalesce(cast({{ col }} as varchar),'')
                {% endfor %}
            ), 256
        ) as record_hash
    from source_data
),
target_active as (
    select tgt.*
        from {{target_schema}}.{{target_table}} tgt
        join (
            select distinct {% for col in pk_columns %}
                                {{ col }}
                                {% if not loop.last %}
                                    ,
                                {% endif %}
                            {% endfor %}
            from source_data
        ) src
        on  {% for col in pk_columns %}
                src.{{ col }} = tgt.{{ col }}
                    {% if not loop.last %}
                        and
                    {% endif %}
            {% endfor %}
        where is_latest = true
),
change_detection as (
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
    from source_hash src
    left join active_target tgt
        on  {% for col in pk_columns %}
            src.{{ col }} = tgt.{{ col }}
                {% if not loop.last %}
                    and
                {% endif %}
        {% endfor %}
),
expired_versions as (
        -- this is Good approach 
    select
        {% for col in tracked_columns %}
            {% if {{ col }} == 'expired_date' %}
                current_timestamp() as {{ col }},
            {% else if  {{ col }} == 'is_latest' %}
                false as {{ col }}, 
            {% else if  {{ col }} == 'expired_date' %}
                current_timestamp() as {{ col }}   , 
            {% else %}
                {{ col }},
            {% endif %}
        {% endfor %}
        'EXPIRED' as change_type 
    from target_active tgt
    join change_detection ch
        on tgt.seller_id = ch.seller_id
    where ch.change_type = 'CHANGED'
    ),
    new_versions as (
            select

        -- md5(
        --     concat(
        --         cast(seller_id as varchar),
        --         current_timestamp()
        --     )
        -- ) as seller_sk,
        -- seller_id,
        -- seller_zip_code_prefix,
        -- seller_city,
        -- seller_state,
        -- partition_key,
        -- record_hash,
        -- current_timestamp() as created_date,
        -- null as expired_date,
        -- true as is_latest



        {% for col in tracked_columns %}
            {% if {{ col }} == 'created_date' %}
                current_timestamp() as {{ col }}
            {% else if  {{ col }} == 'is_latest' %}
                true as {{ col }}
            {% else if  {{ col }} == 'expired_date' %}
                null as {{ col }}
            {% else %}
                {{ col }}
            {% endif %}   
            {% if not loop.last %}
             ,
            {% endif %}   
        {% endfor %}
    from change_detection
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
on 
{% for col in pk_columns %}
    source.{{ col }} = target.{{ col }} and
{% endfor %}
 target.is_latest = true 
AND source.action='EXPIRE'

WHEN MATCHED
THEN UPDATE
SET
    is_latest = FALSE,
    expired_date = CURRENT_TIMESTAMP() 
WHEN NOT MATCHED
THEN INSERT (

         {% for col in tracked_columns %}
            {{ col }}
            {% if not loop.last %}
             ,
            {% endif %}
        {% endfor %}
        ) 
 VALUES (

        {% for col in tracked_columns %}
            source.{{ col }}
            {% if not loop.last %}
             ,
            {% endif %}
        {% endfor %}
        )

{% endmacro %}