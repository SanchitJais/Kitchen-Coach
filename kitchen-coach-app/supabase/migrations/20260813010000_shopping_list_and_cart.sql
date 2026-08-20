-- ============================================================
--  Shopping list, saved cart, and a browsable store catalogue.
--  Replaces the old in-memory-only Shopping List page.
-- ============================================================

-- ------------------------------------------------------------
-- store_items : the catalogue the user browses and adds from.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.store_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL UNIQUE,
  category         text NOT NULL,
  emoji            text,
  default_quantity numeric NOT NULL DEFAULT 1,
  default_unit     text NOT NULL DEFAULT 'pcs',
  calories_per_unit numeric,
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.store_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view store items" ON public.store_items;
CREATE POLICY "Anyone can view store items" ON public.store_items FOR SELECT USING (true);

-- ------------------------------------------------------------
-- shopping_list_items : what the user plans to buy now.
-- cart_items          : saved for later.
-- Both keep name/unit denormalised so a row survives the
-- catalogue entry being removed.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.shopping_list_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL,
  store_item_id uuid REFERENCES public.store_items(id) ON DELETE SET NULL,
  name          text NOT NULL,
  quantity      numeric NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit          text NOT NULL DEFAULT 'pcs',
  category      text,
  checked       boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS public.cart_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL,
  store_item_id uuid REFERENCES public.store_items(id) ON DELETE SET NULL,
  name          text NOT NULL,
  quantity      numeric NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit          text NOT NULL DEFAULT 'pcs',
  category      text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

ALTER TABLE public.shopping_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Single-owner mode, matching the policy style already used by
-- ingredients and meal_logs.
DROP POLICY IF EXISTS "Public read shopping list" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Public insert shopping list" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Public update shopping list" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Public delete shopping list" ON public.shopping_list_items;
CREATE POLICY "Public read shopping list"   ON public.shopping_list_items FOR SELECT USING (true);
CREATE POLICY "Public insert shopping list" ON public.shopping_list_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update shopping list" ON public.shopping_list_items FOR UPDATE USING (true);
CREATE POLICY "Public delete shopping list" ON public.shopping_list_items FOR DELETE USING (true);

DROP POLICY IF EXISTS "Public read cart" ON public.cart_items;
DROP POLICY IF EXISTS "Public insert cart" ON public.cart_items;
DROP POLICY IF EXISTS "Public update cart" ON public.cart_items;
DROP POLICY IF EXISTS "Public delete cart" ON public.cart_items;
CREATE POLICY "Public read cart"   ON public.cart_items FOR SELECT USING (true);
CREATE POLICY "Public insert cart" ON public.cart_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update cart" ON public.cart_items FOR UPDATE USING (true);
CREATE POLICY "Public delete cart" ON public.cart_items FOR DELETE USING (true);

