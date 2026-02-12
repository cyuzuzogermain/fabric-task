import os
from fabric import Connection

# 1. Setup Connection Details
with open('password.txt') as f:
    password = f.read().strip()

connection = Connection(
    host='127.0.0.1', 
    user='waka', 
    connect_kwargs={'password': password}
)

# Define file paths
local_sql_file = 'momo_setup.sql'
remote_sql_path = '/tmp/momo_setup.sql'

def setup_database():
    """
    1. Installs MySQL Server
    2. Creates the database
    3. Runs the SQL dump
    """
    print("--- Starting MySQL Installation ---")
    # Update packages and install mysql-server
    # 'sudo' is used here; Fabric will prompt for password or use the one in connect_kwargs
    connection.sudo('apt-get update -y')
    connection.sudo('DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server')

    print("--- Configuring Database ---")
    # Ensure MySQL service is running
    connection.sudo('systemctl start mysql')

    # Create the SQL file locally first (if it doesn't exist)
    # In a real scenario, you'd save your provided SQL into 'momo_setup.sql'
    
    # Upload the SQL dump to the server
    print(f"--- Uploading {local_sql_file} to server ---")
    connection.put(local_sql_file, remote=remote_sql_path)

    # Execute the SQL script
    # Note: On many fresh installs, 'sudo mysql' allows root access without a password
    print("--- Executing SQL Dump ---")
    connection.sudo(f'mysql < {remote_sql_path}')

    print("--- Activity Completed Successfully ---")

if __name__ == "__main__":
    # Ensure the local SQL file exists before running
    if os.path.exists(local_sql_file):
        setup_database()
    else:
        print(f"Error: Please save your SQL dump as '{local_sql_file}' in this directory.")
