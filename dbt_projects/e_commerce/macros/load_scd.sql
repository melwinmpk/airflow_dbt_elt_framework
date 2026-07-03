{% macro load_dimension(
    source_schema,
    source_table,
    destination_schema,
    destination_table
) %}
    {{ log("execute = " ~ execute, info=True) }}

    {# 
        The below if condition was required because the initial naming convention 
        for bronze was incorrect.
        To fix it, we needed to remove the bz_ prefix from the table name.
    #} 

    {% if source_table.startswith('brz_') %}
        {% set source_table = source_table[4:] %}
    {% endif %}

    {% set metadata = silver_get_table_metadata(
        source_schema,
        source_table,
        destination_schema,
        destination_table
    ) %}

    {% set target_schema = metadata['target_schema'] %}
    {% set target_table = metadata['target_table'] %}
    {% set source_schema = metadata['source_schema'] %}
    {% set source_table = metadata['source_table'] %}
    {% set extract_date_column = metadata['extract_date_column'] %}
    {% set load_type = metadata['load_type'] %}
    {% set scd_type = metadata['scd_type'] %}
    {% set hash_column_name = metadata['hash_column_name'] %}
    {% set column_names = metadata['column_names'] %}
    {% set primary_keys = metadata['primary_keys'] %}
    {% set scd2_columns = metadata['scd2_columns'] %}
    {% set audit_columns = metadata['audit_columns'] %}


    {{ log("target_table Keys : " ~ target_table, info=True) }}
    {{ log("column_names : " ~ column_names, info=True) }}

    {% if execute %}
        {% if scd_type not in [1,2] %}
            {{ exceptions.raise_compiler_error(
                "Only SCD Type 1 and Type 2 are supported"
            ) }}
        {% endif %}

        {% if scd_type == 1 %}

            -- Type 1 logic here

        {% elif scd_type == 2 %}

        {#
        -- source_schema, (done)
        -- source_table, (done)
        -- pk_columns, -- need to segregate it
        -- source_partiton_column, 
        -- tracked_columns, -- need to segregate it
        -- target_schema, (done)
        -- target_table,  (done)
        #}
        {{ scd2_load(source_schema, source_table, primary_keys, extract_date_column,
        scd2_columns,column_names, target_schema, target_table) 
        }}

        {% endif %}
    {% endif %}

{% endmacro %} 