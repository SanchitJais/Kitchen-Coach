-- ============================================================
-- KITCHEN COACH APP - Complete Database System
-- Based on ER Diagram and Project Documentation
-- ============================================================

DROP TABLE IF EXISTS meal_logs CASCADE;
DROP TABLE IF EXISTS recipe_ingredients CASCADE;
DROP TABLE IF EXISTS recipes CASCADE;
DROP TABLE IF EXISTS ingredients CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================
-- TABLE: users
-- ============================================================
CREATE TABLE users (
    user_id           SERIAL PRIMARY KEY,
    email             VARCHAR(255) UNIQUE NOT NULL,
    password_hash     VARCHAR(255) NOT NULL,
    name              VARCHAR(100),
    dietary_preferences JSONB,
    created_at        TIMESTAMP DEFAULT NOW()
);

INSERT INTO users (email, password_hash, name, dietary_preferences, created_at) VALUES
('alice.johnson@email.com',   '$2b$12$abc123hashed', 'Alice Johnson',   '{"vegan":true,"gluten_free":false,"allergies":["nuts"]}',              '2024-01-05 09:00:00'),
('bob.smith@email.com',       '$2b$12$def456hashed', 'Bob Smith',       '{"vegan":false,"gluten_free":true,"allergies":[]}',                    '2024-01-08 10:30:00'),
('carol.white@email.com',     '$2b$12$ghi789hashed', 'Carol White',     '{"vegan":false,"gluten_free":false,"allergies":["dairy"]}',            '2024-01-10 14:15:00'),
('david.lee@email.com',       '$2b$12$jkl012hashed', 'David Lee',       '{"vegan":true,"gluten_free":true,"allergies":[]}',                     '2024-01-12 08:45:00'),
('eva.martinez@email.com',    '$2b$12$mno345hashed', 'Eva Martinez',    '{"vegan":false,"gluten_free":false,"allergies":["shellfish"]}',        '2024-01-15 11:20:00'),
('frank.brown@email.com',     '$2b$12$pqr678hashed', 'Frank Brown',     '{"vegan":false,"gluten_free":false,"allergies":[]}',                   '2024-01-18 16:00:00'),
('grace.wilson@email.com',    '$2b$12$stu901hashed', 'Grace Wilson',    '{"vegan":false,"vegetarian":true,"allergies":["peanuts"]}',            '2024-01-20 09:30:00'),
('henry.taylor@email.com',    '$2b$12$vwx234hashed', 'Henry Taylor',    '{"vegan":false,"gluten_free":true,"allergies":["eggs"]}',              '2024-01-22 13:45:00'),
('isabella.davis@email.com',  '$2b$12$yza567hashed', 'Isabella Davis',  '{"vegan":true,"gluten_free":false,"allergies":[]}',                    '2024-01-25 10:10:00'),
('jack.miller@email.com',     '$2b$12$bcd890hashed', 'Jack Miller',     '{"vegan":false,"gluten_free":false,"allergies":["soy"]}',              '2024-01-28 15:30:00'),
('karen.moore@email.com',     '$2b$12$efg123hashed', 'Karen Moore',     '{"vegan":false,"vegetarian":true,"allergies":[]}',                     '2024-02-01 08:00:00'),
('liam.anderson@email.com',   '$2b$12$hij456hashed', 'Liam Anderson',   '{"vegan":false,"gluten_free":false,"allergies":["wheat"]}',            '2024-02-03 12:20:00'),
('mia.thomas@email.com',      '$2b$12$klm789hashed', 'Mia Thomas',      '{"vegan":true,"gluten_free":true,"allergies":[]}',                     '2024-02-05 17:00:00'),
('noah.jackson@email.com',    '$2b$12$nop012hashed', 'Noah Jackson',    '{"vegan":false,"gluten_free":false,"allergies":["fish"]}',             '2024-02-08 09:45:00'),
('olivia.harris@email.com',   '$2b$12$qrs345hashed', 'Olivia Harris',   '{"vegan":false,"gluten_free":false,"allergies":[]}',                   '2024-02-10 14:30:00'),
('peter.garcia@email.com',    '$2b$12$tuv678hashed', 'Peter Garcia',    '{"vegan":false,"vegetarian":false,"allergies":["peanuts","tree_nuts"]}','2024-02-12 11:00:00'),
('quinn.martinez@email.com',  '$2b$12$wxy901hashed', 'Quinn Martinez',  '{"vegan":true,"gluten_free":false,"allergies":[]}',                    '2024-02-15 16:45:00'),
('rachel.robinson@email.com', '$2b$12$zab234hashed', 'Rachel Robinson', '{"vegan":false,"gluten_free":true,"allergies":["dairy","eggs"]}',      '2024-02-18 10:15:00'),
('sam.clark@email.com',       '$2b$12$cde567hashed', 'Sam Clark',       '{"vegan":false,"gluten_free":false,"allergies":[]}',                   '2024-02-20 13:00:00'),
('tina.lewis@email.com',      '$2b$12$fgh890hashed', 'Tina Lewis',      '{"vegan":false,"vegetarian":true,"allergies":["sesame"]}',             '2024-02-22 09:20:00'),
('umar.walker@email.com',     '$2b$12$ijk123hashed', 'Umar Walker',     '{"vegan":false,"gluten_free":false,"allergies":[]}',                   '2024-02-25 15:10:00'),
('vera.hall@email.com',       '$2b$12$lmn456hashed', 'Vera Hall',       '{"vegan":true,"gluten_free":true,"allergies":["corn"]}',               '2024-02-28 11:30:00');


