import datetime
from airflow.sdk import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from utility.utility import upload_data_to_s3,  get_metadata_mysql, update_mysql_config
import json



main_data = {
        'source_database_name' : 'ecomm',
        'table_name' : 'customer',
        'destination_bucket' : '/home',
        'destination_s3_dir_path' : '/de24/S3_BUCKET/RAW/'
       }

def Upload_data_to_s3(ti):

    # Get Last extract Date from MYSQL Config Schema
    # mysql_df = get_lastextract_mysql(main_data)
    # tbl_query = get_tbl_query_mysql(main_data)
    meta_data = get_metadata_mysql(main_data)


    # Get Current Extract Dates (It couls be moer than 1 Date) get it from on-prem Database
    #current_extract_date_objs = get_currentdate_extract_mysql(mysql_df,main_data)

    data = {
        "table_name":main_data["table_name"],
        "source_database_name": main_data["source_database_name"],
        "destination_bucket":main_data["destination_bucket"],
        "destination_s3_dir_path":main_data["destination_s3_dir_path"],
        "meta_data":meta_data
           }

    upload_data_to_s3(data)

def update_config():
    data = {
    "database_name" : main_data["source_database_name"],
    "table_name" : main_data["table_name"]
        }
    update_mysql_config(data)

with DAG(
    dag_id="ecomm_mysql_to_s3_Dag",
    start_date=datetime.datetime(2024,1,1),
    schedule=None
    ) as dag:

    Upload_data_to_S3_task = PythonOperator(
            task_id='Upload_data_to_S3',
            python_callable=Upload_data_to_s3
        )
    Update_configs_task = PythonOperator(
            task_id='Update_Configs',
            python_callable=update_config
        )


    Start = EmptyOperator(task_id="Start")
    End   = EmptyOperator(task_id="End")
    Start >> Upload_data_to_S3_task >> Update_configs_task >> End