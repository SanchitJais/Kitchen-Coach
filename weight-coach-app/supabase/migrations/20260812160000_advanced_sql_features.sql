-- ============================================================
-- Ports the Advanced SQL coursework (see ../../database/) into the
-- live schema: views, a relational-division subquery, and triggers.
-- Purely additive — does not touch existing tables/policies/data.
--
-- Apply with `supabase db push`, or paste into the Supabase Dashboard's
-- SQL Editor. Not applied automatically by this repo.
-- ============================================================

-- ------------------------------------------------------------
-- VIEW: ingredients expiring within 3 days
-- Mirrors the client-side filter in src/pages/Dashboard.tsx so the
-- same "expiring soon" logic lives in the database too.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW public.expiring_ingredients_view
WITH (security_invoker = true) AS
SELECT id, user_id, name, quantity, unit, expiration_date, location
FROM public.ingredients
WHERE expiration_date IS NOT NULL
  AND expiration_date <= CURRENT_DATE + INTERVAL '3 days'
ORDER BY expiration_date;

GRANT SELECT ON public.expiring_ingredients_view TO anon, authenticated;

-- ------------------------------------------------------------
-- VIEW: recipes with an aggregated ingredient summary (JOIN + GROUP BY)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW public.recipe_details_view
WITH (security_invoker = true) AS
SELECT
  r.id,
  r.name,
  r.instructions,
  r.prep_time,
  r.difficulty_level,
  COUNT(ri.id) AS ingredient_count,
  STRING_AGG(
    ri.ingredient_name || COALESCE(' (' || ri.quantity || ')', ''),
    ', ' ORDER BY ri.ingredient_name
  ) AS ingredients_summary
FROM public.recipes r
LEFT JOIN public.recipe_ingredients ri ON ri.recipe_id = r.id
GROUP BY r.id, r.name, r.instructions, r.prep_time, r.difficulty_level;

GRANT SELECT ON public.recipe_details_view TO anon, authenticated;

-- ------------------------------------------------------------
-- FUNCTION: recipes fully makeable from a user's current inventory.
-- Relational-division pattern (double NOT EXISTS): a recipe qualifies
-- only if there is no required ingredient missing from stock.
-- Call via supabase-js: supabase.rpc('available_recipes', { p_user_id })
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.available_recipes(p_user_id uuid)
RETURNS SETOF public.recipes
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT r.*
  FROM public.recipes r
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND NOT EXISTS (
        SELECT 1 FROM public.ingredients i
        WHERE i.user_id = p_user_id
          AND lower(i.name) = lower(ri.ingredient_name)
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.available_recipes(uuid) TO anon, authenticated;

-- ------------------------------------------------------------
-- TRIGGER: reject ingredients inserted/updated with an expiration
-- date already in the past. Only affects rows written after this
-- migration runs — existing seed data is untouched.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_ingredient_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expiration_date IS NOT NULL AND NEW.expiration_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'expiration_date (%) cannot be in the past', NEW.expiration_date;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_ingredient_expiry ON public.ingredients;
CREATE TRIGGER trg_check_ingredient_expiry
  BEFORE INSERT OR UPDATE ON public.ingredients
  FOR EACH ROW EXECUTE FUNCTION public.check_ingredient_expiry();

-- ------------------------------------------------------------
-- TRIGGER: default a meal log's rating to 3 when left NULL.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.default_meal_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rating IS NULL THEN
    NEW.rating := 3;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS trg_default_meal_rating ON public.meal_logs;
CREATE TRIGGER trg_default_meal_rating
  BEFORE INSERT ON public.meal_logs
  FOR EACH ROW EXECUTE FUNCTION public.default_meal_rating();

-- Not ported: the "reduce ingredient quantity after a meal is logged"
-- trigger from database/weight_coach_practical.sql. In this schema,
-- recipe_ingredients.quantity is a free-text field (e.g. "400 g") while
-- ingredients.quantity/unit are separate numeric/text columns, so an
-- automatic decrement would need text parsing that's easy to get wrong
-- untested. Left out rather than shipped fragile.

-- ------------------------------------------------------------
-- SECURITY FIX (pre-existing, from the first migration): handle_new_user()
-- is a SECURITY DEFINER function meant to fire only via the
-- on_auth_user_created trigger on auth.users, but was directly callable by
-- anyone via /rest/v1/rpc/handle_new_user. Revoking EXECUTE closes that
-- without affecting the trigger itself (triggers don't need caller EXECUTE
-- grants to fire).
-- ------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