-- ============================================================
-- TABLE: ingredients
-- ============================================================
CREATE TABLE ingredients (
    ingredient_id   SERIAL PRIMARY KEY,
    user_id         INT REFERENCES users(user_id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    quantity        DECIMAL(10,2),
    unit            VARCHAR(20),
    expiration_date DATE,
    location        VARCHAR(50),
    calories_per_unit INT,
    added_date      TIMESTAMP DEFAULT NOW()
);

INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit, added_date) VALUES
(1,  'Spinach',        300.00, 'g',   '2025-08-01', 'refrigerator', 23,  '2025-07-25 08:00:00'),
(1,  'Almond Milk',    1.00,   'l',   '2025-08-05', 'refrigerator', 17,  '2025-07-25 08:05:00'),
(1,  'Chickpeas',      500.00, 'g',   '2026-01-10', 'pantry',       164, '2025-07-20 09:00:00'),
(2,  'Chicken Breast', 600.00, 'g',   '2025-07-28', 'refrigerator', 165, '2025-07-24 10:00:00'),
(2,  'Rice',           2.00,   'kg',  '2026-06-01', 'pantry',       130, '2025-07-10 11:00:00'),
(2,  'Broccoli',       400.00, 'g',   '2025-07-30', 'refrigerator', 55,  '2025-07-23 09:30:00'),
(3,  'Eggs',           12.00,  'pcs', '2025-08-10', 'refrigerator', 78,  '2025-07-22 07:45:00'),
(3,  'Cheddar Cheese', 250.00, 'g',   '2025-08-15', 'refrigerator', 402, '2025-07-20 08:30:00'),
(3,  'Tomatoes',       500.00, 'g',   '2025-07-31', 'refrigerator', 18,  '2025-07-24 10:15:00'),
(4,  'Lentils',        800.00, 'g',   '2026-03-01', 'pantry',       116, '2025-07-15 09:00:00'),
(4,  'Coconut Oil',    500.00, 'ml',  '2026-12-01', 'pantry',       862, '2025-07-10 10:00:00'),
(4,  'Kale',           250.00, 'g',   '2025-07-29', 'refrigerator', 49,  '2025-07-24 08:00:00'),
(5,  'Salmon Fillet',  400.00, 'g',   '2025-07-27', 'freezer',      208, '2025-07-20 11:00:00'),
(5,  'Asparagus',      300.00, 'g',   '2025-07-28', 'refrigerator', 20,  '2025-07-24 09:00:00'),
(5,  'Olive Oil',      750.00, 'ml',  '2026-09-01', 'pantry',       884, '2025-07-01 10:00:00'),
(6,  'Ground Beef',    500.00, 'g',   '2025-07-26', 'freezer',      250, '2025-07-22 12:00:00'),
(6,  'Onions',         1.00,   'kg',  '2025-08-20', 'pantry',       40,  '2025-07-15 08:00:00'),
(6,  'Garlic',         200.00, 'g',   '2025-09-01', 'pantry',       149, '2025-07-10 09:00:00'),
(7,  'Greek Yogurt',   500.00, 'g',   '2025-08-03', 'refrigerator', 59,  '2025-07-23 07:30:00'),
(7,  'Honey',          300.00, 'ml',  '2027-01-01', 'pantry',       304, '2025-07-01 10:00:00'),
(7,  'Blueberries',    250.00, 'g',   '2025-07-30', 'refrigerator', 57,  '2025-07-24 08:30:00'),
(8,  'Oats',           1.00,   'kg',  '2026-04-01', 'pantry',       389, '2025-07-05 09:00:00'),
(8,  'Banana',         6.00,   'pcs', '2025-07-29', 'pantry',       89,  '2025-07-24 10:00:00'),
(9,  'Tofu',           400.00, 'g',   '2025-08-02', 'refrigerator', 76,  '2025-07-23 08:00:00'),
(9,  'Soy Sauce',      500.00, 'ml',  '2026-10-01', 'pantry',       60,  '2025-07-10 09:00:00'),
(10, 'Pasta',          500.00, 'g',   '2026-07-01', 'pantry',       158, '2025-07-12 10:00:00'),
(10, 'Marinara Sauce', 400.00, 'ml',  '2025-10-01', 'pantry',       45,  '2025-07-15 11:00:00'),
(11, 'Sweet Potato',   800.00, 'g',   '2025-08-15', 'pantry',       86,  '2025-07-18 09:00:00'),
(12, 'Black Beans',    600.00, 'g',   '2026-02-01', 'pantry',       132, '2025-07-20 08:30:00'),
(13, 'Quinoa',         500.00, 'g',   '2026-05-01', 'pantry',       120, '2025-07-22 09:00:00');


