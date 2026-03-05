import datetime
from .database_helper import mysql_db_helper
import pandas as pd
import os
import json
import boto3
import io



def get_lastextract_mysql(data):
    mysql_obj = mysql_db_helper('ecomm')
    table_name = data.get('table_name',None)
    df = mysql_obj.query_exec_getresult(f'''SELECT last_extract_date FROM metadata_config  
                                            WHERE  table_name = {table_name};''')
    mysql_obj.connection_close()

    return df 

def upload_data_to_s3(data):

    print("============== Uploading Data to S3 =============== ")

    source_database_name = data.get("source_database_name","")
    table_name = data.get("table_name","")
    current_extract_date_objs = data.get("current_extract_date_objs","")
    destination_bucket = data.get('destination_bucket',"")
    destination_s3_dir_path = data.get('destination_s3_dir_path', "")


    s3_client = boto3.client('s3')
    db = database_helper(source_database_name)

    for date in current_extract_date_objs:

        query = f'''Select * from {source_database_name}.{table_name} where business_date = '{date}';'''
        df = db.query_exec_getresult(query)

        date_string = f'''{date.strftime('%Y')}{date.strftime('%m')}{date.strftime('%d')}'''

        outdir_path = f'{destination_s3_dir_path}{destination_database_name}/{table_name}/{date_string}'
        filename = f'{date_string}-{table_name.replace("_","-")}.csv'

        with io.StringIO() as csv_buffer:
            df.to_csv(csv_buffer, sep=',',index=False, encoding='utf-8')

            response = s3_client.put_object(Bucket = destination_bucket, Key = f'{outdir_path}/{filename}', Body = csv_buffer.getvalue())

            status = response.get("ResponseMetadata",{}).get("HTTPStatusCode")

            if status == 200:
                print(f" File = {filename} loaded to S3 path {destination_bucket}/{outdir_path}/ Succesfully Status {status} ")
            else:
                print(f" File was upload Unsuccesfully Status {status} ")

    print("============== Upload Data Task End =============== ")
