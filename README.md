# Weight Coach — Advanced SQL Project (21CSC205P)

AI-based nutrition and kitchen management app, built as the Advanced SQL
course project. The working app lives in [`weight-coach-app/`](weight-coach-app);
everything else at this level is course documentation.

## Layout
```
.
├── ASQL_PROJECT TEMPLATE.pptx        # Slide template provided for the course
├── ASQL_PROJECT_COMPLETED.pptx       # Completed presentation
├── WEIGHT COACH FINAL UPDATES.docx   # Written report
├── Schema.mwb                        # MySQL Workbench ER diagram
├── weight-coach-app/                 # The actual application (React + Vite + Supabase)
│   ├── database/                     # Advanced SQL coursework (DDL/DML/views/triggers/cursors/...)
│   └── supabase/migrations/          # Live schema the deployed app runs on
└── _archive/
    └── legacy-express-backend/       # Superseded Express + MySQL API — kept for reference, not used by the app
```

## Where things are
- **Running the app / its own database docs** → see
  [`weight-coach-app/README.md`](weight-coach-app/README.md).
- **The Advanced SQL coursework SQL files** (constraints, aggregates, joins,
  views, triggers, cursors, transactions) → see
  [`weight-coach-app/database/README.md`](weight-coach-app/database/README.md).
- **`_archive/legacy-express-backend/`** is an earlier prototype (Node/Express
  + MySQL, routes for auth/ingredients/recipes/mealLogs/profile/shoppingList)
  from before the app moved to Supabase. It's not wired into the current app
  and isn't required to run it — kept only so that earlier work isn't lost.

## Quick start
```bash
cd weight-coach-app
npm install
npm run dev
```
