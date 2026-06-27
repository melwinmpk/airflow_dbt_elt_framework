{% macro get_table_metadata(
    target_schema,
    target_table,
    source_schema,
    source_table
) %}

    {% set query %}
        SELECT
            target_schema,
            target_table,
            source_schema,
            source_table,
            extract_date_column,
            load_type,
            scd_type,
            hash_column_name
        FROM {{ target_schema }}.table_load_config
        WHERE
             target_schema = '{{ target_schema }}'
          AND target_table = '{{ target_table }}'
          AND source_schema = '{{ source_schema }}'
          AND source_table = '{{ source_table }}'
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}

        {% if results.rows | length == 0 %}
            {{ exceptions.raise_compiler_error(
                "Metadata not found for "
                ~ source_schema ~ "." ~ source_table
            ) }}
        {% endif %}

        {% set target_schema = results.rows[0][0] %}
        {% set target_table = results.rows[0][1] %}
        {% set source_schema = results.rows[0][2] %}
        {% set source_table = results.rows[0][3] %}
        {% set extract_date_column = results.rows[0][4] %}
        {% set load_type = results.rows[0][5] %}
        {% set scd_type = results.rows[0][6] %}
        {% set hash_column_name = results.rows[0][7] %}

           {% set query %}
                SELECT
                    column_name,
                    is_primary_key,
                    is_scd2_column,
                    is_audit_column
                FROM {{ target_schema }}.table_column_config
                WHERE config_id IN (
                SELECT
                        config_id
                    FROM {{ target_schema }}.table_load_config
                    WHERE
                    AND target_schema = '{{ target_schema }}'
                    AND target_table = '{{ target_table }}'
                    AND source_schema = '{{ source_schema }}'
                    AND source_table = '{{ source_table }}' )
            {% endset %}

            {% set column_data = run_query(query) %} 
            {% set column_names = [] %}
            {% set primary_keys = [] %}
            {% set scd2_columns = [] %}
            {% set audit_columns = [] %}

            {% for row in column_data.rows %}

                {% do column_names.append(row[0]) %}

                {% if row[1] %}
                    {% do primary_keys.append(row[0]) %}
                {% endif %}

                {% if row[2] %}
                    {% do scd2_columns.append(row[0]) %}
                {% endif %}

                {% if row[3] %}
                    {% do audit_columns.append(row[0]) %}
                {% endif %}

            {% endfor %}

        {{ return({
            "target_schema" : target_schema,
            "target_table" : target_table,
            "source_schema" : source_schema,
            "source_table" : source_table,
            "extract_date_column" : extract_date_column,
            "load_type" : load_type,
            "scd_type" : scd_type,
            "hash_column_name" : hash_column_name,
            "column_names": column_names,
            "primary_keys": primary_keys,
            "scd2_columns": scd2_columns,
            "audit_columns": audit_columns
        }) }}

    {% endif %}

{% endmacro %}