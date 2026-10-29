# Database design – `abms_db` (MySQL 8+)

| Table | Purpose |
|---|---|
| branches | Bank branches (master) |
| customers | People who own accounts; `referred_by` points to another customer |
| account_types | SAVING / CURRENT rules: interest rate, overdraft limit, minimum balance |
| transaction_types | DEPOSIT, WITHDRAW, TRANSFER_OUT, TRANSFER_IN, INTEREST with CREDIT/DEBIT direction |
| accounts | One row per account: owner, branch, type, hashed PIN, balance, status |
| transactions | History of every money movement |
| account_audit | Status changes, filled by a trigger |

## branches
- branch_id INT PK AUTO_INCREMENT
- branch_name VARCHAR(80) NOT NULL
- city VARCHAR(50) NOT NULL
- ifsc_code CHAR(11) NOT NULL UNIQUE

## customers
- customer_id INT PK AUTO_INCREMENT
- full_name VARCHAR(100) NOT NULL
- phone CHAR(10) NOT NULL UNIQUE, CHECK 10 digits
- email VARCHAR(100) UNIQUE (NULL allowed)
- city VARCHAR(50)
- referred_by INT FK -> customers.customer_id (ON DELETE SET NULL)
- created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP

## account_types
- type_id TINYINT PK AUTO_INCREMENT
- type_name VARCHAR(20) NOT NULL UNIQUE
- interest_rate DECIMAL(4,2) NOT NULL DEFAULT 0, CHECK >= 0
- overdraft_limit DECIMAL(12,2) NOT NULL DEFAULT 0, CHECK >= 0
- min_balance DECIMAL(12,2) NOT NULL DEFAULT 0, CHECK >= 0

## transaction_types
- txn_type_id TINYINT PK AUTO_INCREMENT
- type_name VARCHAR(20) NOT NULL UNIQUE
- direction ENUM('CREDIT','DEBIT') NOT NULL

## accounts
- account_no INT PK AUTO_INCREMENT (starts at 1001, like the original `last_acc_no = 1000`)
- customer_id INT NOT NULL FK -> customers
- branch_id INT NOT NULL FK -> branches
- type_id TINYINT NOT NULL FK -> account_types
- pin_hash CHAR(64) NOT NULL (SHA-256 of `account_no:pin`)
- balance DECIMAL(14,2) NOT NULL DEFAULT 0
- status ENUM('ACTIVE','FROZEN','CLOSED') NOT NULL DEFAULT 'ACTIVE'
- opened_on DATE NOT NULL DEFAULT (CURRENT_DATE)

## transactions
- txn_id BIGINT PK AUTO_INCREMENT
- account_no INT NOT NULL FK -> accounts
- txn_type_id TINYINT NOT NULL FK -> transaction_types
- amount DECIMAL(14,2) NOT NULL, CHECK > 0
- balance_after DECIMAL(14,2) NOT NULL
- counterparty_acc INT FK -> accounts (other side of a transfer)
- status ENUM('COMPLETED','PENDING','FAILED') NOT NULL DEFAULT 'COMPLETED'
- remarks VARCHAR(200)
- txn_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP

## account_audit
- audit_id INT PK AUTO_INCREMENT
- account_no INT NOT NULL FK -> accounts
- old_status, new_status VARCHAR(10) NOT NULL
- changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP

## Python <-> original code mapping
| Original (ABMS_OOP.py) | Now |
|---|---|
| `Account.last_acc_no` counter | `accounts.account_no` AUTO_INCREMENT |
| private `__balance`, `__pin` | `accounts.balance`, `accounts.pin_hash`; still private inside the object |
| `TransactionManager.history` dict | `transactions` table |
| `record_deposit / withdrawal / transfer / interest` | one `record(...)` with a transaction type |
| `save_account_info`, `read_account_info` | kept (files in `bank_records/`), data now read from MySQL |
