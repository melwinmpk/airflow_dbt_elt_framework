import datetime
from .database_helper import mysql_db_helper
import pandas as pd
import os
import json
#import boto3
import io
from dateutil.relativedelta import relativedelta



def get_metadata_mysql(data):
    result = {}
    mysql_obj = mysql_db_helper('ecomm')
    table_name = data.get('table_name',None)
    df = mysql_obj.query_exec_getresult(f'''SELECT * FROM metadata_config  
                                            WHERE  table_name = '{table_name}';''')
    mysql_obj.connection_close()
    for column in df.columns:
        result[column] = df[column][0]

    return result 

def get_next_last_extract_date(data):
    meta_data = data.get("meta_data",None)
    last_extract_date = meta_data.get("last_extracxt_date",None)
    next_last_extract_date = last_extract_date + relativedelta(months=1)
    return next_last_extract_date


def upload_data_to_s3(data):

    print("============== Uploading Data to S3 =============== ")
    meta_data = get_metadata_mysql(data)
    data["meta_data"] = meta_data
    table_name = data.get('table_name',None)
    extract_date = get_next_last_extract_date(data)
    source_database_name = data.get('source_database_name',None)
    tbl_query = data["meta_data"].get('tbl_query',None)
    tbl_query = (tbl_query.replace('__YEAR__',f"'{extract_date.year}'")).replace('__MONTH__',f"'{extract_date.month}'")
    
    folder_path = f"/home/de24/S3_BUCKET/RAW/{source_database_name}/{table_name}/{extract_date.year}{extract_date.month if extract_date.month > 9 else '0'+str(extract_date.month) }/"
    os.makedirs(folder_path, exist_ok=True)
    
    mysql_obj = mysql_db_helper('ecomm')
    df = mysql_obj.query_exec_getresult(f'''{tbl_query}''')
    
    df.to_csv(f"{folder_path}/data.csv", index=False)
    mysql_obj.connection_close()

    print("============== Upload Data Task End =============== ")

def update_mysql_config(data):
    meta_data = get_metadata_mysql(data)
    data["meta_data"] = meta_data
    extract_date = get_next_last_extract_date(data)
    mysql_obj = mysql_db_helper('ecomm')
    table_name = data.get('table_name',None)
    df = mysql_obj.query_exec(f'''UPDATE metadata_config
                                  SET last_extracxt_date = '{extract_date.strftime("%Y-%m-%d %H:%M:%S")}'
                                  WHERE  table_name = '{table_name}';''')
    print(f'''UPDATE metadata_config
                                  SET last_extracxt_date = '{extract_date.strftime("%Y-%m-%d %H:%M:%S")}'
                                  WHERE  table_name = '{table_name}';''')
    mysql_obj.connection_close()
