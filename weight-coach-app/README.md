# Kitchen Coach App

AI-based nutrition and kitchen management web app — single-owner mode.

Stack: **React + Vite + TypeScript + Tailwind + shadcn/ui** (frontend) and
**Supabase** (Postgres database + REST API as backend).

## Features
- Home page with feature highlights
- Dashboard with stats (ingredients, meals logged, recipes, expiring soon)
- Ingredients inventory (add / delete, expiry tracking, location)
- **Recipes matched to your kitchen** — the core idea of the project. Every
  recipe is scored against what you currently have in stock:
  - *Can cook now* — you have every ingredient
  - *Almost there* — you're missing one or two
  - each card shows a match %, which ingredients you have (green) vs. lack
    (struck through), and a one-click **“Add N missing items”** button that
    pushes exactly the gaps onto your shopping list
- Meal log with rating
- **Shopping** — three tabs, all persisted in Postgres:
  - *My List* — check items off, adjust quantities, add your own items
  - *Cart* — save items for later, move them to the list in one click
  - *Browse* — a 50-item catalogue with search and category filters; open any
    item for quantity controls and Amazon / Flipkart / Blinkit buy links

> The retailer buttons open a **search** for the item on each store rather than
> a fixed product page. Product IDs and prices change constantly, so a
> hardcoded listing would go stale or 404; a search always returns live
> results and current prices.

This build is configured for a **single user** — no signup/login. The app
auto-uses a fixed owner UUID (`11111111-1111-1111-1111-111111111111`)
which matches the seeded data in the database.

## Folder Structure
```
weight-coach-app/
├── src/
│   ├── components/        # Navbar + shadcn UI primitives
│   ├── hooks/             # useAuth (single-owner), use-toast, ...
│   ├── integrations/
│   │   └── supabase/      # client.ts (auto-generated), types.ts
│   ├── pages/             # Index, Dashboard, Ingredients, Recipes,
│   │                      # MealLogs, ShoppingList, NotFound, Auth
│   ├── index.css          # Design tokens
│   └── App.tsx            # Routes
├── supabase/
│   ├── config.toml
│   └── migrations/        # Live Postgres schema actually used by this app
├── database/               # Coursework SQL (see database/README.md)
│   ├── weight_coach_complete.sql     # Full MySQL submission: DDL+DML+views+triggers+cursors
│   ├── weight_coach_db_mysql.sql     # MySQL schema + seed data
│   ├── weight_coach_db_postgres.sql  # Postgres schema + seed data
│   ├── weight_coach_db_queries.sql   # Standalone query set
│   └── weight_coach_practical.sql    # Practical: constraints/aggregates/joins/views/triggers/cursors
├── index.html
├── package.json
├── tailwind.config.ts
└── vite.config.ts
```

## Run Locally
```bash
# 1. Install
bun install        # or: npm install

# 2. Configure env (already provided in .env)
#    VITE_SUPABASE_URL=...
#    VITE_SUPABASE_PUBLISHABLE_KEY=...

# 3. Start the dev server
bun run dev        # or: npm run dev
```

Open http://localhost:8080

## Database
Two SQL sources exist side by side, on purpose:

- **`supabase/migrations/`** — the *live* Postgres schema that actually powers
  this app. Tables: `profiles`, `ingredients`, `recipes`, `recipe_ingredients`,
  `meal_logs`, `store_items`, `shopping_list_items`, `cart_items`.
  Row-Level Security is enabled with single-owner policies.

  Server-side logic worth knowing about:
  - `add_to_shopping_list()` / `add_to_cart()` — UPSERT so adding the same
    item twice bumps its quantity instead of failing the unique constraint
  - `move_cart_item_to_list()` — upsert into the list + delete the cart row
  - `available_recipes()` — recipes fully cookable from current stock
    (relational division, double `NOT EXISTS`)
  - `recipe_match_summary()` — per-recipe have/missing counts, missing
    ingredient names and a match % (`LEFT JOIN LATERAL` + aggregate `FILTER`
    + `array_agg`)
  - `add_missing_to_shopping_list()` — upserts a recipe's missing ingredients
    onto the shopping list, taking quantities from the catalogue
  - `suggested_store_items()` — catalogue items not already in the kitchen
  - views `expiring_ingredients_view`, `recipe_details_view`
  - triggers rejecting past expiry dates and defaulting a null meal rating
- **`database/`** — the Advanced SQL coursework (MySQL-oriented DDL/DML,
  constraints, aggregates, set ops, subqueries, joins, views, triggers,
  cursors). See [`database/README.md`](database/README.md) for what each file
  covers. It documents the same domain but isn't the schema the deployed app
  reads from.

## Build for production
```bash
bun run build
```
Output in `dist/`.
