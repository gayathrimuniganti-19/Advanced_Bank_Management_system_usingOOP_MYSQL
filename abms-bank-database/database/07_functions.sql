-- 07_functions.sql : reusable calculations that return one value
USE abms_db;
DROP FUNCTION IF EXISTS fn_available_funds;
DROP FUNCTION IF EXISTS fn_balance_category;
DELIMITER $$

-- Money the customer can still withdraw: balance + overdraft - minimum balance
CREATE FUNCTION fn_available_funds(p_acc INT)
RETURNS DECIMAL(14,2)
READS SQL DATA
BEGIN
  DECLARE v_funds DECIMAL(14,2);
  SELECT a.balance + t.overdraft_limit - t.min_balance
    INTO v_funds
    FROM accounts a
    JOIN account_types t ON t.type_id = a.type_id
   WHERE a.account_no = p_acc;
  RETURN v_funds;
END$$

-- Labels a balance as LOW / MEDIUM / HIGH
CREATE FUNCTION fn_balance_category(p_balance DECIMAL(14,2))
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
  RETURN CASE
           WHEN p_balance < 20000 THEN 'LOW'
           WHEN p_balance < 75000 THEN 'MEDIUM'
           ELSE 'HIGH'
         END;
END$$

DELIMITER ;
