# Kitchen Coach App

Kitchen inventory and nutrition management web app — single-owner mode.

Stack: **React + Vite + TypeScript + Tailwind + shadcn/ui** (frontend) and
**Supabase** (Postgres database + REST API as backend).

## Features
- Home page with feature highlights
- Dashboard with stats (ingredients, meals logged, cookable recipes, expiring soon)
- Ingredients inventory (add / delete, expiry tracking, location)
- **Recipes matched to your kitchen** — the core idea of the project. Every
  recipe is scored against what you currently have in stock:
  - *Can cook now* — you have every ingredient
  - *Almost there* — you're missing one or two
  - each card shows a match %, which ingredients you have (green) vs. lack
    (struck through), and a one-click **"Add N missing items"** button that
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
kitchen-coach-app/
├── src/
│   ├── components/        # Navbar, NavLink + 13 shadcn UI primitives
│   ├── hooks/             # useAuth (single-owner), use-toast
│   ├── integrations/
│   │   └── supabase/      # client.ts (auto-generated), types.ts
│   ├── pages/             # Index, Dashboard, Ingredients, Recipes,
│   │                      # MealLogs, ShoppingList, NotFound, Auth
│   ├── test/              # Vitest + Testing Library specs
│   ├── index.css          # Design tokens
│   └── App.tsx            # Routes
├── supabase/
│   ├── config.toml
│   └── migrations/        # Live Postgres schema actually used by this app
├── database/                        # Coursework SQL (see database/README.md)
│   ├── kitchen_coach_complete.sql     # Full MySQL submission: DDL+DML+views+triggers+cursors
│   └── kitchen_coach_db_postgres.sql  # Postgres translation of the same schema
├── index.html
├── package.json
├── tailwind.config.ts
└── vite.config.ts
```

Only UI primitives the app actually imports are kept (13 of shadcn's ~49).
Anything unused was removed along with its Radix dependency, so `npm install`
pulls 22 runtime packages instead of 51.

## Run Locally
```bash
# 1. Install
npm install

# 2. Configure env — create .env with:
#    VITE_SUPABASE_URL=...
#    VITE_SUPABASE_PUBLISHABLE_KEY=...

# 3. Start the dev server
npm run dev
```

Open http://localhost:8080

> Both env vars are inlined at **build** time. If they are missing, the
> Supabase client throws while the module is evaluated, React never mounts,
> and you get a blank white page. On Netlify they must be set in the site's
> environment variables, not just in your local `.env`.

## Scripts
| Command | What it does |
|---|---|
| `npm run dev` | Vite dev server on :8080 |
| `npm run build` | Production build into `dist/` |
| `npm run preview` | Serve the built output |
| `npm test` | Run the Vitest suite once |
| `npm run lint` | ESLint over the project |

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

  All RPCs are `SECURITY INVOKER`, so Row-Level Security applies to them.

- **`database/`** — the Advanced SQL coursework (MySQL-oriented DDL/DML,
  constraints, aggregates, set ops, subqueries, joins, views, triggers,
  cursors, transactions, concurrency control). See
  [`database/README.md`](database/README.md). It documents the same domain but
  isn't the schema the deployed app reads from.

## Build for production
```bash
npm run build
```
Output in `dist/`.