-- ============================================================
-- TABLE: recipes
-- ============================================================
CREATE TABLE recipes (
    recipe_id        SERIAL PRIMARY KEY,
    name             VARCHAR(200) NOT NULL,
    instructions     TEXT,
    prep_time        INT,
    nutritional_info JSONB,
    difficulty_level VARCHAR(20)
);

INSERT INTO recipes (name, instructions, prep_time, nutritional_info, difficulty_level) VALUES
('Vegan Chickpea Curry',
 '1. Heat oil. 2. Saute onion and garlic 3 min. 3. Add spices. 4. Add chickpeas and tomatoes. 5. Simmer 20 min. 6. Serve with rice.',
 30, '{"calories":380,"protein":15,"carbs":52,"fat":10,"fiber":12}', 'Easy'),

('Grilled Chicken Broccoli Bowl',
 '1. Marinate chicken. 2. Grill 6-7 min per side. 3. Steam broccoli. 4. Cook rice. 5. Assemble bowl.',
 35, '{"calories":450,"protein":48,"carbs":38,"fat":12,"fiber":6}', 'Easy'),

('Spinach and Egg Frittata',
 '1. Preheat oven 375F. 2. Saute spinach and onion. 3. Beat eggs with cheese. 4. Bake 15 min.',
 25, '{"calories":290,"protein":22,"carbs":8,"fat":19,"fiber":2}', 'Medium'),

('Lentil Soup',
 '1. Saute onion, garlic, carrots. 2. Add lentils and broth. 3. Simmer 25 min. 4. Season and serve.',
 40, '{"calories":320,"protein":18,"carbs":48,"fat":5,"fiber":16}', 'Easy'),

('Roasted Salmon with Asparagus',
 '1. Preheat oven 400F. 2. Season salmon. 3. Toss asparagus in oil. 4. Roast 15-18 min.',
 25, '{"calories":390,"protein":42,"carbs":8,"fat":20,"fiber":4}', 'Easy'),

('Beef Stir-Fry',
 '1. Slice beef. 2. Stir-fry 3 min. 3. Add vegetables. 4. Add sauces. 5. Serve over rice.',
 20, '{"calories":420,"protein":35,"carbs":30,"fat":18,"fiber":3}', 'Medium'),

('Blueberry Greek Yogurt Parfait',
 '1. Layer yogurt. 2. Add blueberries. 3. Drizzle honey. 4. Top with granola. 5. Chill 30 min.',
 10, '{"calories":280,"protein":18,"carbs":42,"fat":4,"fiber":3}', 'Easy'),

('Banana Overnight Oats',
 '1. Combine oats, milk, chia seeds. 2. Add honey. 3. Refrigerate overnight. 4. Top with banana.',
 5,  '{"calories":350,"protein":12,"carbs":60,"fat":8,"fiber":10}', 'Easy'),

