-- 09_indexes.sql : run once, after 02/03.  PK, UNIQUE and FK columns are already indexed by InnoDB.
USE abms_db;

-- Statement / mini-statement: WHERE account_no = ? ORDER BY txn_time DESC
CREATE INDEX idx_txn_account_time ON transactions (account_no, txn_time);

-- Monthly reports and date-range filters
CREATE INDEX idx_txn_time ON transactions (txn_time);

-- Pending / completed reports
CREATE INDEX idx_txn_status_time ON transactions (status, txn_time);

-- City-wise customer lookups
CREATE INDEX idx_customers_city ON customers (city);

-- "Active accounts with high balance" style queries
CREATE INDEX idx_accounts_status_balance ON accounts (status, balance);

SHOW INDEX FROM transactions;

-- EXPLAIN shows whether MySQL uses an index (look at the "key" and "rows" columns)
EXPLAIN SELECT txn_id, amount, txn_time
FROM transactions
WHERE account_no = 1001
ORDER BY txn_time DESC
LIMIT 5;

EXPLAIN SELECT COUNT(*) FROM transactions WHERE status = 'PENDING' AND txn_time >= '2026-06-01';
