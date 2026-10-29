-- 06_procedures.sql : bank operations as stored procedures (each one is a single safe transaction)
-- Needs 07_functions.sql for fn_available_funds. Run 07 first if you run files one by one.
USE abms_db;
DROP PROCEDURE IF EXISTS sp_deposit;
DROP PROCEDURE IF EXISTS sp_withdraw;
DROP PROCEDURE IF EXISTS sp_transfer;
DROP PROCEDURE IF EXISTS sp_apply_interest;
DELIMITER $$

CREATE PROCEDURE sp_deposit(IN p_acc INT, IN p_amount DECIMAL(14,2))
BEGIN
  DECLARE v_balance DECIMAL(14,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  SELECT balance INTO v_balance FROM accounts WHERE account_no = p_acc FOR UPDATE;
  IF v_balance IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
  END IF;
  IF p_amount <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deposit amount must be greater than 0';
  END IF;
  UPDATE accounts SET balance = balance + p_amount WHERE account_no = p_acc;
  INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, remarks)
  SELECT p_acc, txn_type_id, p_amount, v_balance + p_amount, 'Deposit via procedure'
    FROM transaction_types WHERE type_name = 'DEPOSIT';
  COMMIT;
END$$

CREATE PROCEDURE sp_withdraw(IN p_acc INT, IN p_amount DECIMAL(14,2))
BEGIN
  DECLARE v_balance DECIMAL(14,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  SELECT balance INTO v_balance FROM accounts WHERE account_no = p_acc FOR UPDATE;
  IF v_balance IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
  END IF;
  IF p_amount <= 0 OR p_amount > fn_available_funds(p_acc) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid amount or insufficient balance';
  END IF;
  UPDATE accounts SET balance = balance - p_amount WHERE account_no = p_acc;
  INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, remarks)
  SELECT p_acc, txn_type_id, p_amount, v_balance - p_amount, 'Withdrawal via procedure'
    FROM transaction_types WHERE type_name = 'WITHDRAW';
  COMMIT;
END$$

CREATE PROCEDURE sp_transfer(IN p_from INT, IN p_to INT, IN p_amount DECIMAL(14,2))
BEGIN
  DECLARE v_from_bal DECIMAL(14,2);
  DECLARE v_to_bal   DECIMAL(14,2);
  DECLARE v_lo_bal   DECIMAL(14,2);
  DECLARE v_hi_bal   DECIMAL(14,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  IF p_from = p_to THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot transfer to the same account';
  END IF;

  START TRANSACTION;
  -- lock both rows, always the smaller account number first, so two opposite
  -- transfers at the same time cannot deadlock each other
  SELECT balance INTO v_lo_bal FROM accounts WHERE account_no = LEAST(p_from, p_to)    FOR UPDATE;
  SELECT balance INTO v_hi_bal FROM accounts WHERE account_no = GREATEST(p_from, p_to) FOR UPDATE;
  IF p_from < p_to THEN
    SET v_from_bal = v_lo_bal, v_to_bal = v_hi_bal;
  ELSE
    SET v_from_bal = v_hi_bal, v_to_bal = v_lo_bal;
  END IF;

  IF v_from_bal IS NULL OR v_to_bal IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
  END IF;
  IF p_amount <= 0 OR p_amount > fn_available_funds(p_from) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid amount or insufficient balance';
  END IF;

  UPDATE accounts SET balance = balance - p_amount WHERE account_no = p_from;
  UPDATE accounts SET balance = balance + p_amount WHERE account_no = p_to;

  INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, counterparty_acc, remarks)
  SELECT p_from, txn_type_id, p_amount, v_from_bal - p_amount, p_to, 'Transfer out'
    FROM transaction_types WHERE type_name = 'TRANSFER_OUT';
  INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, counterparty_acc, remarks)
  SELECT p_to, txn_type_id, p_amount, v_to_bal + p_amount, p_from, 'Transfer in'
    FROM transaction_types WHERE type_name = 'TRANSFER_IN';
  COMMIT;
END$$

-- Cursor example: credit one year of interest to every ACTIVE interest-bearing account
CREATE PROCEDURE sp_apply_interest()
BEGIN
  DECLARE v_done     TINYINT DEFAULT 0;
  DECLARE v_acc      INT;
  DECLARE v_balance  DECIMAL(14,2);
  DECLARE v_rate     DECIMAL(4,2);
  DECLARE v_interest DECIMAL(14,2);
  DECLARE v_type     TINYINT;
  DECLARE cur CURSOR FOR
    SELECT a.account_no, a.balance, t.interest_rate
    FROM accounts a JOIN account_types t ON t.type_id = a.type_id
    WHERE a.status = 'ACTIVE' AND t.interest_rate > 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  SELECT txn_type_id INTO v_type FROM transaction_types WHERE type_name = 'INTEREST';

  START TRANSACTION;
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_acc, v_balance, v_rate;
    IF v_done = 1 THEN LEAVE read_loop; END IF;
    SET v_interest = ROUND(v_balance * v_rate / 100, 2);
    IF v_interest > 0 THEN
      UPDATE accounts SET balance = balance + v_interest WHERE account_no = v_acc;
      INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, remarks)
      VALUES (v_acc, v_type, v_interest, v_balance + v_interest, 'Annual interest credit');
    END IF;
  END LOOP;
  CLOSE cur;
  COMMIT;
END$$

DELIMITER ;
