Advanced Bank Management System (ABMS)

A console banking app written in Python (OOP) that keeps accounts, balances and transaction history in a MySQL 8 database. I built it as a database project, starting from an earlier version that stored everything in memory and text files and lost all data when the program closed.

Features
Open saving or current accounts (the PIN is stored as a SHA-256 hash, never as plain text)
Deposit, withdraw, transfer money, check balance, credit yearly interest
Saving accounts keep a minimum balance; current accounts have an overdraft limit
Every money operation is one database transaction: COMMIT if it works, ROLLBACK if anything fails
Mini statement (last 5 transactions) and account export to a text file
Database extras: 3 views, 4 stored procedures, 2 functions, 3 triggers, 5 indexes, 32 practice queries and 14 reports
Technologies
Python 3.9+
mysql-connector-python
MySQL 8+ (MySQL Workbench for running the scripts)
Project structure
abms-bank-database/
├── app/                  Python code
│   ├── main.py           console menu
│   ├── models.py         Account, SavingAccount, CurrentAccount, BankError
│   ├── operations.py     open account, deposit, withdraw, transfer, interest
│   ├── transactions.py   history, mini statement, save/read account file
│   └── database.py       MySQL connection and the transaction() helper
├── database/             SQL scripts 00 to 11
├── documentation/        requirements, database design, ER diagram
├── bank_records/         exported account files
├── requirements.txt
└── README.md
Database design

Seven tables: branches, customers, account_types, transaction_types, accounts, transactions, account_audit.

accounts is the centre table. It links to customers, branches and account_types. Every money movement is a row in transactions, and a trigger writes status changes to account_audit. Column details and the ER diagram are in the documentation/ folder.

Object-oriented design
Encapsulation: the balance and PIN hash are private inside the account object
Inheritance: SavingAccount and CurrentAccount extend Account
Polymorphism: available_funds() behaves differently for each account type
Exception handling: BankError is raised for a wrong PIN, low funds or a frozen account
Setup
1. Create the database

Open MySQL Workbench and run these files from the database folder, each one once, in this order:

01_create_database.sql
02_create_tables.sql
03_insert_data.sql
05_views.sql
07_functions.sql
06_procedures.sql
08_triggers.sql
09_indexes.sql

Run the whole file each time (lightning bolt, or Ctrl+Shift+Enter). 04_queries.sql, 10_reports.sql and 11_transactions_demo.sql are for practice and can be run any time after that.

Or do everything in one go from the command line:

cd database
mysql -u root -p < 00_run_all.sql
2. Install the Python package
pip install -r requirements.txt
3. Set your MySQL password and run the app

Windows PowerShell:

$env:ABMS_DB_PASSWORD = "your_password"
cd app
python main.py

Linux / macOS:

export ABMS_DB_PASSWORD="your_password"
cd app
python main.py

Other settings you can change the same way: ABMS_DB_HOST, ABMS_DB_PORT, ABMS_DB_USER, ABMS_DB_NAME. The password is read from the environment, so it is never stored in the code.

Sample logins (sample data only)
Account	PIN	Type
1001	1111	Saving
1002	2222	Saving
1003	3333	Current
1007	7777	Current
1011	9999	Frozen

The sample data has 12 accounts in total (1001 to 1012).

Try it
Run python main.py and choose option 2 (Deposit): account 1001, amount 500
In MySQL Workbench run:
sql
USE abms_db;
SELECT * FROM transactions WHERE account_no = 1001 ORDER BY txn_id DESC;

The new deposit appears as the top row, which shows the app is saving to the database.

More sample queries:

sql
SELECT account_no, full_name, balance FROM vw_account_overview ORDER BY balance DESC LIMIT 5;
CALL sp_transfer(1002, 1001, 1500.00);
SELECT * FROM vw_monthly_summary;
Common problems
Duplicate entry error (1062): 03_insert_data.sql was run more than once. Run it only once after creating the tables.
Table doesn't exist (1146): 01_create_database.sql was run again, which deletes everything in the database. Run 02 and 03 again.
Access denied for user 'root': the password is wrong, or ABMS_DB_PASSWORD was not set in that terminal window.
Syntax error (1064): a semicolon is missing at the end of a statement.
Future improvements

Customer and admin login, loans and EMI, a web or GUI front end, monthly interest as a scheduled MySQL EVENT, salted PIN hashing (PBKDF2 or bcrypt), and statement export to PDF.

Author

Gayathri Bhavani Muniganti
