# ---> Member 2 : Banking Operations (methods, exception handling)
from decimal import Decimal, InvalidOperation

from mysql.connector import Error as MySQLError

from database import transaction, fetch_account, update_balance
from models import BankError, hash_pin


def to_amount(value):
    """Convert user input to a Decimal with 2 places; must be > 0."""
    try:
        amount = Decimal(str(value)).quantize(Decimal("0.01"))
    except (InvalidOperation, ValueError):
        raise BankError("Amount must be a number")
    if amount <= 0:
        raise BankError("Amount must be greater than 0")
    return amount


class BankingOperations:
    def __init__(self, txn_manager):
        self.txns = txn_manager

    @staticmethod
    def _check_active(account):
        if account.status != "ACTIVE":
            raise BankError(f"Account {account.acc_no} is {account.status}")

    # Every method: one DB transaction -> all changes saved together or none at all.
    def open_account(self, name, phone, pin, initial_deposit, account_type="SAVING", branch_id=1):
        try:
            if not (pin.isdigit() and len(pin) == 4):
                raise BankError("PIN must be exactly 4 digits")
            initial = Decimal(str(initial_deposit)).quantize(Decimal("0.01"))
            with transaction() as cur:
                cur.execute("SELECT type_id, min_balance FROM account_types WHERE type_name = %s",
                            (account_type,))
                t = cur.fetchone()
                if t is None:
                    raise BankError("Account type must be SAVING or CURRENT")
                if initial < t["min_balance"]:
                    raise BankError(f"Minimum opening balance is {t['min_balance']}")
                cur.execute("INSERT INTO customers (full_name, phone) VALUES (%s, %s)", (name, phone))
                customer_id = cur.lastrowid
                cur.execute("""INSERT INTO accounts (customer_id, branch_id, type_id, pin_hash, balance)
                               VALUES (%s, %s, %s, %s, %s)""",
                            (customer_id, branch_id, t["type_id"], "0" * 64, initial))
                acc_no = cur.lastrowid
                # the PIN hash includes the account number, so it is set after the number exists
                cur.execute("UPDATE accounts SET pin_hash = %s WHERE account_no = %s",
                            (hash_pin(acc_no, pin), acc_no))
                if initial > 0:
                    self.txns.record(cur, acc_no, "DEPOSIT", initial, initial, remarks="Account opening")
            print(f"Account created. Your account number is {acc_no}")
            return acc_no
        except (BankError, MySQLError, InvalidOperation) as e:
            print("Error:", e)

    def deposit(self, acc_no, amount):
        try:
            amount = to_amount(amount)
            with transaction() as cur:
                acc = fetch_account(cur, acc_no, lock=True)
                self._check_active(acc)
                new_bal = acc._balance() + amount
                update_balance(cur, acc_no, new_bal)
                self.txns.record(cur, acc_no, "DEPOSIT", amount, new_bal)
            print(f"{amount} deposited successfully")
            print(f"Current Balance: {new_bal}")
        except (BankError, MySQLError) as e:
            print("Error:", e)

    def withdraw(self, acc_no, pin, amount):
        try:
            amount = to_amount(amount)
            with transaction() as cur:
                acc = fetch_account(cur, acc_no, lock=True)
                self._check_active(acc)
                if not acc.validate_pin(pin):
                    raise BankError("Invalid PIN")
                if amount > acc.available_funds():
                    raise BankError("Insufficient balance")
                new_bal = acc._balance() - amount
                update_balance(cur, acc_no, new_bal)
                self.txns.record(cur, acc_no, "WITHDRAW", amount, new_bal)
            print(f"{amount} withdrawn successfully")
            print(f"Current Balance: {new_bal}")
        except (BankError, MySQLError) as e:
            print("Error:", e)

    def check_balance(self, acc_no, pin):
        try:
            with transaction() as cur:
                acc = fetch_account(cur, acc_no)
            balance = acc.get_balance(pin)
            if balance is None:
                raise BankError("Invalid PIN")
            print(f"Account Number: {acc.acc_no}")
            print(f"Account Holder: {acc.name}")
            print(f"Current balance: {balance}")
        except (BankError, MySQLError) as e:
            print("Error:", e)

    def transfer_money(self, sender_no, receiver_no, sender_pin, amount):
        try:
            amount = to_amount(amount)
            if sender_no == receiver_no:
                raise BankError("Cannot transfer to the same account")
            with transaction() as cur:
                # lock the smaller account number first so two opposite transfers cannot deadlock
                first, second = sorted((sender_no, receiver_no))
                locked = {first: fetch_account(cur, first, lock=True),
                          second: fetch_account(cur, second, lock=True)}
                sender, receiver = locked[sender_no], locked[receiver_no]
                self._check_active(sender)
                self._check_active(receiver)
                if not sender.validate_pin(sender_pin):
                    raise BankError("Invalid sender PIN")
                if amount > sender.available_funds():
                    raise BankError("Insufficient balance for transfer")
                s_bal = sender._balance() - amount
                r_bal = receiver._balance() + amount
                update_balance(cur, sender_no, s_bal)
                update_balance(cur, receiver_no, r_bal)
                self.txns.record(cur, sender_no, "TRANSFER_OUT", amount, s_bal, receiver_no)
                self.txns.record(cur, receiver_no, "TRANSFER_IN", amount, r_bal, sender_no)
            print(f"{amount} transferred successfully")
            print(f"Sender Balance: {s_bal}")
        except (BankError, MySQLError) as e:
            print("Error:", e)

    def calculate_interest(self, acc_no):
        try:
            with transaction() as cur:
                acc = fetch_account(cur, acc_no)
            print(f"Yearly interest for account {acc_no}: {acc.calculate_interest()}")
        except (BankError, MySQLError) as e:
            print("Error:", e)

    def credit_interest(self, acc_no):
        try:
            with transaction() as cur:
                acc = fetch_account(cur, acc_no, lock=True)
                self._check_active(acc)
                interest = acc.calculate_interest()
                if interest <= 0:
                    raise BankError("This account earns no interest")
                new_bal = acc._balance() + interest
                update_balance(cur, acc_no, new_bal)
                self.txns.record(cur, acc_no, "INTEREST", interest, new_bal, remarks="Annual interest credit")
            print(f"Interest {interest} credited. Balance: {new_bal}")
        except (BankError, MySQLError) as e:
            print("Error:", e)
