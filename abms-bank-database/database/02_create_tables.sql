-- 02_create_tables.sql  (MySQL 8+)
USE abms_db;

-- Master / lookup tables ------------------------------------------------
CREATE TABLE branches (
  branch_id   INT          NOT NULL AUTO_INCREMENT,
  branch_name VARCHAR(80)  NOT NULL,
  city        VARCHAR(50)  NOT NULL,
  ifsc_code   CHAR(11)     NOT NULL,
  PRIMARY KEY (branch_id),
  UNIQUE KEY uq_branches_ifsc (ifsc_code)
) ENGINE=InnoDB;

CREATE TABLE account_types (
  type_id         TINYINT       NOT NULL AUTO_INCREMENT,
  type_name       VARCHAR(20)   NOT NULL,
  interest_rate   DECIMAL(4,2)  NOT NULL DEFAULT 0.00,
  overdraft_limit DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  min_balance     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (type_id),
  UNIQUE KEY uq_account_types_name (type_name),
  CONSTRAINT chk_acctype_rate CHECK (interest_rate >= 0),
  CONSTRAINT chk_acctype_od   CHECK (overdraft_limit >= 0),
  CONSTRAINT chk_acctype_min  CHECK (min_balance >= 0)
) ENGINE=InnoDB;

CREATE TABLE transaction_types (
  txn_type_id TINYINT     NOT NULL AUTO_INCREMENT,
  type_name   VARCHAR(20) NOT NULL,
  direction   ENUM('CREDIT','DEBIT') NOT NULL,
  PRIMARY KEY (txn_type_id),
  UNIQUE KEY uq_txn_types_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT          NOT NULL AUTO_INCREMENT,
  full_name   VARCHAR(100) NOT NULL,
  phone       CHAR(10)     NOT NULL,
  email       VARCHAR(100) NULL,
  city        VARCHAR(50)  NULL,
  referred_by INT          NULL,                      -- self reference
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customers_phone (phone),
  UNIQUE KEY uq_customers_email (email),
  CONSTRAINT chk_customers_phone CHECK (phone REGEXP '^[0-9]{10}$'),
  CONSTRAINT fk_customers_referrer FOREIGN KEY (referred_by)
    REFERENCES customers (customer_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Core tables -----------------------------------------------------------
CREATE TABLE accounts (
  account_no  INT           NOT NULL AUTO_INCREMENT,
  customer_id INT           NOT NULL,
  branch_id   INT           NOT NULL,
  type_id     TINYINT       NOT NULL,
  pin_hash    CHAR(64)      NOT NULL,                 -- SHA-256 hex, never the plain PIN
  balance     DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  status      ENUM('ACTIVE','FROZEN','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  opened_on   DATE          NOT NULL DEFAULT (CURRENT_DATE),
  PRIMARY KEY (account_no),
  CONSTRAINT fk_accounts_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT fk_accounts_branch   FOREIGN KEY (branch_id)   REFERENCES branches (branch_id),
  CONSTRAINT fk_accounts_type     FOREIGN KEY (type_id)     REFERENCES account_types (type_id)
) ENGINE=InnoDB AUTO_INCREMENT=1001;

CREATE TABLE transactions (
  txn_id           BIGINT        NOT NULL AUTO_INCREMENT,
  account_no       INT           NOT NULL,
  txn_type_id      TINYINT       NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  balance_after    DECIMAL(14,2) NOT NULL,
  counterparty_acc INT           NULL,                -- other account in a transfer
  status           ENUM('COMPLETED','PENDING','FAILED') NOT NULL DEFAULT 'COMPLETED',
  remarks          VARCHAR(200)  NULL,
  txn_time         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (txn_id),
  CONSTRAINT chk_txn_amount CHECK (amount > 0),
  CONSTRAINT fk_txn_account  FOREIGN KEY (account_no)       REFERENCES accounts (account_no),
  CONSTRAINT fk_txn_type     FOREIGN KEY (txn_type_id)      REFERENCES transaction_types (txn_type_id),
  CONSTRAINT fk_txn_counter  FOREIGN KEY (counterparty_acc) REFERENCES accounts (account_no)
) ENGINE=InnoDB;

-- Filled automatically by a trigger (08_triggers.sql)
CREATE TABLE account_audit (
  audit_id   INT         NOT NULL AUTO_INCREMENT,
  account_no INT         NOT NULL,
  old_status VARCHAR(10) NOT NULL,
  new_status VARCHAR(10) NOT NULL,
  changed_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (audit_id),
  CONSTRAINT fk_audit_account FOREIGN KEY (account_no) REFERENCES accounts (account_no)
) ENGINE=InnoDB;
