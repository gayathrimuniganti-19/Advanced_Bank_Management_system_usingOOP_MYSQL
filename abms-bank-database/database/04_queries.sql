-- 04_queries.sql : 32 practice queries, each with a plain-language explanation
USE abms_db;

-- 1. SELECT specific columns (avoid SELECT * in real projects)
SELECT customer_id, full_name, city FROM customers;

-- 2. WHERE: customers living in Hyderabad
SELECT full_name, phone FROM customers WHERE city = 'Hyderabad';

-- 3. DISTINCT: list each city only once
SELECT DISTINCT city FROM customers ORDER BY city;

-- 4. ORDER BY: richest accounts first
SELECT account_no, balance FROM accounts ORDER BY balance DESC;

-- 5. LIMIT: the 5 highest balances
SELECT account_no, balance FROM accounts ORDER BY balance DESC LIMIT 5;

-- 6. LIMIT + OFFSET: page 2 of the account list (5 per page)
SELECT account_no, balance FROM accounts ORDER BY account_no LIMIT 5 OFFSET 5;

-- 7. LIKE: names starting with S
SELECT full_name FROM customers WHERE full_name LIKE 'S%';

-- 8. BETWEEN: balances from 20,000 to 60,000
SELECT account_no, balance FROM accounts WHERE balance BETWEEN 20000 AND 60000;

-- 9. IN: customers from two cities
SELECT full_name, city FROM customers WHERE city IN ('Chennai', 'Pune');

-- 10. NOT IN: customers outside Hyderabad
SELECT full_name, city FROM customers WHERE city NOT IN ('Hyderabad');

-- 11. IS NULL: customers nobody referred
SELECT full_name FROM customers WHERE referred_by IS NULL;

-- 12. IS NOT NULL: customers who gave an email
SELECT full_name, email FROM customers WHERE email IS NOT NULL;

-- 13. AND / OR / NOT: active savings-size balances, excluding frozen accounts
SELECT account_no, balance, status
FROM accounts
WHERE (balance > 50000 OR balance < 10000) AND NOT status = 'FROZEN';

-- 14. Aggregate functions over all accounts
SELECT COUNT(*) AS total_accounts, SUM(balance) AS total_money,
       AVG(balance) AS average_balance, MIN(balance) AS lowest, MAX(balance) AS highest
FROM accounts;

-- 15. GROUP BY: accounts and average balance per account type
SELECT t.type_name, COUNT(*) AS accounts, ROUND(AVG(a.balance), 2) AS avg_balance
FROM accounts a
JOIN account_types t ON t.type_id = a.type_id
GROUP BY t.type_name;

-- 16. HAVING: cities where customers together hold more than 100,000
SELECT c.city, SUM(a.balance) AS city_total
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
GROUP BY c.city
HAVING SUM(a.balance) > 100000;

-- 17. INNER JOIN: account with owner, type and branch
SELECT a.account_no, c.full_name, t.type_name, b.branch_name, a.balance
FROM accounts a
INNER JOIN customers     c ON c.customer_id = a.customer_id
INNER JOIN account_types t ON t.type_id     = a.type_id
INNER JOIN branches      b ON b.branch_id   = a.branch_id;

-- 18. LEFT JOIN: accounts that have never had a transaction
SELECT a.account_no, c.full_name
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN transactions x ON x.account_no = a.account_no
WHERE x.txn_id IS NULL;

-- 19. RIGHT JOIN: every branch, even those with no accounts
SELECT b.branch_name, COUNT(a.account_no) AS accounts
FROM accounts a
RIGHT JOIN branches b ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name
ORDER BY accounts DESC;

-- 20. SELF JOIN: who referred whom
SELECT c.full_name AS customer, r.full_name AS referred_by
FROM customers c
JOIN customers r ON r.customer_id = c.referred_by;

-- 21. Subquery: accounts above the overall average balance
SELECT account_no, balance
FROM accounts
WHERE balance > (SELECT AVG(balance) FROM accounts);

-- 22. Correlated subquery: accounts above the average of their OWN type
SELECT a.account_no, a.type_id, a.balance
FROM accounts a
WHERE a.balance > (SELECT AVG(b.balance) FROM accounts b WHERE b.type_id = a.type_id);

-- 23. EXISTS: customers who made at least one withdrawal
SELECT c.full_name
FROM customers c
WHERE EXISTS (
  SELECT 1
  FROM accounts a
  JOIN transactions x ON x.account_no = a.account_no
  JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
  WHERE a.customer_id = c.customer_id AND tt.type_name = 'WITHDRAW'
);

-- 24. NOT EXISTS: accounts that never received a completed deposit
SELECT a.account_no
FROM accounts a
WHERE NOT EXISTS (
  SELECT 1
  FROM transactions x
  JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
  WHERE x.account_no = a.account_no AND tt.type_name = 'DEPOSIT' AND x.status = 'COMPLETED'
);

-- 25. CASE: label each balance
SELECT account_no, balance,
       CASE WHEN balance >= 75000 THEN 'HIGH'
            WHEN balance >= 20000 THEN 'MEDIUM'
            ELSE 'LOW' END AS balance_level
FROM accounts;

-- 26. COALESCE: show a default when remarks or email is NULL
SELECT txn_id, COALESCE(remarks, 'No remarks') AS remarks FROM transactions LIMIT 10;
SELECT full_name, COALESCE(email, 'not provided') AS email FROM customers;

-- 27. UNION: every city we know (customers + branches), duplicates removed
SELECT city FROM customers UNION SELECT city FROM branches;

-- 28. UNION ALL: credits and debits stacked into one list (duplicates kept)
SELECT account_no, amount, 'CREDIT' AS side
FROM transactions x JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
WHERE tt.direction = 'CREDIT' AND x.status = 'COMPLETED'
UNION ALL
SELECT account_no, amount, 'DEBIT'
FROM transactions x JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
WHERE tt.direction = 'DEBIT' AND x.status = 'COMPLETED';

-- 29. Date functions: transactions per month
SELECT DATE_FORMAT(txn_time, '%Y-%m') AS month, COUNT(*) AS txns
FROM transactions GROUP BY month ORDER BY month;

-- 30. Count of transactions per type
SELECT tt.type_name, COUNT(*) AS times_used
FROM transactions x
JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
GROUP BY tt.type_name
ORDER BY times_used DESC;

-- 31. Transfers with sender and receiver names (joins accounts + customers twice)
SELECT x.txn_time, cs.full_name AS sender, cr.full_name AS receiver, x.amount
FROM transactions x
JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id AND tt.type_name = 'TRANSFER_OUT'
JOIN accounts  s  ON s.account_no  = x.account_no
JOIN customers cs ON cs.customer_id = s.customer_id
JOIN accounts  r  ON r.account_no  = x.counterparty_acc
JOIN customers cr ON cr.customer_id = r.customer_id
ORDER BY x.txn_time;

-- 32. Subquery in FROM: customer with the highest total withdrawals
SELECT w.full_name, w.total_withdrawn
FROM (
  SELECT c.full_name, SUM(x.amount) AS total_withdrawn
  FROM transactions x
  JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
  JOIN accounts a  ON a.account_no  = x.account_no
  JOIN customers c ON c.customer_id = a.customer_id
  WHERE tt.type_name = 'WITHDRAW' AND x.status = 'COMPLETED'
  GROUP BY c.customer_id, c.full_name
) AS w
ORDER BY w.total_withdrawn DESC
LIMIT 1;
