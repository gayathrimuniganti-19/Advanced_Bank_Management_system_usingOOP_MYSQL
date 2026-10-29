# Menu-driven console app. Run from the app/ folder:  python main.py
from mysql.connector import Error as MySQLError

from database import get_connection
from operations import BankingOperations
from transactions import TransactionManager

MENU = """
===== Advanced Bank Management System =====
1. Open account          6. Mini statement
2. Deposit               7. Credit yearly interest
3. Withdraw              8. Save account info to file
4. Transfer money        9. Read saved account file
5. Check balance         0. Exit
"""


def ask_int(prompt):
    while True:
        try:
            return int(input(prompt))
        except ValueError:
            print("Please enter a whole number.")


def main():
    try:
        get_connection().close()
    except MySQLError as e:
        print("Cannot connect to MySQL:", e)
        print("Check ABMS_DB_* settings in database.py and that you ran the SQL scripts first.")
        return

    txns = TransactionManager()
    bank = BankingOperations(txns)
    while True:
        print(MENU)
        choice = input("Choose: ").strip()
        if choice == "1":
            bank.open_account(input("Name: ").strip(), input("Phone (10 digits): ").strip(),
                              input("4-digit PIN: ").strip(), input("Opening deposit: "),
                              input("Type (SAVING/CURRENT): ").strip().upper() or "SAVING")
        elif choice == "2":
            bank.deposit(ask_int("Account no: "), input("Amount: "))
        elif choice == "3":
            bank.withdraw(ask_int("Account no: "), input("PIN: ").strip(), input("Amount: "))
        elif choice == "4":
            bank.transfer_money(ask_int("From account: "), ask_int("To account: "),
                                input("Your PIN: ").strip(), input("Amount: "))
        elif choice == "5":
            bank.check_balance(ask_int("Account no: "), input("PIN: ").strip())
        elif choice == "6":
            txns.generate_mini_statement(ask_int("Account no: "))
        elif choice == "7":
            acc = ask_int("Account no: ")
            bank.calculate_interest(acc)
            if input("Credit it to the account? (y/n): ").strip().lower() == "y":
                bank.credit_interest(acc)
        elif choice == "8":
            txns.save_account_info(ask_int("Account no: "))
        elif choice == "9":
            txns.read_account_info(ask_int("Account no: "))
        elif choice == "0":
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")


if __name__ == "__main__":
    main()
