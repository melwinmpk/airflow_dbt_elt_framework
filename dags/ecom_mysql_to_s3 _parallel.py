from airflow.decorators import dag, task, task_group
import datetime
# from airflow.sdk import DAG
# from airflow.operators.empty import EmptyOperator
# from airflow.operators.python import PythonOperator
from utility.utility import upload_data_to_s3,  get_metadata_mysql, update_mysql_config

import json

table_names = ['customer','orders','order_items','order_payments','order_reviews', 'sellers']

main_data = {
        'source_database_name' : 'ecomm',
        'table_name' : 'customer',
        'destination_bucket' : '/home',
        'destination_s3_dir_path' : '/de24/S3_BUCKET/RAW/'
       }

@dag(
    dag_id="ecomm_mysql_to_s3_Dag_parallel",  # This will appear in the Airflow UI
    start_date = datetime.datetime(2024, 1, 1), 
    schedule=None
)
def parallel_table_pipeline():

    @task_group(group_id="process_table")
    def process_table(table_name: str):

        @task
        def Upload_data_to_s3(table_name):

            meta_data = get_metadata_mysql(main_data)

            data = {
                "table_name":table_name,
                "source_database_name": main_data["source_database_name"],
                "destination_bucket":main_data["destination_bucket"],
                "destination_s3_dir_path":main_data["destination_s3_dir_path"],
                "meta_data":meta_data
                }

            upload_data_to_s3(data)

        @task
        def update_config(table_name):
            data = {
            "source_database_name" : main_data["source_database_name"],
            "table_name" : table_name
                }
            update_mysql_config(data)
        
        t1 = Upload_data_to_s3(table_name)
        t2 = update_config(table_name)

        t1 >> t2

    process_table.expand(table_name=table_names)
parallel_table_pipeline()