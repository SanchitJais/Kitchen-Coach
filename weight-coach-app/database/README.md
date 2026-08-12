# Database — Coursework SQL

This folder holds the **Advanced SQL (21CSC205P) coursework**, kept separate
from [`../supabase/migrations/`](../supabase/migrations), which is the *live*
schema the deployed app actually queries. The domain (users/ingredients/
recipes/meal_logs) is the same in both; the SQL dialect and depth differ.

| File | Dialect | What it is |
|---|---|---|
| `weight_coach_complete.sql` | MySQL 8.0 | **The master file.** Full DDL + seed data + every required concept in one runnable script: constraints, aggregates, set ops, subqueries, joins, views, triggers, cursors, transactions/TCL, concurrency control. Run this one if you just need a single script that demonstrates everything. |
| `weight_coach_practical.sql` | MySQL 8.0 | The standalone lab-practical submission (constraints → cursors). Mostly a subset of `weight_coach_complete.sql`, kept as its own file since it was graded separately. |
| `weight_coach_db_queries.sql` | MySQL 8.0 | The same query set as the practical, but written up with a "Question / SQL / Explanation" format — the source for the write-up in `WEIGHT COACH FINAL UPDATES.docx`. |
| `weight_coach_db_mysql.sql` | MySQL 8.0 | Plain schema + seed data only, no exercises — useful for quickly spinning up a local MySQL copy. |
| `weight_coach_db_postgres.sql` | PostgreSQL | Same schema/seed, translated to Postgres syntax (`SERIAL`, `JSONB`, `NOW()`). Closer in shape to `supabase/migrations/` than the MySQL files are, but still not identical to the deployed schema (no RLS, different table set). |

## Why this doesn't just replace `supabase/migrations/`
The deployed app is single-owner and Supabase-managed: it uses `profiles` +
RLS policies instead of a `users` table with hashed passwords, and it has no
triggers/cursors/procedures yet. The files above are the fuller "textbook"
schema used to demonstrate DBMS concepts required by the course. See the root
README's [Database](../README.md#database) section, and
`../supabase/migrations/` for a proposed migration that ports the views/
triggers demonstrated here into the actual running app.
