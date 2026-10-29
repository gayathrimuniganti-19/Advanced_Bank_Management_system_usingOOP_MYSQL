# Advanced Bank Management System – Python OOP + MySQL

A console banking app written with Python OOP. Accounts, balances and transaction history are stored in a MySQL 8 database. Made by a team of three: account management, banking operations, and transactions & database.

## Features
- Open saving / current accounts (PIN stored as a SHA-256 hash, never plain text)
- Deposit, withdraw, transfer, balance check, yearly interest
- Saving accounts keep a minimum balance; current accounts have an overdraft limit
- Every money operation is one database transaction (COMMIT or ROLLBACK)
- Mini statement and account export to a text file
- SQL extras: views, stored procedures, functions, triggers, cursor, indexes, 32 practice queries, 14 reports

## Technologies
Python 3.9+, `mysql-connector-python`, MySQL 8+

## Folder structure
```
abms-bank-database/
├── app/                      Python code (models.py, operations.py, transactions.py, database.py, main.py)
├── bank_records/             exported account files
├── database/                 SQL scripts 00–11
├── documentation/            requirements.md, database-design.md, er-diagram.md
├── requirements.txt
└── README.md
```

## Database structure
7 tables: `branches`, `customers`, `account_types`, `transaction_types`, `accounts`, `transactions`, `account_audit`. Details and the ER diagram are in `documentation/`.

## Installation
1. Install MySQL 8+ and make sure the server is running.
2. `pip install -r requirements.txt`
3. Create the database (see below).
4. Set your MySQL password and start the app:
   ```
   # Windows PowerShell
   $env:ABMS_DB_PASSWORD = "your_password"
   # Linux / macOS
   export ABMS_DB_PASSWORD="your_password"

   cd app
   python main.py
   ```
   Other settings you can override: `ABMS_DB_HOST`, `ABMS_DB_PORT`, `ABMS_DB_USER`, `ABMS_DB_NAME`.

## How to execute the SQL files
Fastest, from the command line:
```
cd database
mysql -u root -p < 00_run_all.sql
```
Or in MySQL Workbench, open and run these in order: `01`, `02`, `03`, `05`, `07`, `06`, `08`, `09`. Then `04`, `10`, `11` whenever you want to practise.
Re-running `01` deletes and rebuilds the whole database.

## Sample logins (sample data only)
Account `1001` PIN `1111`, `1002` -> `2222`, `1003` (current) -> `3333`, `1004` -> `4444`, `1005` -> `5555`, `1006` -> `6666`, `1007` (current) -> `7777`, `1008` -> `8888`, `1009` -> `1357`, `1010` -> `2468`, `1011` (frozen) -> `9999`, `1012` -> `1928`.

## Sample queries
```sql
SELECT account_no, full_name, balance FROM vw_account_overview ORDER BY balance DESC LIMIT 5;
CALL sp_transfer(1002, 1001, 1500.00);
SELECT * FROM vw_monthly_summary;
```

## Future enhancements
Customer / admin login, loans and EMI, a web or GUI front end, monthly interest as a scheduled MySQL EVENT, salted PIN hashing (PBKDF2/bcrypt), statement PDF export.