('Tofu Teriyaki Bowl',
 '1. Press and cube tofu. 2. Pan-fry until golden. 3. Make teriyaki sauce. 4. Serve over rice.',
 30, '{"calories":400,"protein":20,"carbs":55,"fat":12,"fiber":4}', 'Medium'),

('Pasta Marinara',
 '1. Boil pasta. 2. Saute garlic. 3. Add marinara, simmer 10 min. 4. Toss with pasta.',
 20, '{"calories":430,"protein":14,"carbs":72,"fat":10,"fiber":5}', 'Easy'),

('Sweet Potato Black Bean Tacos',
 '1. Roast sweet potato. 2. Season beans. 3. Warm tortillas. 4. Assemble with avocado and salsa.',
 35, '{"calories":370,"protein":12,"carbs":60,"fat":10,"fiber":14}', 'Easy'),

('Quinoa Power Bowl',
 '1. Cook quinoa in broth. 2. Roast vegetables. 3. Prepare tahini dressing. 4. Assemble bowl.',
 40, '{"calories":420,"protein":16,"carbs":55,"fat":14,"fiber":9}', 'Medium'),

('Kale Caesar Salad',
 '1. Massage kale. 2. Make dressing. 3. Toss kale. 4. Add croutons and chickpeas.',
 15, '{"calories":310,"protein":12,"carbs":28,"fat":18,"fiber":7}', 'Easy'),

('Veggie Omelette',
 '1. Whisk eggs. 2. Saute vegetables. 3. Pour eggs over veggies. 4. Fold and add cheese.',
 15, '{"calories":320,"protein":24,"carbs":10,"fat":22,"fiber":2}', 'Easy'),

('Banana Smoothie Bowl',
 '1. Blend frozen bananas with milk. 2. Pour into bowl. 3. Top with granola and fruit.',
 10, '{"calories":380,"protein":8,"carbs":72,"fat":8,"fiber":8}', 'Easy'),

('Garlic Butter Shrimp Pasta',
 '1. Cook pasta. 2. Saute garlic in butter. 3. Add shrimp. 4. Toss with pasta and lemon.',
 25, '{"calories":480,"protein":32,"carbs":55,"fat":16,"fiber":3}', 'Medium'),

('Coconut Lentil Dal',
 '1. Saute aromatics. 2. Add lentils and coconut milk. 3. Season. 4. Simmer 20 min. 5. Add spinach.',
 35, '{"calories":410,"protein":18,"carbs":52,"fat":14,"fiber":14}', 'Easy'),

('Chicken Caesar Wrap',
 '1. Grill chicken. 2. Slice thin. 3. Toss romaine in dressing. 4. Roll in tortilla.',
 20, '{"calories":490,"protein":40,"carbs":38,"fat":20,"fiber":4}', 'Easy'),

('Tomato Basil Bruschetta',
 '1. Dice tomatoes with basil and garlic. 2. Toast baguette. 3. Top with tomato mixture.',
 15, '{"calories":220,"protein":6,"carbs":32,"fat":8,"fiber":2}', 'Easy'),

('Mushroom Risotto',
 '1. Saute shallots. 2. Toast rice. 3. Add broth ladle by ladle. 4. Fold in mushrooms.',
 45, '{"calories":460,"protein":14,"carbs":70,"fat":14,"fiber":3}', 'Hard'),

('Avocado Toast with Poached Egg',
 '1. Toast bread. 2. Mash avocado. 3. Poach eggs. 4. Spread and top with egg.',
 12, '{"calories":390,"protein":16,"carbs":32,"fat":24,"fiber":8}', 'Medium'),

('Cauliflower Fried Rice',
 '1. Pulse cauliflower. 2. Stir-fry garlic and ginger. 3. Add veggies. 4. Scramble eggs. 5. Add soy sauce.',
 20, '{"calories":260,"protein":14,"carbs":22,"fat":12,"fiber":6}', 'Medium');


-- ============================================================
-- TABLE: recipe_ingredients
-- ============================================================
CREATE TABLE recipe_ingredients (
    recipe_id       INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,
    ingredient_name VARCHAR(100) NOT NULL,
    quantity        DECIMAL(10,2),
    unit            VARCHAR(20),
    PRIMARY KEY (recipe_id, ingredient_name)
);

