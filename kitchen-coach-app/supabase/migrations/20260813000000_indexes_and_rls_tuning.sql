-- ============================================================
-- Index + RLS tuning, from the Supabase performance advisor.
-- Purely additive: no data or column changes.
-- ============================================================

-- ------------------------------------------------------------
-- Foreign keys without a covering index. Both are joined on every
-- page load: MealLogs.tsx selects "*, recipes(name)", Recipes.tsx
-- groups recipe_ingredients by recipe_id, and both
-- available_recipes() and recipe_details_view join on recipe_id.
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_meal_logs_recipe_id
  ON public.meal_logs (recipe_id);

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id
  ON public.recipe_ingredients (recipe_id);

-- ------------------------------------------------------------
-- Composite indexes matching the app's actual filter+sort pairs:
--   Ingredients.tsx : where user_id = ? order by expiration_date asc
--   MealLogs.tsx    : where user_id = ? order by consumed_date desc
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ingredients_user_expiry
  ON public.ingredients (user_id, expiration_date);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_consumed
  ON public.meal_logs (user_id, consumed_date DESC);

-- ------------------------------------------------------------
-- auth_rls_initplan: bare auth.uid() in a policy is re-evaluated
-- once per row. Wrapping it in a scalar subquery lets Postgres
-- evaluate it a single time per query instead.
-- (profiles is unused in single-owner mode, but fixed for
-- correctness if per-user auth is ever turned back on.)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING ((select auth.uid()) = user_id);
