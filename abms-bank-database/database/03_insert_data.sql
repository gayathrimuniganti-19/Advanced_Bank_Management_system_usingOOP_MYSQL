-- 03_insert_data.sql : sample data (generated so balances match transaction history)
-- Sample PINs: account 1001=1111, 1002=2222, ... see README. PIN hash = SHA2('<account_no>:<pin>',256)
USE abms_db;

INSERT INTO branches (branch_name, city, ifsc_code) VALUES
  ('Madhapur', 'Hyderabad', 'ABMS0000101'),
  ('Banjara Hills', 'Hyderabad', 'ABMS0000102'),
  ('Secunderabad', 'Hyderabad', 'ABMS0000103'),
  ('T Nagar', 'Chennai', 'ABMS0000104'),
  ('Adyar', 'Chennai', 'ABMS0000105'),
  ('Koramangala', 'Bengaluru', 'ABMS0000106'),
  ('Indiranagar', 'Bengaluru', 'ABMS0000107'),
  ('Hinjewadi', 'Pune', 'ABMS0000108'),
  ('Kothrud', 'Pune', 'ABMS0000109'),
  ('Gachibowli', 'Hyderabad', 'ABMS0000110');

INSERT INTO account_types (type_name, interest_rate, overdraft_limit, min_balance) VALUES
  ('SAVING', 4.00, 0.00, 500.00),
  ('CURRENT', 0.00, 50000.00, 0.00);

INSERT INTO transaction_types (type_name, direction) VALUES
  ('DEPOSIT','CREDIT'),
  ('WITHDRAW','DEBIT'),
  ('TRANSFER_OUT','DEBIT'),
  ('TRANSFER_IN','CREDIT'),
  ('INTEREST','CREDIT');

INSERT INTO customers (customer_id, full_name, phone, email, city, referred_by) VALUES
  (1, 'Ravi Kumar', '9876500001', 'ravi.kumar@example.com', 'Hyderabad', NULL),
  (2, 'Sneha Reddy', '9876500002', 'sneha.reddy@example.com', 'Hyderabad', '1'),
  (3, 'Arjun Mehta', '9876500003', 'arjun.mehta@example.com', 'Bengaluru', '1'),
  (4, 'Priya Nair', '9876500004', 'priya.nair@example.com', 'Chennai', NULL),
  (5, 'Karthik Rao', '9876500005', 'karthik.rao@example.com', 'Pune', '2'),
  (6, 'Divya Sharma', '9876500006', 'divya.sharma@example.com', 'Hyderabad', '2'),
  (7, 'Mohammed Irfan', '9876500007', 'irfan.m@example.com', 'Hyderabad', '3'),
  (8, 'Lakshmi Iyer', '9876500008', 'lakshmi.iyer@example.com', 'Chennai', '4'),
  (9, 'Vikram Singh', '9876500009', 'vikram.singh@example.com', 'Pune', '5'),
  (10, 'Anitha Varma', '9876500010', 'anitha.varma@example.com', 'Bengaluru', '3'),
  (11, 'Suresh Babu', '9876500011', 'suresh.babu@example.com', 'Hyderabad', '6'),
  (12, 'Meena Kapoor', '9876500012', NULL, 'Chennai', NULL);

INSERT INTO accounts (account_no, customer_id, branch_id, type_id, pin_hash, balance, status, opened_on) VALUES
  (1001, 1, 1, 1, '9359484c63a22483a0b42d2674dc96e94044f716c333065428872530fdef6752', 44000.00, 'ACTIVE', '2025-01-10'),
  (1002, 2, 1, 1, '827b3a94c860efc432457722be248b53fd6b9c1c15ce5fd62e14076cbc49d345', 52800.00, 'ACTIVE', '2025-02-14'),
  (1003, 3, 6, 2, '81e337fd6ff62c0df5f6879bea6d04a5897e3cc4d2284de76b119997fa384e94', 120000, 'ACTIVE', '2025-03-05'),
  (1004, 4, 4, 1, '1a31c1c0a3e5c3824c9ba888cf2f92c179ffec76a22465fc27a700df7a918a02', 35000, 'ACTIVE', '2025-03-21'),
  (1005, 5, 8, 1, '52cfa6705ecf1e09ca4735f10ca83f0e36b02b4078c89b7822d5fe92dcb64813', 60840.00, 'ACTIVE', '2025-04-02'),
  (1006, 6, 2, 1, '7194b93f196dc53865e82bc54453fdcdf8a015c414d0b1693cc55375e3dc4542', 46500, 'ACTIVE', '2025-05-18'),
  (1007, 7, 3, 2, 'cc2e3e1dcfdd152029ad7f13602ef8f02fd077068758f47ee263e5a1ae7a84f6', 105000, 'ACTIVE', '2025-06-09'),
  (1008, 8, 5, 1, '8b8ec9f23ba2d66f403bdcf8457a779ccddeaf62b544560d2a0a6090ff7c1e52', 9000, 'ACTIVE', '2025-07-01'),
  (1009, 9, 9, 1, '894872092b2a76a0ccb49d2deb3e6c0ce92cd88e7d54ba2b31642e8449e247dd', 63440.00, 'ACTIVE', '2025-08-12'),
  (1010, 10, 7, 1, 'f821db62995712f5fa692c29fe5b9169d1249082cdf99f00485b3b26d54c946a', 28000, 'ACTIVE', '2025-09-03'),
  (1011, 11, 10, 1, '8fc80a5f0b25411e751af2797d69db1d2a4973d64c4b0b527cf9b0c711901678', 8000, 'FROZEN', '2025-10-15'),
  (1012, 12, 4, 1, 'd9b117ed5e29420dcf745ad9453f1a11ebeb7ebb5e8eab17618af7a6a06edbb3', 23000, 'ACTIVE', '2025-11-20');

