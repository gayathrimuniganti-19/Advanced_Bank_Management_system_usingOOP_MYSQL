# ---> Member 1 : Account Management (classes, encapsulation, inheritance)
import hashlib
from decimal import Decimal


class BankError(Exception):
    """Any business-rule problem (bad PIN, low balance, ...)."""


def hash_pin(acc_no, pin):
    """Same formula as the sample data in 03_insert_data.sql: SHA2('<acc_no>:<pin>', 256)."""
    return hashlib.sha256(f"{acc_no}:{pin}".encode()).hexdigest()


class Account:
    def __init__(self, acc_no, name, account_type, balance, pin_hash, opened_on, status="ACTIVE"):
        self.acc_no = acc_no
        self.name = name
        self.account_type = account_type
        self.opened_on = opened_on
        self.status = status
        self.__balance = Decimal(balance)      # private (encapsulation)
        self.__pin_hash = pin_hash             # only the hash is ever kept

    def validate_pin(self, entered_pin):
        return hash_pin(self.acc_no, entered_pin) == self.__pin_hash

    def get_balance(self, entered_pin):
        return self.__balance if self.validate_pin(entered_pin) else None

    # "protected" helpers for the operations layer
    def _balance(self):
        return self.__balance

    def available_funds(self):
        """How much can be taken out right now (overridden by each account type)."""
        return self.__balance

    def calculate_interest(self):
        return Decimal("0.00")

    def show_details(self):
        print(f"Acc no : {self.acc_no} | Name: {self.name} | Type: {self.account_type} "
              f"| Status: {self.status} | Opened: {self.opened_on}")


class SavingAccount(Account):
    def __init__(self, acc_no, name, balance, pin_hash, opened_on, status, interest_rate, min_balance):
        super().__init__(acc_no, name, "SAVING", balance, pin_hash, opened_on, status)
        self.interest_rate = Decimal(interest_rate)
        self.min_balance = Decimal(min_balance)

    def available_funds(self):                       # polymorphism
        return self._balance() - self.min_balance

    def calculate_interest(self):                    # yearly interest
        return (self._balance() * self.interest_rate / 100).quantize(Decimal("0.01"))


class CurrentAccount(Account):
    def __init__(self, acc_no, name, balance, pin_hash, opened_on, status, overdraft_limit):
        super().__init__(acc_no, name, "CURRENT", balance, pin_hash, opened_on, status)
        self.overdraft_limit = Decimal(overdraft_limit)

    def available_funds(self):                       # polymorphism
        return self._balance() + self.overdraft_limit


def build_account(row):
    """Turn one database row (dict) into the right Account subclass."""
    if row["type_name"] == "SAVING":
        return SavingAccount(row["account_no"], row["full_name"], row["balance"], row["pin_hash"],
                             row["opened_on"], row["status"], row["interest_rate"], row["min_balance"])
    return CurrentAccount(row["account_no"], row["full_name"], row["balance"], row["pin_hash"],
                          row["opened_on"], row["status"], row["overdraft_limit"])
