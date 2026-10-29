-- 11_transactions_demo.sql : COMMIT, ROLLBACK and SAVEPOINT by hand
-- A transaction groups steps so they all happen, or none happen.
USE abms_db;

-- 1) COMMIT: move 1000 from account 1001 to 1002 and keep it
START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_no = 1001;
UPDATE accounts SET balance = balance + 1000 WHERE account_no = 1002;
SELECT account_no, balance FROM accounts WHERE account_no IN (1001, 1002);
COMMIT;

-- 2) ROLLBACK: undo a mistake
START TRANSACTION;
UPDATE accounts SET balance = balance - 5000 WHERE account_no = 1001;
SELECT account_no, balance FROM accounts WHERE account_no = 1001;   -- shows the lower balance
ROLLBACK;
SELECT account_no, balance FROM accounts WHERE account_no = 1001;   -- back to the old balance

-- 3) SAVEPOINT: undo only part of the work
START TRANSACTION;
UPDATE accounts SET balance = balance - 500 WHERE account_no = 1004;   -- step 1 (keep)
SAVEPOINT after_step1;
UPDATE accounts SET balance = balance - 500 WHERE account_no = 1006;   -- step 2 (oops)
ROLLBACK TO SAVEPOINT after_step1;                                      -- undo step 2 only
COMMIT;                                                                 -- step 1 is saved
SELECT account_no, balance FROM accounts WHERE account_no IN (1004, 1006);

-- 4) Trying the stored procedures and triggers
CALL sp_deposit(1001, 2500.00);
CALL sp_transfer(1002, 1001, 1500.00);
-- CALL sp_withdraw(1008, 999999);   -- uncomment: fails with "insufficient balance" and rolls back
UPDATE accounts SET status = 'FROZEN' WHERE account_no = 1012;
SELECT * FROM account_audit;               -- written by the trigger
UPDATE accounts SET status = 'ACTIVE' WHERE account_no = 1012;
SELECT fn_available_funds(1003) AS available_current, fn_balance_category(1003) AS level;
