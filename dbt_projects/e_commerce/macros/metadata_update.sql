{% macro update_metadata(tbl_name) %}
    UPDATE bronze.metadata_config
    set last_extracxt_date = (SELECT (MAX(partition_key) || '01') as yyyymmdd FROM Bronze.{{ tbl_name }})::DATE
    WHERE table_name = '{{ tbl_name }}'
{% endmacro %}