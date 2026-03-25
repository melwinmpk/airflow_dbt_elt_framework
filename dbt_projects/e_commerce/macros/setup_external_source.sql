{% macro setup_external_source() %}
    {% set sql %}
        CREATE EXTENSION IF NOT EXISTS file_fdw;
        DO $$ 
        BEGIN 
            IF NOT EXISTS (SELECT 1 FROM pg_foreign_server WHERE srvname = 'pg_local_files') THEN
                CREATE SERVER pg_local_files FOREIGN DATA WRAPPER file_fdw;
            END IF;
        END $$;
    {% endset %}
    
    {% do run_query(sql) %}
    {% do log("Foreign Data Wrapper setup complete", info=True) %}
{% endmacro %}