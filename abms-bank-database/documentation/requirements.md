# Requirements – Advanced Bank Management System (ABMS)

**Objective** – Keep bank accounts, balances and transaction history in a MySQL database instead of in Python variables, so data survives after the program closes.

**Real-world problem** – The first version of the project kept everything in memory and text files. Closing the program lost every account. A database gives permanent storage, safe money transfers (all-or-nothing), and fast reports.

**Modules**
| Module | Owner | What it does |
|---|---|---|
| Account management (`models.py`) | Member 1 | Account classes, PIN check (hashed), saving vs current rules |
| Banking operations (`operations.py`) | Member 2 | Open account, deposit, withdraw, transfer, balance, interest |
| Transactions & database (`database.py`, `transactions.py`) | Member 3 | MySQL connection, history, mini statement, save/read account file |

**Users / roles** – Customer (uses the menu with account number + PIN). Bank staff / analyst (runs reports in `10_reports.sql`).

**Workflow**
1. Customer opens an account (customer row + account row + opening deposit) in one transaction.
2. Each deposit / withdrawal / transfer / interest credit: lock the account row -> check rules -> update balance -> add a history row -> COMMIT (or ROLLBACK on any error).
3. Mini statement and file export read from the `transactions` table.
4. Triggers guard the data (overdraft floor, only ACTIVE accounts, status audit).
