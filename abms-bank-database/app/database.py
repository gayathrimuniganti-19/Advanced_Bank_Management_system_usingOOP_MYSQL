# ---> Member 3 : Database connection layer
import os
from contextlib import contextmanager

import mysql.connector

from models import build_account, BankError

# Change these defaults, or set environment variables (recommended for the password):
#   Windows (PowerShell):  $env:ABMS_DB_PASSWORD = "your_password"
#   Linux / macOS:         export ABMS_DB_PASSWORD="your_password"
DB_CONFIG = {
    "host": os.getenv("ABMS_DB_HOST", "localhost"),
    "port": int(os.getenv("ABMS_DB_PORT", "3306")),
    "user": os.getenv("ABMS_DB_USER", "root"),
    "password": os.getenv("ABMS_DB_PASSWORD", ""),
    "database": os.getenv("ABMS_DB_NAME", "abms_db"),
}


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


@contextmanager
def transaction():
    """One database transaction: COMMIT if the block finishes, ROLLBACK if anything fails."""
    conn = get_connection()
    try:
        cur = conn.cursor(dictionary=True, buffered=True)
        yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


ACCOUNT_SQL = """
SELECT a.account_no, c.full_name, t.type_name, a.balance, a.pin_hash, a.opened_on, a.status,
       t.interest_rate, t.overdraft_limit, t.min_balance
FROM accounts a
JOIN customers c     ON c.customer_id = a.customer_id
JOIN account_types t ON t.type_id     = a.type_id
WHERE a.account_no = %s
"""


def fetch_account(cur, acc_no, lock=False):
    """Load an Account object. lock=True uses SELECT ... FOR UPDATE so nobody else changes it meanwhile."""
    cur.execute(ACCOUNT_SQL + (" FOR UPDATE OF a" if lock else ""), (acc_no,))
    row = cur.fetchone()
    if row is None:
        raise BankError(f"Account {acc_no} not found")
    return build_account(row)


def update_balance(cur, acc_no, new_balance):
    cur.execute("UPDATE accounts SET balance = %s WHERE account_no = %s", (new_balance, acc_no))
