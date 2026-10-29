# ---> Member 3 : Transaction & Database (history, statements, file handling)
import os
from decimal import Decimal

from database import get_connection, fetch_account
from models import BankError


class TransactionManager:
    def __init__(self, folder="bank_records"):
        self.folder = folder
        os.makedirs(self.folder, exist_ok=True)

    # ---- history is now stored in the `transactions` table ----------------
    def record(self, cur, acc_no, txn_type, amount, balance_after,
               counterparty=None, remarks=None, status="COMPLETED"):
        """Insert one history row using the caller's cursor, so it is part of the SAME transaction
        as the balance update (both saved, or both undone). txn_type: DEPOSIT, WITHDRAW,
        TRANSFER_OUT, TRANSFER_IN or INTEREST."""
        cur.execute(
            """INSERT INTO transactions
                 (account_no, txn_type_id, amount, balance_after, counterparty_acc, status, remarks)
               SELECT %s, txn_type_id, %s, %s, %s, %s, %s
               FROM transaction_types WHERE type_name = %s""",
            (acc_no, amount, balance_after, counterparty, status, remarks, txn_type))
        if cur.rowcount == 0:
            raise BankError(f"Unknown transaction type {txn_type}")

    def _fetch_history(self, acc_no, limit=None):
        sql = """SELECT x.txn_time, tt.type_name, tt.direction, x.amount, x.balance_after,
                        x.counterparty_acc, x.status, x.remarks
                 FROM transactions x
                 JOIN transaction_types tt ON tt.txn_type_id = x.txn_type_id
                 WHERE x.account_no = %s
                 ORDER BY x.txn_time DESC, x.txn_id DESC"""
        params = [acc_no]
        if limit:
            sql += " LIMIT %s"
            params.append(limit)
        conn = get_connection()
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute(sql, params)
            return cur.fetchall()
        finally:
            conn.close()

    @staticmethod
    def _format(row):
        sign = "+" if row["direction"] == "CREDIT" else "-"
        other = f" (Acc {row['counterparty_acc']})" if row["counterparty_acc"] else ""
        note = f" [{row['status']}]" if row["status"] != "COMPLETED" else ""
        return (f"[{row['txn_time']}] {row['type_name']:<12} {sign}{row['amount']}{other} "
                f"(Balance: {row['balance_after']}){note}")

    def generate_mini_statement(self, acc_no, last_n=5):
        rows = self._fetch_history(acc_no, last_n)
        if not rows:
            print("No transactions yet.")
            return
        print(f"---- Mini Statement (Account {acc_no}, last {len(rows)}) ----")
        for row in rows:
            print(self._format(row))

    # ---- file handling (kept from the original project) -------------------
    def save_account_info(self, acc_no):
        conn = get_connection()
        try:
            cur = conn.cursor(dictionary=True)
            account = fetch_account(cur, acc_no)
        finally:
            conn.close()
        filename = os.path.join(self.folder, f"account_{acc_no}.txt")
        with open(filename, "w") as f:
            f.write(f"Account Number : {account.acc_no}\n")
            f.write(f"Name           : {account.name}\n")
            f.write(f"Type           : {account.account_type}\n")
            f.write(f"Opened On      : {account.opened_on}\n")
            f.write(f"Balance        : {account._balance()}\n")
            f.write("Transaction History (newest first):\n")
            for row in self._fetch_history(acc_no):
                f.write(self._format(row) + "\n")
        print(f"Account info saved to {filename}")
        return filename

    def read_account_info(self, acc_no):
        filename = os.path.join(self.folder, f"account_{acc_no}.txt")
        if not os.path.exists(filename):
            print("No saved record found for this account")
            return None
        with open(filename, "r") as f:
            content = f.read()
        print(content)
        return content
