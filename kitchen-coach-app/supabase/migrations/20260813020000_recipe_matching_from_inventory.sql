-- ============================================================
--  "What can I cook with what I have?" — the project's core idea,
--  computed in the database rather than in the client.
-- ============================================================

-- ------------------------------------------------------------
-- Fix to the earlier available_recipes(): a recipe with no rows in
-- recipe_ingredients satisfied the double-NOT-EXISTS vacuously (there is
-- no missing ingredient because there is no ingredient at all) and was
-- reported as cookable. Require at least one ingredient.
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
  WHERE EXISTS (
    SELECT 1 FROM public.recipe_ingredients ri WHERE ri.recipe_id = r.id
  )
  AND NOT EXISTS (
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

-- ------------------------------------------------------------
-- Per-recipe match against the user's stock: how many ingredients they
-- have, which ones they don't, and a percentage. Powers the Recipes page.
--
-- LEFT JOIN LATERAL probes the inventory once per required ingredient;
-- aggregate FILTER splits have/missing in a single pass; array_agg with
-- FILTER collects the missing names.
--
-- The `ri.id IS NOT NULL` guard in the array_agg FILTER matters: for a
-- recipe with no ingredients the LEFT JOIN still emits one all-NULL row,
-- and `inv.name IS NULL` is true for it, which would otherwise collect a
-- NULL element into the array.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.recipe_match_summary(p_user_id uuid)
RETURNS TABLE (
  id                uuid,
  name              text,
  instructions      text,
  prep_time         integer,
  difficulty_level  text,
  total_ingredients bigint,
  have_count        bigint,
  missing_count     bigint,
  missing_ingredients text[],
  match_pct         integer
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.name,
    r.instructions,
    r.prep_time,
    r.difficulty_level,
    count(ri.id)                                     AS total_ingredients,
    count(ri.id) FILTER (WHERE inv.name IS NOT NULL) AS have_count,
    count(ri.id) FILTER (WHERE inv.name IS NULL)     AS missing_count,
    COALESCE(
      array_agg(ri.ingredient_name ORDER BY ri.ingredient_name)
        FILTER (WHERE ri.id IS NOT NULL AND inv.name IS NULL),
      '{}'::text[]
    )                                                AS missing_ingredients,
    CASE
      WHEN count(ri.id) = 0 THEN 0
      ELSE round(100.0 * count(ri.id) FILTER (WHERE inv.name IS NOT NULL) / count(ri.id))::int
    END                                              AS match_pct
  FROM public.recipes r
  LEFT JOIN public.recipe_ingredients ri ON ri.recipe_id = r.id
  LEFT JOIN LATERAL (
    SELECT i.name
    FROM public.ingredients i
    WHERE i.user_id = p_user_id
      AND lower(i.name) = lower(ri.ingredient_name)
    LIMIT 1
  ) inv ON true
  GROUP BY r.id, r.name, r.instructions, r.prep_time, r.difficulty_level
  ORDER BY match_pct DESC, r.name;
$$;

GRANT EXECUTE ON FUNCTION public.recipe_match_summary(uuid) TO anon, authenticated;

-- ------------------------------------------------------------
-- Push everything a recipe needs but the user lacks onto the shopping
-- list, borrowing quantities from the catalogue where names match.
--
-- DISTINCT ON guards the case where a recipe lists the same ingredient
-- twice: without it, ON CONFLICT would try to touch the same target row
-- twice in one statement, which Postgres rejects.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_missing_to_shopping_list(
  p_user_id   uuid,
  p_recipe_id uuid
)
RETURNS integer
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  n integer := 0;
BEGIN
  INSERT INTO public.shopping_list_items
    (user_id, store_item_id, name, quantity, unit, category)
  SELECT DISTINCT ON (lower(ri.ingredient_name))
    p_user_id,
    s.id,
    ri.ingredient_name,
    COALESCE(s.default_quantity, 1),
    COALESCE(s.default_unit, 'pcs'),
    s.category
  FROM public.recipe_ingredients ri
  LEFT JOIN public.store_items s ON lower(s.name) = lower(ri.ingredient_name)
  WHERE ri.recipe_id = p_recipe_id
    AND NOT EXISTS (
      SELECT 1 FROM public.ingredients i
      WHERE i.user_id = p_user_id
        AND lower(i.name) = lower(ri.ingredient_name)
    )
  ORDER BY lower(ri.ingredient_name)
  ON CONFLICT (user_id, name) DO UPDATE
    SET checked = false;

  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_missing_to_shopping_list(uuid, uuid) TO anon, authenticated;
