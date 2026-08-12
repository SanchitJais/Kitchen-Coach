
-- Remove FK constraints to auth.users so we can use a fixed owner UUID
ALTER TABLE public.ingredients DROP CONSTRAINT IF EXISTS ingredients_user_id_fkey;
ALTER TABLE public.meal_logs DROP CONSTRAINT IF EXISTS meal_logs_user_id_fkey;

ALTER TABLE public.ingredients ADD COLUMN IF NOT EXISTS calories_per_unit numeric DEFAULT 0;

DROP POLICY IF EXISTS "Users can view own ingredients" ON public.ingredients;
DROP POLICY IF EXISTS "Users can insert own ingredients" ON public.ingredients;
DROP POLICY IF EXISTS "Users can update own ingredients" ON public.ingredients;
DROP POLICY IF EXISTS "Users can delete own ingredients" ON public.ingredients;
CREATE POLICY "Public read ingredients" ON public.ingredients FOR SELECT USING (true);
CREATE POLICY "Public insert ingredients" ON public.ingredients FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update ingredients" ON public.ingredients FOR UPDATE USING (true);
CREATE POLICY "Public delete ingredients" ON public.ingredients FOR DELETE USING (true);

DROP POLICY IF EXISTS "Users can view own meal logs" ON public.meal_logs;
DROP POLICY IF EXISTS "Users can insert own meal logs" ON public.meal_logs;
DROP POLICY IF EXISTS "Users can update own meal logs" ON public.meal_logs;
DROP POLICY IF EXISTS "Users can delete own meal logs" ON public.meal_logs;
CREATE POLICY "Public read meal logs" ON public.meal_logs FOR SELECT USING (true);
CREATE POLICY "Public insert meal logs" ON public.meal_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update meal logs" ON public.meal_logs FOR UPDATE USING (true);
CREATE POLICY "Public delete meal logs" ON public.meal_logs FOR DELETE USING (true);

DELETE FROM public.recipe_ingredients;
DELETE FROM public.recipes;

