{% macro scd2_load(source_schema,source_table, pk_columns, source_partiton_column, scd2_columns, tracked_columns, target_schema, target_table) %}

{% set merge_sql %}
    merge into {{target_schema}}.{{target_table}} target
    using (
    with source_data as (
        select *
        from {{source_schema}}.{{ source_table }}
        where {{ source_partiton_column }} >
        (
            select COALESCE(MAX({{ source_partiton_column }}), '190001')
            from {{target_schema}}.{{target_table}} 
        )
    ),
    source_hash as (
        select
            *,
            sha256(
                concat_ws(
                    '|'
                    {% for col in scd2_columns %}
                        ,coalesce(cast({{ col }} as varchar),'')
                    {% endfor %}
                )::bytea
            )::text as record_hash
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
        left join target_active tgt
            on  {% for col in pk_columns %}
                src.{{ col }} = tgt.{{ col }}
                    {% if not loop.last %}
                        and
                    {% endif %}
            {% endfor %}
    ),
    expired_versions as (
        select
            {% for col in tracked_columns %}
                {% if  col  == 'expired_date' %}
                    current_timestamp as {{ col }}
                {% elif   col  == 'is_latest' %}
                    false as {{ col }} 
                {% else %}
                    tgt.{{ col }}  {# -- FIXED: Added table prefix to avoid ambiguity #}
                {% endif %}
                {% if not loop.last %}
                    ,
                {% endif %}
            {% endfor %},  {# -- FIXED: Placed comma outside loop safely #}
            'EXPIRED' as change_type 
        from target_active tgt
        join change_detection ch
            on 
            {% for col in pk_columns %}
                tgt.{{ col }} = ch.{{ col }}
                    {% if not loop.last %}
                        and
                    {% endif %}
            {% endfor %}
        where ch.change_type = 'CHANGED'
        ),
        new_versions as (
            select
            {% for col in tracked_columns %}
                {% if  col  == 'created_date' %}
                    current_timestamp as {{ col }}
                {% elif   col  == 'is_latest' %}
                    true as {{ col }}
                {% elif   col  == 'expired_date' %}
                    CAST(NULL AS timestamp) as {{ col }}
                {% else %}
                    {{ col }}
                {% endif %}   
                {% if not loop.last %}
                ,
                {% endif %}   
            {% endfor %}
            ,change_type
        from change_detection
        where change_type in ('NEW','CHANGED')
        )
        select {% for col in tracked_columns %}
                {{ col }}
                {% if not loop.last %}
                ,
                {% endif %}
            {% endfor %},
        'INSERT' as action
        ,FALSE AS is_expired
        from new_versions

        union all

        select {% for col in tracked_columns %}
                {{ col }}
                {% if not loop.last %}
                ,
                {% endif %}
            {% endfor %},
        'EXPIRE' as action
        ,TRUE AS is_expired
        from expired_versions 
    ) source
    on 
    {% for col in pk_columns %}
        source.{{ col }} = target.{{ col }} and
    {% endfor %}
    target.is_latest = true 
    AND source.is_expired = TRUE
    WHEN MATCHED 
    THEN UPDATE
    SET
        is_latest = FALSE,
        expired_date = CURRENT_TIMESTAMP 
    WHEN NOT MATCHED AND source.is_expired = FALSE
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
{% endset %}

{{ log(merge_sql, info=True) }}

{% do run_query(merge_sql) %}

{% endmacro %}