INSERT INTO recipe_ingredients (recipe_id, ingredient_name, quantity, unit) VALUES
(1,  'Chickpeas',        400.00, 'g'),
(1,  'Tomatoes',         300.00, 'g'),
(1,  'Onions',           150.00, 'g'),
(1,  'Garlic',            10.00, 'g'),
(1,  'Coconut Oil',       15.00, 'ml'),
(2,  'Chicken Breast',   300.00, 'g'),
(2,  'Broccoli',         200.00, 'g'),
(2,  'Rice',             200.00, 'g'),
(2,  'Olive Oil',         15.00, 'ml'),
(2,  'Garlic',             5.00, 'g'),
(3,  'Spinach',          150.00, 'g'),
(3,  'Eggs',               4.00, 'pcs'),
(3,  'Cheddar Cheese',    50.00, 'g'),
(3,  'Onions',            80.00, 'g'),
(4,  'Lentils',          300.00, 'g'),
(4,  'Onions',           100.00, 'g'),
(4,  'Garlic',             8.00, 'g'),
(4,  'Olive Oil',         10.00, 'ml'),
(5,  'Salmon Fillet',    200.00, 'g'),
(5,  'Asparagus',        150.00, 'g'),
(5,  'Olive Oil',         15.00, 'ml'),
(6,  'Ground Beef',      250.00, 'g'),
(6,  'Onions',           100.00, 'g'),
(6,  'Garlic',             8.00, 'g'),
(6,  'Rice',             150.00, 'g'),
(7,  'Greek Yogurt',     200.00, 'g'),
(7,  'Blueberries',      100.00, 'g'),
(7,  'Honey',             20.00, 'ml'),
(8,  'Oats',              80.00, 'g'),
(8,  'Almond Milk',      200.00, 'ml'),
(8,  'Banana',             1.00, 'pcs'),
(8,  'Honey',             15.00, 'ml'),
(9,  'Tofu',             200.00, 'g'),
(9,  'Soy Sauce',         40.00, 'ml'),
(9,  'Rice',             150.00, 'g'),
(10, 'Pasta',            200.00, 'g'),
(10, 'Marinara Sauce',   200.00, 'ml'),
(10, 'Garlic',             5.00, 'g'),
(10, 'Olive Oil',         10.00, 'ml'),
(11, 'Sweet Potato',     300.00, 'g'),
(11, 'Black Beans',      200.00, 'g'),
(12, 'Quinoa',           200.00, 'g'),
(13, 'Kale',             150.00, 'g'),
(13, 'Chickpeas',        100.00, 'g'),
(13, 'Olive Oil',         15.00, 'ml'),
(14, 'Eggs',               3.00, 'pcs'),
(14, 'Spinach',           80.00, 'g'),
(14, 'Cheddar Cheese',    40.00, 'g'),
(15, 'Banana',             2.00, 'pcs'),
(15, 'Almond Milk',      100.00, 'ml'),
(15, 'Honey',             15.00, 'ml'),
(17, 'Lentils',          250.00, 'g'),
(17, 'Coconut Oil',       15.00, 'ml'),
(17, 'Spinach',          100.00, 'g'),
(18, 'Chicken Breast',   300.00, 'g'),
(18, 'Olive Oil',         10.00, 'ml'),
(19, 'Tomatoes',         300.00, 'g'),
(19, 'Garlic',             5.00, 'g'),
(19, 'Olive Oil',         20.00, 'ml'),
(21, 'Eggs',               2.00, 'pcs'),
(21, 'Olive Oil',         10.00, 'ml'),
(22, 'Rice',             200.00, 'g'),
(22, 'Eggs',               2.00, 'pcs'),
(22, 'Soy Sauce',         30.00, 'ml');


