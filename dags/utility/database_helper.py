import mysql.connector
import pandas as pd

class mysql_db_helper:
    def __init__(self,data = 'ecomm'):
        database_name = data
        self.create_connection({"database_name":database_name})

    def create_connection(self, data):
        try:
            # refer to understand the connection https://www.red-gate.com/simple-talk/databases/mysql/retrieving-mysql-data-python/
            self.conn = mysql.connector.connect(option_files = '/home/de24/config/mysqldbconnectors.cnf')
            self.conn.database = data['database_name']
            #self.conn.autocommit = True
            self.curr = self.conn.cursor()
        except Exception as e:
            raise Exception(f"Error => {e}")
            

    def query_exec(self,query):
        try:
            self.curr.execute(query)          
            # 1. Check success
            print(f"Rows affected: {self.curr.rowcount}")
            # 2. Save the changes
            self.curr.commit() 
            print("Changes committed to the database.")
        except mysql.connector.Error as err:
            # 3. If an error occurs, the execution stops and goes here
            self.conn.rollback()
            # print(f"Error => {err}")
            raise Exception(f"Error => {err}")

    def query_exec_getresult(self,query):
        try:
            result_df = pd.read_sql(query, self.conn) # reading in Pandas Data frame
        except Exception as e:
            #raise Exception(f"Error => {e}")
            print(f"Error => {e}")
            return -1
        return result_df

    def connection_close(self):
        self.conn.close()

    def __del__(self):
        self.conn.close() 