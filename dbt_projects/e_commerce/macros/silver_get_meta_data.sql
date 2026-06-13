{% macro silver_get_table_metadata(
    source_schema,
    source_table,
    target_schema,
    target_table
) %}

{% set query %}

select
    primary_keys,
    tracked_columns,
    watermark_column
from control.table_metadata
where source_schema='{{ source_schema }}'
and source_table='{{ source_table }}'
and target_schema='{{ target_schema }}'
and target_table='{{ target_table }}'

{% endset %}

{% set result = run_query(query) %}

{{ return({
    "primary_keys": result.rows[0][0],
    "tracked_columns": result.rows[0][1],
    "watermark_column": result.rows[0][2]
}) }}

{% endmacro %}