-- ============================================================
-- TABLE: meal_logs
-- ============================================================
CREATE TABLE meal_logs (
    log_id        SERIAL PRIMARY KEY,
    user_id       INT REFERENCES users(user_id) ON DELETE CASCADE,
    recipe_id     INT REFERENCES recipes(recipe_id) ON DELETE SET NULL,
    consumed_date DATE,
    rating        INT CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES
(1,   1, '2025-07-01', 5),
(1,   4, '2025-07-03', 4),
(1,  13, '2025-07-05', 5),
(1,  17, '2025-07-08', 4),
(2,   2, '2025-07-02', 5),
(2,   6, '2025-07-04', 4),
(2,  10, '2025-07-06', 3),
(2,  18, '2025-07-09', 5),
(3,   3, '2025-07-01', 4),
(3,   7, '2025-07-03', 5),
(3,  14, '2025-07-07', 4),
(3,  19, '2025-07-10', 3),
(4,   4, '2025-07-02', 5),
(4,   9, '2025-07-05', 4),
(4,  12, '2025-07-08', 5),
(5,   5, '2025-07-01', 5),
(5,  16, '2025-07-04', 4),
(5,  20, '2025-07-07', 3),
(6,   6, '2025-07-02', 4),
(6,  10, '2025-07-06', 4),
(6,  18, '2025-07-09', 5),
(7,   7, '2025-07-03', 5),
(7,   8, '2025-07-05', 4),
(7,  15, '2025-07-08', 5),
(8,   8, '2025-07-01', 4),
(8,  14, '2025-07-04', 3),
(8,  21, '2025-07-07', 4),
(9,   9, '2025-07-02', 5),
(9,  12, '2025-07-05', 4),
(9,  22, '2025-07-09', 5),
(10, 10, '2025-07-03', 3),
(10, 16, '2025-07-06', 4),
(11, 11, '2025-07-01', 5),
(11, 17, '2025-07-04', 4),
(12,  4, '2025-07-02', 5),
(12, 11, '2025-07-07', 4),
(13,  9, '2025-07-01', 5),
(13, 12, '2025-07-05', 5),
(14,  2, '2025-07-03', 4),
(14,  6, '2025-07-06', 3),
(15,  3, '2025-07-02', 4),
(15, 19, '2025-07-05', 5),
(16, 10, '2025-07-04', 3),
(16, 20, '2025-07-08', 4),
(17,  1, '2025-07-01', 5),
(17, 13, '2025-07-06', 4),
(18,  5, '2025-07-03', 5),
(18, 21, '2025-07-07', 4),
(19, 16, '2025-07-02', 4),
(19, 18, '2025-07-05', 5),
(20,  7, '2025-07-04', 5),
(20,  8, '2025-07-07', 4),
(21,  6, '2025-07-03', 4),
(21, 22, '2025-07-06', 5),
(22,  9, '2025-07-01', 5),
(22, 15, '2025-07-05', 4);


-- ============================================================
-- USEFUL QUERIES FOR THE KITCHEN COACH APP
-- ============================================================

-- Q1: Ingredients expiring within the next 3 days (waste prevention alerts)
-- SELECT u.name AS user_name, i.name AS ingredient, i.quantity, i.unit,
--        i.expiration_date, i.location,
--        (i.expiration_date - CURRENT_DATE) AS days_remaining
-- FROM ingredients i JOIN users u ON i.user_id = u.user_id
-- WHERE i.expiration_date <= CURRENT_DATE + INTERVAL '3 days'
-- ORDER BY i.expiration_date;

-- Q2: Recipes a user can cook using their available ingredients (AI recommendation base)
-- SELECT r.name, r.difficulty_level, r.prep_time,
--        COUNT(DISTINCT ri.ingredient_name) AS matched_ingredients
-- FROM recipes r
-- JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
-- JOIN ingredients i ON LOWER(i.name) = LOWER(ri.ingredient_name) AND i.user_id = 1
-- GROUP BY r.recipe_id
-- HAVING COUNT(DISTINCT ri.ingredient_name) >= 2
-- ORDER BY matched_ingredients DESC, r.prep_time;

-- Q3: Top-rated recipes with cook count
-- SELECT r.name, r.difficulty_level,
--        ROUND(AVG(ml.rating), 2) AS avg_rating,
--        COUNT(ml.log_id) AS times_cooked
-- FROM meal_logs ml JOIN recipes r ON ml.recipe_id = r.recipe_id
-- GROUP BY r.recipe_id
-- ORDER BY avg_rating DESC, times_cooked DESC
-- LIMIT 10;

-- Q4: User engagement summary
-- SELECT u.name, COUNT(ml.log_id) AS meals_logged,
--        ROUND(AVG(ml.rating), 1) AS avg_meal_rating
-- FROM users u LEFT JOIN meal_logs ml ON u.user_id = ml.user_id
-- GROUP BY u.user_id
-- ORDER BY meals_logged DESC;

-- Q5: Nutritional overview for a user's ingredient inventory
-- SELECT location, name, quantity, unit, expiration_date,
--        calories_per_unit,
--        ROUND((quantity * calories_per_unit)::numeric, 0) AS total_calories
-- FROM ingredients
-- WHERE user_id = 1
-- ORDER BY location, expiration_date;