CREATE INDEX IF NOT EXISTS idx_shopping_list_user ON public.shopping_list_items (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cart_user          ON public.cart_items (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_list_item ON public.shopping_list_items (store_item_id);
CREATE INDEX IF NOT EXISTS idx_cart_item          ON public.cart_items (store_item_id);

-- ------------------------------------------------------------
-- Adding the same item twice should bump the quantity rather than
-- fail on the UNIQUE constraint. UPSERT keeps that atomic instead
-- of doing a read-then-write from the client.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_to_shopping_list(
  p_user_id  uuid,
  p_name     text,
  p_quantity numeric DEFAULT 1,
  p_unit     text    DEFAULT 'pcs',
  p_category text    DEFAULT NULL,
  p_store_item_id uuid DEFAULT NULL
)
RETURNS public.shopping_list_items
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.shopping_list_items
    (user_id, store_item_id, name, quantity, unit, category)
  VALUES
    (p_user_id, p_store_item_id, p_name, p_quantity, p_unit, p_category)
  ON CONFLICT (user_id, name) DO UPDATE
    SET quantity = public.shopping_list_items.quantity + EXCLUDED.quantity,
        checked  = false
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.add_to_cart(
  p_user_id  uuid,
  p_name     text,
  p_quantity numeric DEFAULT 1,
  p_unit     text    DEFAULT 'pcs',
  p_category text    DEFAULT NULL,
  p_store_item_id uuid DEFAULT NULL
)
RETURNS public.cart_items
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.cart_items
    (user_id, store_item_id, name, quantity, unit, category)
  VALUES
    (p_user_id, p_store_item_id, p_name, p_quantity, p_unit, p_category)
  ON CONFLICT (user_id, name) DO UPDATE
    SET quantity = public.cart_items.quantity + EXCLUDED.quantity
  RETURNING *;
$$;

GRANT EXECUTE ON FUNCTION public.add_to_shopping_list(uuid, text, numeric, text, text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.add_to_cart(uuid, text, numeric, text, text, uuid) TO anon, authenticated;

-- ------------------------------------------------------------
-- Moving a saved item from the cart into the shopping list, in one
-- statement: upsert into the list, then drop the cart row.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.move_cart_item_to_list(p_cart_item_id uuid)
RETURNS public.shopping_list_items
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  c public.cart_items;
  r public.shopping_list_items;
BEGIN
  SELECT * INTO c FROM public.cart_items WHERE id = p_cart_item_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'cart item % not found', p_cart_item_id;
  END IF;

  SELECT * INTO r FROM public.add_to_shopping_list(
    c.user_id, c.name, c.quantity, c.unit, c.category, c.store_item_id
  );

  DELETE FROM public.cart_items WHERE id = p_cart_item_id;
  RETURN r;
END;
$$;

GRANT EXECUTE ON FUNCTION public.move_cart_item_to_list(uuid) TO anon, authenticated;

-- ------------------------------------------------------------
-- Which catalogue items are NOT already in the user's kitchen?
-- (set difference — the "what do I still need to buy" query)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.suggested_store_items(p_user_id uuid)
RETURNS SETOF public.store_items
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT s.*
  FROM public.store_items s
  WHERE NOT EXISTS (
    SELECT 1 FROM public.ingredients i
    WHERE i.user_id = p_user_id
      AND lower(i.name) = lower(s.name)
  )
  ORDER BY s.category, s.name;
$$;

GRANT EXECUTE ON FUNCTION public.suggested_store_items(uuid) TO anon, authenticated;

-- ------------------------------------------------------------
-- Catalogue seed : 50 items.
-- ------------------------------------------------------------
INSERT INTO public.store_items (name, category, emoji, default_quantity, default_unit, calories_per_unit) VALUES
  ('Spinach',            'Vegetables',      '🥬', 250, 'g',   23),
  ('Tomatoes',           'Vegetables',      '🍅', 500, 'g',   18),
  ('Onions',             'Vegetables',      '🧅', 1,   'kg',  40),
  ('Garlic',             'Vegetables',      '🧄', 200, 'g',   149),
  ('Broccoli',           'Vegetables',      '🥦', 400, 'g',   55),
  ('Kale',               'Vegetables',      '🥬', 250, 'g',   49),
  ('Asparagus',          'Vegetables',      '🌱', 300, 'g',   20),
  ('Carrots',            'Vegetables',      '🥕', 500, 'g',   41),
  ('Bell Pepper',        'Vegetables',      '🫑', 300, 'g',   31),
  ('Cucumber',           'Vegetables',      '🥒', 400, 'g',   15),
  ('Potato',             'Vegetables',      '🥔', 1,   'kg',  77),
  ('Sweet Potato',       'Vegetables',      '🍠', 800, 'g',   86),
  ('Cauliflower',        'Vegetables',      '🥦', 600, 'g',   25),
  ('Green Peas',         'Vegetables',      '🫛', 400, 'g',   81),
  ('Mushrooms',          'Vegetables',      '🍄', 300, 'g',   22),
  ('Ginger',             'Vegetables',      '🫚', 150, 'g',   80),
  ('Green Chilli',       'Vegetables',      '🌶️', 100, 'g',   40),
  ('Coriander',          'Vegetables',      '🌿', 100, 'g',   23),
  ('Banana',             'Fruits',          '🍌', 6,   'pcs', 89),
  ('Apple',              'Fruits',          '🍎', 6,   'pcs', 52),
  ('Orange',             'Fruits',          '🍊', 6,   'pcs', 47),
  ('Lemon',              'Fruits',          '🍋', 4,   'pcs', 29),
  ('Blueberries',        'Fruits',          '🫐', 250, 'g',   57),
  ('Avocado',            'Fruits',          '🥑', 2,   'pcs', 160),
  ('Milk',               'Dairy & Eggs',    '🥛', 1,   'L',   61),
  ('Almond Milk',        'Dairy & Eggs',    '🥛', 1,   'L',   17),
  ('Greek Yogurt',       'Dairy & Eggs',    '🥣', 500, 'g',   59),
  ('Cheddar Cheese',     'Dairy & Eggs',    '🧀', 250, 'g',   402),
  ('Paneer',             'Dairy & Eggs',    '🧀', 400, 'g',   265),
  ('Butter',             'Dairy & Eggs',    '🧈', 250, 'g',   717),
  ('Eggs',               'Dairy & Eggs',    '🥚', 12,  'pcs', 78),
  ('Rice',               'Grains & Pulses', '🍚', 2,   'kg',  130),
  ('Quinoa',             'Grains & Pulses', '🌾', 500, 'g',   120),
  ('Oats',               'Grains & Pulses', '🥣', 1,   'kg',  389),
  ('Pasta',              'Grains & Pulses', '🍝', 500, 'g',   158),
  ('Lentils',            'Grains & Pulses', '🫘', 800, 'g',   116),
  ('Chickpeas',          'Grains & Pulses', '🫘', 500, 'g',   164),
  ('Black Beans',        'Grains & Pulses', '🫘', 600, 'g',   132),
  ('Whole Wheat Bread',  'Bakery',          '🍞', 1,   'pcs', 247),
  ('Almonds',            'Snacks',          '🌰', 250, 'g',   579),
  ('Honey',              'Condiments',      '🍯', 300, 'ml',  304),
  ('Olive Oil',          'Condiments',      '🫒', 750, 'ml',  884),
  ('Coconut Oil',        'Condiments',      '🥥', 500, 'ml',  862),
  ('Soy Sauce',          'Condiments',      '🍶', 500, 'ml',  60),
  ('Marinara Sauce',     'Condiments',      '🥫', 400, 'ml',  45),
  ('Chicken Breast',     'Meat & Seafood',  '🍗', 600, 'g',   165),
  ('Ground Beef',        'Meat & Seafood',  '🥩', 500, 'g',   250),
  ('Salmon Fillet',      'Meat & Seafood',  '🐟', 400, 'g',   208),
  ('Shrimp',             'Meat & Seafood',  '🦐', 400, 'g',   99),
  ('Tofu',               'Meat & Seafood',  '🧊', 400, 'g',   76)
ON CONFLICT (name) DO NOTHING;