WITH new_recipes AS (
  INSERT INTO public.recipes (name, instructions, prep_time, difficulty_level) VALUES
  ('Vegan Chickpea Curry','1. Heat oil. 2. Saute onion and garlic 3 min. 3. Add spices. 4. Add chickpeas and tomatoes. 5. Simmer 20 min. 6. Serve with rice.',30,'Easy'),
  ('Grilled Chicken Broccoli Bowl','1. Marinate chicken. 2. Grill 6-7 min per side. 3. Steam broccoli. 4. Cook rice. 5. Assemble bowl.',35,'Easy'),
  ('Spinach and Egg Frittata','1. Preheat oven 375F. 2. Saute spinach and onion. 3. Beat eggs with cheese. 4. Bake 15 min.',25,'Medium'),
  ('Lentil Soup','1. Saute onion, garlic, carrots. 2. Add lentils and broth. 3. Simmer 25 min. 4. Season and serve.',40,'Easy'),
  ('Roasted Salmon with Asparagus','1. Preheat oven 400F. 2. Season salmon. 3. Toss asparagus in oil. 4. Roast 15-18 min.',25,'Easy'),
  ('Beef Stir-Fry','1. Slice beef. 2. Stir-fry 3 min. 3. Add vegetables. 4. Add sauces. 5. Serve over rice.',20,'Medium'),
  ('Blueberry Greek Yogurt Parfait','1. Layer yogurt. 2. Add blueberries. 3. Drizzle honey. 4. Top with granola. 5. Chill 30 min.',10,'Easy'),
  ('Banana Overnight Oats','1. Combine oats, milk, chia seeds. 2. Add honey. 3. Refrigerate overnight. 4. Top with banana.',5,'Easy'),
  ('Tofu Teriyaki Bowl','1. Press and cube tofu. 2. Pan-fry until golden. 3. Make teriyaki sauce. 4. Serve over rice.',30,'Medium'),
  ('Pasta Marinara','1. Boil pasta. 2. Saute garlic. 3. Add marinara, simmer 10 min. 4. Toss with pasta.',20,'Easy'),
  ('Sweet Potato Black Bean Tacos','1. Roast sweet potato. 2. Season beans. 3. Warm tortillas. 4. Assemble with avocado and salsa.',35,'Easy'),
  ('Quinoa Power Bowl','1. Cook quinoa in broth. 2. Roast vegetables. 3. Prepare tahini dressing. 4. Assemble bowl.',40,'Medium'),
  ('Kale Caesar Salad','1. Massage kale. 2. Make dressing. 3. Toss kale. 4. Add croutons and chickpeas.',15,'Easy'),
  ('Veggie Omelette','1. Whisk eggs. 2. Saute vegetables. 3. Pour eggs over veggies. 4. Fold and add cheese.',15,'Easy'),
  ('Banana Smoothie Bowl','1. Blend frozen bananas with milk. 2. Pour into bowl. 3. Top with granola and fruit.',10,'Easy'),
  ('Garlic Butter Shrimp Pasta','1. Cook pasta. 2. Saute garlic in butter. 3. Add shrimp. 4. Toss with pasta and lemon.',25,'Medium'),
  ('Coconut Lentil Dal','1. Saute aromatics. 2. Add lentils and coconut milk. 3. Season. 4. Simmer 20 min. 5. Add spinach.',35,'Easy'),
  ('Chicken Caesar Wrap','1. Grill chicken. 2. Slice thin. 3. Toss romaine in dressing. 4. Roll in tortilla.',20,'Easy'),
  ('Tomato Basil Bruschetta','1. Dice tomatoes with basil and garlic. 2. Toast baguette. 3. Top with tomato mixture.',15,'Easy'),
  ('Mushroom Risotto','1. Saute shallots. 2. Toast rice. 3. Add broth ladle by ladle. 4. Fold in mushrooms.',45,'Hard'),
  ('Avocado Toast with Poached Egg','1. Toast bread. 2. Mash avocado. 3. Poach eggs. 4. Spread and top with egg.',12,'Medium'),
  ('Cauliflower Fried Rice','1. Pulse cauliflower. 2. Stir-fry garlic and ginger. 3. Add veggies. 4. Scramble eggs. 5. Add soy sauce.',20,'Medium')
  RETURNING id, name
)
INSERT INTO public.recipe_ingredients (recipe_id, ingredient_name, quantity)
SELECT nr.id, x.ingredient_name, x.qty
FROM new_recipes nr
JOIN (VALUES
  ('Vegan Chickpea Curry','Chickpeas','400 g'),('Vegan Chickpea Curry','Tomatoes','300 g'),('Vegan Chickpea Curry','Onions','150 g'),('Vegan Chickpea Curry','Garlic','10 g'),('Vegan Chickpea Curry','Coconut Oil','15 ml'),
  ('Grilled Chicken Broccoli Bowl','Chicken Breast','300 g'),('Grilled Chicken Broccoli Bowl','Broccoli','200 g'),('Grilled Chicken Broccoli Bowl','Rice','200 g'),('Grilled Chicken Broccoli Bowl','Olive Oil','15 ml'),('Grilled Chicken Broccoli Bowl','Garlic','5 g'),
  ('Spinach and Egg Frittata','Spinach','150 g'),('Spinach and Egg Frittata','Eggs','4 pcs'),('Spinach and Egg Frittata','Cheddar Cheese','50 g'),('Spinach and Egg Frittata','Onions','80 g'),
  ('Lentil Soup','Lentils','300 g'),('Lentil Soup','Onions','100 g'),('Lentil Soup','Garlic','8 g'),('Lentil Soup','Olive Oil','10 ml'),
  ('Roasted Salmon with Asparagus','Salmon Fillet','200 g'),('Roasted Salmon with Asparagus','Asparagus','150 g'),('Roasted Salmon with Asparagus','Olive Oil','15 ml'),
  ('Beef Stir-Fry','Ground Beef','250 g'),('Beef Stir-Fry','Onions','100 g'),('Beef Stir-Fry','Garlic','8 g'),('Beef Stir-Fry','Rice','150 g'),
  ('Blueberry Greek Yogurt Parfait','Greek Yogurt','200 g'),('Blueberry Greek Yogurt Parfait','Blueberries','100 g'),('Blueberry Greek Yogurt Parfait','Honey','20 ml'),
  ('Banana Overnight Oats','Oats','80 g'),('Banana Overnight Oats','Almond Milk','200 ml'),('Banana Overnight Oats','Banana','1 pcs'),('Banana Overnight Oats','Honey','15 ml'),
  ('Tofu Teriyaki Bowl','Tofu','200 g'),('Tofu Teriyaki Bowl','Soy Sauce','40 ml'),('Tofu Teriyaki Bowl','Rice','150 g'),
  ('Pasta Marinara','Pasta','200 g'),('Pasta Marinara','Marinara Sauce','200 ml'),('Pasta Marinara','Garlic','5 g'),('Pasta Marinara','Olive Oil','10 ml'),
  ('Sweet Potato Black Bean Tacos','Sweet Potato','300 g'),('Sweet Potato Black Bean Tacos','Black Beans','200 g'),
  ('Quinoa Power Bowl','Quinoa','200 g'),
  ('Kale Caesar Salad','Kale','150 g'),('Kale Caesar Salad','Chickpeas','100 g'),('Kale Caesar Salad','Olive Oil','15 ml'),
  ('Veggie Omelette','Eggs','3 pcs'),('Veggie Omelette','Spinach','80 g'),('Veggie Omelette','Cheddar Cheese','40 g'),
  ('Banana Smoothie Bowl','Banana','2 pcs'),('Banana Smoothie Bowl','Almond Milk','100 ml'),('Banana Smoothie Bowl','Honey','15 ml'),
  ('Coconut Lentil Dal','Lentils','250 g'),('Coconut Lentil Dal','Coconut Oil','15 ml'),('Coconut Lentil Dal','Spinach','100 g'),
  ('Chicken Caesar Wrap','Chicken Breast','300 g'),('Chicken Caesar Wrap','Olive Oil','10 ml'),
  ('Tomato Basil Bruschetta','Tomatoes','300 g'),('Tomato Basil Bruschetta','Garlic','5 g'),('Tomato Basil Bruschetta','Olive Oil','20 ml'),
  ('Avocado Toast with Poached Egg','Eggs','2 pcs'),('Avocado Toast with Poached Egg','Olive Oil','10 ml'),
  ('Cauliflower Fried Rice','Rice','200 g'),('Cauliflower Fried Rice','Eggs','2 pcs'),('Cauliflower Fried Rice','Soy Sauce','30 ml')
) AS x(recipe_name, ingredient_name, qty) ON x.recipe_name = nr.name;

