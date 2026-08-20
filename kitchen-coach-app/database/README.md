# Database — Coursework SQL

This folder holds the **Advanced SQL (21CSC205P) coursework**, kept separate
from [`../supabase/migrations/`](../supabase/migrations), which is the *live*
schema the deployed app actually queries. The domain (users/ingredients/
recipes/meal_logs) is the same in both; the SQL dialect and depth differ.

| File | Dialect | What it is |
|---|---|---|
| `kitchen_coach_complete.sql` | MySQL 8.0 | **The master file.** Full DDL + seed data + every required concept in one runnable script: constraints, aggregates, set ops, subqueries, joins, views, triggers, cursors, transactions/TCL, concurrency control. Run this one if you need a single script that demonstrates everything. |
| `kitchen_coach_db_postgres.sql` | PostgreSQL | The same schema and seed data translated to Postgres syntax (`SERIAL`, `JSONB`, `NOW()`). Closer in shape to `supabase/migrations/` than the MySQL file is, but still not identical to the deployed schema (no RLS, different table set). |

Earlier drafts (`*_practical.sql`, `*_db_queries.sql`, `*_db_mysql.sql`) were
strict subsets of the master file and have been removed; everything they
covered lives in `kitchen_coach_complete.sql`. They remain in git history if
you need them back.

## Running the MySQL script
```bash
mysql -u root -p < kitchen_coach_complete.sql
```
It creates and selects the `kitchen_coach_db` database itself, so no setup is
needed beforehand.

## Seed data
| Table | Rows |
|---|---|
| `users` | 22 |
| `ingredients` | 30 |
| `recipes` | 22 |
| `recipe_ingredients` | 64 |
| `meal_logs` | 55 |

## Why this doesn't just replace `supabase/migrations/`
The deployed app is single-owner and Supabase-managed: it uses `profiles` +
RLS policies instead of a `users` table with hashed passwords, and it has no
triggers/cursors/procedures yet. The files above are the fuller "textbook"
schema used to demonstrate the DBMS concepts required by the course. See the
root [README](../../README.md) and `../supabase/migrations/` for the schema the
running app uses.