INSERT INTO transactions (account_no, txn_type_id, amount, balance_after, counterparty_acc, status, remarks, txn_time) VALUES
  (1001, 1, 5000, 30000, NULL, 'COMPLETED', 'Salary credit', '2026-01-05 10:15:00'),
  (1002, 2, 3000, 45000, NULL, 'COMPLETED', 'ATM withdrawal', '2026-01-12 11:00:00'),
  (1003, 3, 20000, 130000, '1001', 'COMPLETED', 'Rent payment', '2026-01-20 15:30:00'),
  (1001, 4, 20000, 50000, '1003', 'COMPLETED', 'Rent payment', '2026-01-20 15:30:00'),
  (1004, 1, 8000, 20000, NULL, 'COMPLETED', 'Cash deposit at branch', '2026-02-03 09:45:00'),
  (1005, 2, 10000, 66000, NULL, 'COMPLETED', 'ATM withdrawal', '2026-02-14 14:20:00'),
  (1003, 1, 50000, 180000, NULL, 'COMPLETED', 'Client payment received', '2026-02-25 16:00:00'),
  (1005, 3, 7500, 58500, '1006', 'COMPLETED', 'Shared trip expenses', '2026-03-02 10:10:00'),
  (1006, 4, 7500, 37500, '1005', 'COMPLETED', 'Shared trip expenses', '2026-03-02 10:10:00'),
  (1007, 2, 25000, 65000, NULL, 'COMPLETED', 'Equipment purchase', '2026-03-18 13:00:00'),
  (1001, 5, 2000.00, 52000.00, NULL, 'COMPLETED', 'Annual interest credit', '2026-03-31 23:00:00'),
  (1002, 5, 1800.00, 46800.00, NULL, 'COMPLETED', 'Annual interest credit', '2026-03-31 23:00:00'),
  (1005, 5, 2340.00, 60840.00, NULL, 'COMPLETED', 'Annual interest credit', '2026-03-31 23:00:00'),
  (1009, 1, 12000, 76000, NULL, 'COMPLETED', 'Cash deposit at branch', '2026-04-04 10:00:00'),
  (1002, 3, 4000, 42800.00, '1008', 'COMPLETED', 'Loan repayment to friend', '2026-04-22 17:15:00'),
  (1008, 4, 4000, 9000, '1002', 'COMPLETED', 'Loan repayment to friend', '2026-04-22 17:15:00'),
  (1003, 2, 60000, 120000, NULL, 'COMPLETED', 'Vendor payment', '2026-05-06 09:30:00'),
  (1010, 1, 6000, 28000, NULL, 'COMPLETED', 'Cash deposit at branch', '2026-05-19 11:45:00'),
  (1012, 1, 5000, 18000, NULL, 'PENDING', 'Cheque deposit under clearing', '2026-06-01 10:20:00'),
  (1008, 2, 9000, 9000, NULL, 'FAILED', 'Insufficient funds', '2026-06-10 14:00:00'),
  (1009, 3, 15000, 61000, '1004', 'COMPLETED', 'Fee payment', '2026-06-28 16:40:00'),
  (1004, 4, 15000, 35000, '1009', 'COMPLETED', 'Fee payment', '2026-06-28 16:40:00'),
  (1006, 1, 9000, 46500, NULL, 'COMPLETED', 'Salary credit', '2026-07-07 10:05:00'),
  (1001, 2, 8000, 44000.00, NULL, 'COMPLETED', 'ATM withdrawal', '2026-07-21 12:10:00'),
  (1007, 1, 40000, 105000, NULL, 'COMPLETED', 'Client payment received', '2026-08-09 15:55:00'),
  (1009, 5, 2440.00, 63440.00, NULL, 'COMPLETED', 'Annual interest credit', '2026-08-30 23:00:00'),
  (1012, 1, 5000, 23000, NULL, 'COMPLETED', 'Cheque cleared', '2026-09-02 10:30:00'),
  (1002, 1, 10000, 52800.00, NULL, 'COMPLETED', 'Salary credit', '2026-09-15 11:10:00'),
  (1010, 1, 3500, 28000, NULL, 'PENDING', 'Cheque deposit under clearing', '2026-09-28 09:50:00');
