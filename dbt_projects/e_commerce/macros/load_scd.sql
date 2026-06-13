{% macro load_dimension(
    source_schema,
    source_table,
    destination_schema,
    destination_table,
    scd_type
) %}

    {% if scd_type not in [1,2] %}
        {{ exceptions.raise_compiler_error(
            "Only SCD Type 1 and Type 2 are supported"
        ) }}
    {% endif %}

    {% set metadata = get_table_metadata(
        source_schema,
        source_table,
        destination_schema,
        destination_table
    ) %}

    {% set pk_cols = metadata['primary_keys'] %}
    {% set timestamp_col = metadata['timestamp_column'] %}

    {{ log("Primary Keys : " ~ pk_cols, info=True) }}
    {{ log("Timestamp Col : " ~ timestamp_col, info=True) }}

    {% if scd_type == 1 %}

        -- Type 1 logic here

    {% elif scd_type == 2 %}

        -- Type 2 logic here

    {% endif %}

{% endmacro %} 