DELETE FROM public.ingredients WHERE user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO public.ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit) VALUES
('11111111-1111-1111-1111-111111111111','Spinach',300,'g','2026-08-01','Fridge',23),
('11111111-1111-1111-1111-111111111111','Almond Milk',1,'L','2026-08-05','Fridge',17),
('11111111-1111-1111-1111-111111111111','Chickpeas',500,'g','2027-01-10','Pantry',164),
('11111111-1111-1111-1111-111111111111','Chicken Breast',600,'g','2026-05-15','Fridge',165),
('11111111-1111-1111-1111-111111111111','Rice',2,'kg','2027-06-01','Pantry',130),
('11111111-1111-1111-1111-111111111111','Broccoli',400,'g','2026-05-20','Fridge',55),
('11111111-1111-1111-1111-111111111111','Eggs',12,'pcs','2026-05-25','Fridge',78),
('11111111-1111-1111-1111-111111111111','Cheddar Cheese',250,'g','2026-06-15','Fridge',402),
('11111111-1111-1111-1111-111111111111','Tomatoes',500,'g','2026-05-10','Fridge',18),
('11111111-1111-1111-1111-111111111111','Lentils',800,'g','2027-03-01','Pantry',116),
('11111111-1111-1111-1111-111111111111','Coconut Oil',500,'ml','2027-12-01','Pantry',862),
('11111111-1111-1111-1111-111111111111','Kale',250,'g','2026-05-08','Fridge',49),
('11111111-1111-1111-1111-111111111111','Salmon Fillet',400,'g','2026-05-12','Freezer',208),
('11111111-1111-1111-1111-111111111111','Asparagus',300,'g','2026-05-09','Fridge',20),
('11111111-1111-1111-1111-111111111111','Olive Oil',750,'ml','2027-09-01','Pantry',884),
('11111111-1111-1111-1111-111111111111','Onions',1,'kg','2026-08-20','Pantry',40),
('11111111-1111-1111-1111-111111111111','Garlic',200,'g','2026-09-01','Pantry',149),
('11111111-1111-1111-1111-111111111111','Greek Yogurt',500,'g','2026-05-18','Fridge',59),
('11111111-1111-1111-1111-111111111111','Honey',300,'ml','2028-01-01','Pantry',304),
('11111111-1111-1111-1111-111111111111','Blueberries',250,'g','2026-05-11','Fridge',57),
('11111111-1111-1111-1111-111111111111','Oats',1,'kg','2027-04-01','Pantry',389),
('11111111-1111-1111-1111-111111111111','Banana',6,'pcs','2026-05-07','Pantry',89),
('11111111-1111-1111-1111-111111111111','Tofu',400,'g','2026-05-19','Fridge',76),
('11111111-1111-1111-1111-111111111111','Soy Sauce',500,'ml','2027-10-01','Pantry',60),
('11111111-1111-1111-1111-111111111111','Pasta',500,'g','2027-07-01','Pantry',158),
('11111111-1111-1111-1111-111111111111','Marinara Sauce',400,'ml','2026-10-01','Pantry',45),
('11111111-1111-1111-1111-111111111111','Sweet Potato',800,'g','2026-08-15','Pantry',86),
('11111111-1111-1111-1111-111111111111','Black Beans',600,'g','2027-02-01','Pantry',132),
('11111111-1111-1111-1111-111111111111','Quinoa',500,'g','2027-05-01','Pantry',120);

