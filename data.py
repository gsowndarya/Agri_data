import streamlit as st
import pandas as pd
import pymysql

# UI: Page Title
st.title("CSV to MySQL Uploader")

# MySQL Connection Function
def connect_to_mysql(host, user, passwd):
    try:
        return pymysql.connect(host=host, user=user, passwd=passwd)
    except Exception as e:
        st.error(f"Error connecting to MySQL: {e}")
        return None

# User Input for MySQL Credentials
host = st.text_input("Enter MySQL Host", "127.0.0.1")
user = st.text_input("Enter MySQL Username", "root")
passwd = st.text_input("Enter MySQL Password", type="password")

if st.button("Connect to MySQL"):
    connection = connect_to_mysql(host, user, passwd)
    if connection:
        st.success("Connected to MySQL!")

# File Uploader
uploaded_file = st.file_uploader("Upload a CSV file", type=['csv'])

if uploaded_file is not None:
    df = pd.read_csv(uploaded_file)
    st.write("### Preview of Uploaded Data")
    st.dataframe(df.head())

    database_name = st.text_input("Enter Database Name")
    table_name = st.text_input("Enter Table Name")

    if st.button("Upload to MySQL"):
        connection = connect_to_mysql(host, user, passwd)
        if connection:
            cursor = connection.cursor()

            # Create Table Schema
            dtype_mapping = {
                'int64': 'INTEGER',
                'float64': 'FLOAT',
                'object': 'TEXT',
                'datetime64[ns]': 'DATETIME',
                'bool': 'BOOLEAN'
            }
            columns = ",".join(f"{col} {dtype_mapping[str(dtype)]}" for col, dtype in zip(df.columns, df.dtypes))
            create_table_query = f"CREATE TABLE {database_name}.{table_name} ({columns});"

            try:
                cursor.execute(f"USE {database_name}")
                cursor.execute(create_table_query)
                st.success(f"Table `{table_name}` created successfully!")
            except Exception as e:
                st.error(f"Error creating table: {e}")

            # Insert Data
            try:
                for i in range(len(df)):
                    cursor.execute(f"INSERT INTO {database_name}.{table_name} VALUES {tuple(df.iloc[i])}")
                connection.commit()
                st.success(f"Data inserted into `{table_name}` successfully!")
            except Exception as e:
                st.error(f"Error inserting data: {e}")

            cursor.close()
            connection.close()
