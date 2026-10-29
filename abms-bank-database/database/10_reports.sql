-- 10_reports.sql : business reports
USE abms_db;

-- R1. Total records in each main table
SELECT 'customers' AS table_name, COUNT(*) AS total FROM customers
UNION ALL SELECT 'accounts',     COUNT(*) FROM accounts
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;

-- R2. Monthly report: number and value of completed transactions
SELECT DATE_FORMAT(txn_time, '%Y-%m') AS month, COUNT(*) AS txns, SUM(amount) AS total_value
FROM transactions WHERE status = 'COMPLETED'
GROUP BY month ORDER BY month;

-- R3. Top 5 customers by total balance
SELECT c.full_name, SUM(a.balance) AS total_balance
FROM customers c JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_balance DESC LIMIT 5;

-- R4. Highest and lowest balance, with the account owner
(SELECT 'HIGHEST' AS kind, a.account_no, c.full_name, a.balance
 FROM accounts a JOIN customers c ON c.customer_id = a.customer_id
 ORDER BY a.balance DESC LIMIT 1)
UNION ALL
(SELECT 'LOWEST', a.account_no, c.full_name, a.balance
 FROM accounts a JOIN customers c ON c.customer_id = a.customer_id
 ORDER BY a.balance ASC LIMIT 1);

-- R5. Second highest balance (two ways)
SELECT DISTINCT balance AS second_highest FROM accounts ORDER BY balance DESC LIMIT 1 OFFSET 1;
SELECT MAX(balance) AS second_highest FROM accounts WHERE balance < (SELECT MAX(balance) FROM accounts);

-- R6. City-wise summary of branches' accounts
SELECT b.city, COUNT(a.account_no) AS accounts, COALESCE(SUM(a.balance), 0) AS total_balance
FROM branches b LEFT JOIN accounts a ON a.branch_id = b.branch_id
GROUP BY b.city ORDER BY total_balance DESC;

-- R7. Account-type-wise summary
SELECT t.type_name, COUNT(*) AS accounts, SUM(a.balance) AS total_balance, AVG(a.balance) AS avg_balance
FROM accounts a JOIN account_types t ON t.type_id = a.type_id
GROUP BY t.type_name;

-- R8. Monthly deposit inflow (money coming into the bank from outside)
SELECT DATE_FORMAT(x.txn_time, '%Y-%m') AS month, SUM(x.amount) AS deposits
FROM transactions x JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
WHERE tt.type_name = 'DEPOSIT' AND x.status = 'COMPLETED'
GROUP BY month ORDER BY month;

-- R9. Interest paid out per month (the bank's cost)
SELECT DATE_FORMAT(x.txn_time, '%Y-%m') AS month, SUM(x.amount) AS interest_paid
FROM transactions x JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
WHERE tt.type_name = 'INTEREST'
GROUP BY month ORDER BY month;

-- R10. Pending transactions
SELECT x.txn_id, x.account_no, x.amount, x.remarks, x.txn_time FROM transactions x WHERE x.status = 'PENDING';

-- R11. Completed vs pending vs failed
SELECT status, COUNT(*) AS txns, SUM(amount) AS total_amount FROM transactions GROUP BY status;

-- R12. Most frequently used services
SELECT tt.type_name, COUNT(*) AS times_used
FROM transactions x JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
GROUP BY tt.type_name ORDER BY times_used DESC;

-- R13. Branch performance: accounts and transactions handled
-- (balances are not summed here: joining transactions would repeat each account's balance)
SELECT b.branch_name, COUNT(DISTINCT a.account_no) AS accounts,
       COUNT(x.txn_id) AS transactions
FROM branches b
JOIN accounts a ON a.branch_id = b.branch_id
LEFT JOIN transactions x ON x.account_no = a.account_no
GROUP BY b.branch_id, b.branch_name
ORDER BY transactions DESC;

-- R14. Customers who referred the most new customers
SELECT r.full_name, COUNT(*) AS referrals
FROM customers c JOIN customers r ON r.customer_id = c.referred_by
GROUP BY r.customer_id, r.full_name ORDER BY referrals DESC;
