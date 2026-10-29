# ER diagram (text) and relationships

```
branches 1 ──────< accounts >────── 1 customers
                      │  │                │
                      │  └─ N : 1 ─ account_types      customers 1 ──< customers (referred_by, self)
                      │
                      ├──────< transactions >────── 1 transaction_types
                      │            │
                      │            └─ counterparty_acc ──> accounts (transfers)
                      └──────< account_audit
```

## Relationships
- **One-to-many:** branch -> accounts; customer -> accounts; account_type -> accounts; account -> transactions; transaction_type -> transactions; account -> account_audit; customer -> customers they referred (self relationship).
- **Many-to-many:** customers <-> branches, solved through `accounts` (a customer can hold accounts at many branches, a branch has many customers). `accounts` therefore acts as the junction table and carries its own data (balance, status).
- **One-to-one:** none needed. (A customer's profile could be split into its own table, but nothing in this project needs it.)
- **Transfers:** a transfer writes two rows in `transactions` (TRANSFER_OUT for the sender, TRANSFER_IN for the receiver); `counterparty_acc` links each row to the other account.

## Normalization
- **1NF** – every column holds one value (no lists in a cell), every table has a primary key, no repeating column groups (no `phone1, phone2`).
- **2NF** – all tables have a single-column primary key, so no column can depend on only part of a key.
- **3NF** – no column depends on a non-key column. Interest rate, overdraft limit and minimum balance live in `account_types`, not in `accounts`; branch city lives in `branches`; the type names live in the two type tables.
- **Intentional denormalization** – `transactions.balance_after` and `accounts.balance` are stored even though they could be calculated by adding up transactions. This makes balance checks and statements fast, and `balance_after` keeps a statement correct even if rules change later. The cost is that both must change together, which is why every Python operation and stored procedure does them inside one transaction.
