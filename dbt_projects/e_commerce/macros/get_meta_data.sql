{% macro get_table_metadata(
    source_schema,
    source_table,
    destination_schema,
    destination_table
) %}

    {% set query %}
        SELECT
            primary_keys,
            timestamp_column
        FROM control.table_metadata
        WHERE source_schema = '{{ source_schema }}'
          AND source_table = '{{ source_table }}'
          AND destination_schema = '{{ destination_schema }}'
          AND destination_table = '{{ destination_table }}'
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}

        {% if results.rows | length == 0 %}
            {{ exceptions.raise_compiler_error(
                "Metadata not found for "
                ~ source_schema ~ "." ~ source_table
            ) }}
        {% endif %}

        {% set primary_keys = results.rows[0][0] %}
        {% set timestamp_column = results.rows[0][1] %}

        {{ return({
            "primary_keys": primary_keys,
            "timestamp_column": timestamp_column
        }) }}

    {% endif %}

{% endmacro %}