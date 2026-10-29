-- 05_views.sql : views hide joins and give reports a simple name to query
USE abms_db;

CREATE OR REPLACE VIEW vw_account_overview AS
SELECT a.account_no, c.full_name, t.type_name AS account_type,
       b.branch_name, b.city AS branch_city, a.balance, a.status, a.opened_on
FROM accounts a
JOIN customers     c ON c.customer_id = a.customer_id
JOIN account_types t ON t.type_id     = a.type_id
JOIN branches      b ON b.branch_id   = a.branch_id;

CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT DATE_FORMAT(x.txn_time, '%Y-%m') AS txn_month,
       tt.type_name,
       COUNT(*)      AS txn_count,
       SUM(x.amount) AS total_amount
FROM transactions x
JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
WHERE x.status = 'COMPLETED'
GROUP BY DATE_FORMAT(x.txn_time, '%Y-%m'), tt.type_name;

CREATE OR REPLACE VIEW vw_customer_portfolio AS
SELECT c.customer_id, c.full_name, c.city,
       COUNT(a.account_no)           AS accounts_held,
       COALESCE(SUM(a.balance), 0)   AS total_balance
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.city;
