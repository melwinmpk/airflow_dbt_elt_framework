{% macro scd2_load(
    source_relation,
    business_keys,
    tracked_columns,
    partition_column
) %}

{% set join_condition %}
    {% for key in business_keys %}
        src.{{ key }} = tgt.{{ key }}
        {% if not loop.last %}
            and
        {% endif %}
    {% endfor %}
{% endset %}

with source_data as (
    select *
    from {{ source_relation }}
    {% if is_incremental() %}
    where {{ partition_column }} >
    (
        select coalesce(max({{ partition_column }}),0)
        from {{ this }}
    )
    {% endif %}
),

source_hash as (
    select
        *,
        md5(
            concat_ws(
                '|'
                {% for col in tracked_columns %}
                    ,coalesce(cast({{ col }} as varchar),'')
                {% endfor %}
            )
        ) as record_hash
    from source_data
),

active_target as (
    select *
    from {{ this }}
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
        on {{ join_condition }}

),

records_to_insert as (

    select *

    from change_detection

    where change_type in ('NEW','CHANGED')

)

select

    md5(
        concat(
            {% for key in business_keys %}
                cast({{ key }} as varchar)
                {% if not loop.last %}
                    ,
                {% endif %}
            {% endfor %}
            ,
            current_timestamp()
        )
    ) as surrogate_key,

    *

    exclude(
        target_hash,
        change_type
    ),

    current_timestamp() as created_date,

    cast(null as timestamp) as expired_date,

    true as is_latest

from records_to_insert

{% endmacro %}