DELETE FROM public.meal_logs WHERE user_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO public.meal_logs (user_id, recipe_id, consumed_date, rating)
SELECT '11111111-1111-1111-1111-111111111111', r.id, d.consumed_date, d.rating
FROM (VALUES
  ('Vegan Chickpea Curry','2026-04-01'::date,5),
  ('Lentil Soup','2026-04-03'::date,4),
  ('Kale Caesar Salad','2026-04-05'::date,5),
  ('Coconut Lentil Dal','2026-04-08'::date,4),
  ('Grilled Chicken Broccoli Bowl','2026-04-10'::date,5),
  ('Pasta Marinara','2026-04-12'::date,3),
  ('Spinach and Egg Frittata','2026-04-14'::date,4),
  ('Blueberry Greek Yogurt Parfait','2026-04-16'::date,5),
  ('Banana Overnight Oats','2026-04-18'::date,4),
  ('Roasted Salmon with Asparagus','2026-04-20'::date,5),
  ('Tofu Teriyaki Bowl','2026-04-22'::date,4),
  ('Veggie Omelette','2026-04-24'::date,4),
  ('Quinoa Power Bowl','2026-04-26'::date,5),
  ('Sweet Potato Black Bean Tacos','2026-04-28'::date,4)
) AS d(recipe_name, consumed_date, rating)
JOIN public.recipes r ON r.name = d.recipe_name;
