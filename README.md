README: Fabric MySQL Automation
This project provides a Python script using the Fabric library to automate the installation of a MySQL server and the deployment of a specific database schema for a MoMo (Mobile Money) SMS Tracking System.

Project Overview
The script automates the following DevOps tasks:

Environment Setup: Updates system packages and installs mysql-server non-interactively.

File Orchestration: Transfers the SQL database dump from your local machine to the target server.

Database Deployment: Executes the SQL script to create the momo_sms_db database, its tables (Users, Transactions, Tags, etc.), and populates it with sample data.

Prerequisites
Python 3.x installed locally.

Fabric library installed: pip install fabric.

SSH access to the target machine (configured for 127.0.0.1 in the script).

A file named password.txt in the root directory containing your SSH password.

A file named momo_setup.sql containing your SQL dump.

File Structure
fabfile.py: The main automation script.

momo_setup.sql: The SQL script containing the MoMo database schema.

password.txt: (Ignored by Git) Contains the SSH password for the connection.

Usage
Prepare your SQL file: Save the SQL dump provided in your assignment as momo_setup.sql.

Run the script:

Bash
python3 fabfile.py
Verify: Log into your server and check the database:

Bash
sudo mysql -e "SHOW DATABASES; USE momo_sms_db; SHOW TABLES;"
Database Schema Details
The deployed database momo_sms_db includes:

users: Tracks individuals, businesses, and agents with KYC data.

transactions: Records transaction references, amounts, fees, and raw SMS data.

transaction_categories: Categorizes movements as inbound, outbound, or internal.

system_logs: Captures processing errors and "dead letter" SMS that failed to parse.
