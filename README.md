# Kitchen Coach — Advanced SQL Project (21CSC205P)

Kitchen inventory and nutrition management app, built as the Advanced SQL
course project. The working app lives in [`kitchen-coach-app/`](kitchen-coach-app);
everything else at this level is course documentation.

The core idea: track what's actually in your kitchen, surface what's about to
expire, and match recipes against current stock so nothing gets wasted.

## Layout
```
.
├── ASQL_PROJECT TEMPLATE.pptx          # Slide template provided for the course
├── ASQL_PROJECT_COMPLETED.pptx         # Earlier presentation draft
├── ASQL_PROJECT_COMPLETED_v2.pptx      # Current presentation (16 slides)
├── KITCHEN COACH FINAL UPDATES.docx    # Written report
├── Schema.mwb                          # MySQL Workbench ER diagram
├── netlify.toml                        # Deploy config (base = kitchen-coach-app)
└── kitchen-coach-app/                  # The application (React + Vite + Supabase)
    ├── database/                       # Advanced SQL coursework (DDL/DML/views/triggers/cursors)
    └── supabase/migrations/            # Live schema the deployed app runs on
```

## Where things are
- **Running the app** → [`kitchen-coach-app/README.md`](kitchen-coach-app/README.md)
- **The Advanced SQL coursework** (constraints, aggregates, joins, views,
  triggers, cursors, transactions, concurrency control) →
  [`kitchen-coach-app/database/README.md`](kitchen-coach-app/database/README.md)

## Quick start
```bash
cd kitchen-coach-app
npm install
npm run dev
```
Then open http://localhost:8080

Requires a `.env` in `kitchen-coach-app/` with `VITE_SUPABASE_URL` and
`VITE_SUPABASE_PUBLISHABLE_KEY`. These are read at **build** time, so they must
also be set in the Netlify dashboard for the deployed site — without them the
Supabase client throws on import and the page renders blank.
