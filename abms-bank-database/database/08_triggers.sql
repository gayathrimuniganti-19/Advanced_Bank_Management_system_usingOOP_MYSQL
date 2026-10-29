-- 08_triggers.sql : rules the database enforces by itself, whoever writes to it
USE abms_db;
DROP TRIGGER IF EXISTS trg_accounts_before_update;
DROP TRIGGER IF EXISTS trg_accounts_after_update;
DROP TRIGGER IF EXISTS trg_transactions_before_insert;
DELIMITER $$

-- Balance may never fall below the allowed overdraft (0 for SAVING, 50000 for CURRENT)
CREATE TRIGGER trg_accounts_before_update
BEFORE UPDATE ON accounts
FOR EACH ROW
BEGIN
  DECLARE v_overdraft DECIMAL(12,2);
  SELECT overdraft_limit INTO v_overdraft FROM account_types WHERE type_id = NEW.type_id;
  IF NEW.balance < -v_overdraft THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Balance would go below the allowed overdraft limit';
  END IF;
END$$

-- Keep a history of status changes (ACTIVE -> FROZEN etc.)
CREATE TRIGGER trg_accounts_after_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO account_audit (account_no, old_status, new_status)
    VALUES (OLD.account_no, OLD.status, NEW.status);
  END IF;
END$$

-- Only ACTIVE accounts may get new COMPLETED/PENDING transactions
CREATE TRIGGER trg_transactions_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(10);
  SELECT status INTO v_status FROM accounts WHERE account_no = NEW.account_no;
  IF v_status <> 'ACTIVE' AND NEW.status <> 'FAILED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account is not ACTIVE';
  END IF;
END$$

DELIMITER ;
