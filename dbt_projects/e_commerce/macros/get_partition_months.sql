{% macro get_partition_months(tbl_name) %}
    {% set query %}
        -- Use single quotes for the string value in the WHERE clause
        SELECT TO_CHAR(last_extracxt_date + (duration || ' ' || duration_type)::INTERVAL,'YYYYMM')::VARCHAR AS next_extract_date  FROM bronze.metadata_config WHERE table_name = '{{ tbl_name }}'
    {% endset %}
    {% set results = run_query(query) %}
    

    {% if execute %}
        {% set months = results.columns.get('next_extract_date').values() %}
        {{ return(months[0]) }}
    {% else %}
        {{ return('') }}
    {% endif %}
{% endmacro %}