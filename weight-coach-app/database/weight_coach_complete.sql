-- ============================================================
--  WEIGHT COACH APP  ·  Complete Database System
--  Course  : 21CSC205P  Database Management Systems
--  DB      : MySQL 8.0
--  Covers  : DDL · DML · Constraints · Aggregate Functions
--            Sets · Subqueries · Joins · Views
--            Triggers · Cursors · Transactions · Concurrency
-- ============================================================

-- ============================================================
-- SECTION 0 : DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS weight_coach_db;
CREATE DATABASE weight_coach_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE weight_coach_db;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';


-- ============================================================
-- SECTION 1 : DDL – TABLE DEFINITIONS
-- ============================================================

-- ------------------------------------------------------------
-- TABLE 1 : users
-- ------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id             INT           AUTO_INCREMENT PRIMARY KEY,
    email               VARCHAR(255)  UNIQUE        NOT NULL,
    password_hash       VARCHAR(255)                NOT NULL,
    name                VARCHAR(100),
    dietary_preferences JSON,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- TABLE 2 : ingredients
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ingredients;
CREATE TABLE ingredients (
    ingredient_id   INT            AUTO_INCREMENT PRIMARY KEY,
    user_id         INT,
    name            VARCHAR(100)   NOT NULL,
    quantity        DECIMAL(10,2),
    unit            VARCHAR(20),
    expiration_date DATE,
    location        VARCHAR(50),
    calories_per_unit INT,
    added_date      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- TABLE 3 : recipes
-- ------------------------------------------------------------
DROP TABLE IF EXISTS recipes;
CREATE TABLE recipes (
    recipe_id        INT           AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(200)  NOT NULL,
    instructions     TEXT,
    prep_time        INT,
    nutritional_info JSON,
    difficulty_level VARCHAR(20)
);

-- ------------------------------------------------------------
-- TABLE 4 : recipe_ingredients  (junction table — M:N)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS recipe_ingredients;
CREATE TABLE recipe_ingredients (
    recipe_id       INT,
    ingredient_name VARCHAR(100)  NOT NULL,
    quantity        DECIMAL(10,2),
    unit            VARCHAR(20),
    PRIMARY KEY (recipe_id, ingredient_name),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- TABLE 5 : meal_logs
-- ------------------------------------------------------------
DROP TABLE IF EXISTS meal_logs;
CREATE TABLE meal_logs (
    log_id        INT   AUTO_INCREMENT PRIMARY KEY,
    user_id       INT,
    recipe_id     INT,
    consumed_date DATE,
    rating        INT CHECK (rating BETWEEN 1 AND 5),
    FOREIGN KEY (user_id)   REFERENCES users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE SET NULL
);

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- SECTION 2 : DML – DATA INSERTION
-- ============================================================

-- ------------------------------------------------------------
-- 2.1  users  (22 rows)
-- ------------------------------------------------------------
INSERT INTO users (email, password_hash, name, dietary_preferences, created_at) VALUES
('alice.johnson@email.com',   '$2b$12$abc123hashed', 'Alice Johnson',   '{"vegan":true,"gluten_free":false,"allergies":["nuts"]}',               '2024-01-05 09:00:00'),
('bob.smith@email.com',       '$2b$12$def456hashed', 'Bob Smith',       '{"vegan":false,"gluten_free":true,"allergies":[]}',                     '2024-01-08 10:30:00'),
('carol.white@email.com',     '$2b$12$ghi789hashed', 'Carol White',     '{"vegan":false,"gluten_free":false,"allergies":["dairy"]}',             '2024-01-10 14:15:00'),
('david.lee@email.com',       '$2b$12$jkl012hashed', 'David Lee',       '{"vegan":true,"gluten_free":true,"allergies":[]}',                      '2024-01-12 08:45:00'),
('eva.martinez@email.com',    '$2b$12$mno345hashed', 'Eva Martinez',    '{"vegan":false,"gluten_free":false,"allergies":["shellfish"]}',         '2024-01-15 11:20:00'),
('frank.brown@email.com',     '$2b$12$pqr678hashed', 'Frank Brown',     '{"vegan":false,"gluten_free":false,"allergies":[]}',                    '2024-01-18 16:00:00'),
('grace.wilson@email.com',    '$2b$12$stu901hashed', 'Grace Wilson',    '{"vegan":false,"vegetarian":true,"allergies":["peanuts"]}',             '2024-01-20 09:30:00'),
('henry.taylor@email.com',    '$2b$12$vwx234hashed', 'Henry Taylor',    '{"vegan":false,"gluten_free":true,"allergies":["eggs"]}',               '2024-01-22 13:45:00'),
('isabella.davis@email.com',  '$2b$12$yza567hashed', 'Isabella Davis',  '{"vegan":true,"gluten_free":false,"allergies":[]}',                     '2024-01-25 10:10:00'),
('jack.miller@email.com',     '$2b$12$bcd890hashed', 'Jack Miller',     '{"vegan":false,"gluten_free":false,"allergies":["soy"]}',               '2024-01-28 15:30:00'),
('karen.moore@email.com',     '$2b$12$efg123hashed', 'Karen Moore',     '{"vegan":false,"vegetarian":true,"allergies":[]}',                      '2024-02-01 08:00:00'),
('liam.anderson@email.com',   '$2b$12$hij456hashed', 'Liam Anderson',   '{"vegan":false,"gluten_free":false,"allergies":["wheat"]}',             '2024-02-03 12:20:00'),
('mia.thomas@email.com',      '$2b$12$klm789hashed', 'Mia Thomas',      '{"vegan":true,"gluten_free":true,"allergies":[]}',                      '2024-02-05 17:00:00'),
('noah.jackson@email.com',    '$2b$12$nop012hashed', 'Noah Jackson',    '{"vegan":false,"gluten_free":false,"allergies":["fish"]}',              '2024-02-08 09:45:00'),
('olivia.harris@email.com',   '$2b$12$qrs345hashed', 'Olivia Harris',   '{"vegan":false,"gluten_free":false,"allergies":[]}',                    '2024-02-10 14:30:00'),
('peter.garcia@email.com',    '$2b$12$tuv678hashed', 'Peter Garcia',    '{"vegan":false,"vegetarian":false,"allergies":["peanuts","tree_nuts"]}','2024-02-12 11:00:00'),
('quinn.martinez@email.com',  '$2b$12$wxy901hashed', 'Quinn Martinez',  '{"vegan":true,"gluten_free":false,"allergies":[]}',                     '2024-02-15 16:45:00'),
('rachel.robinson@email.com', '$2b$12$zab234hashed', 'Rachel Robinson', '{"vegan":false,"gluten_free":true,"allergies":["dairy","eggs"]}',       '2024-02-18 10:15:00'),
('sam.clark@email.com',       '$2b$12$cde567hashed', 'Sam Clark',       '{"vegan":false,"gluten_free":false,"allergies":[]}',                    '2024-02-20 13:00:00'),
('tina.lewis@email.com',      '$2b$12$fgh890hashed', 'Tina Lewis',      '{"vegan":false,"vegetarian":true,"allergies":["sesame"]}',              '2024-02-22 09:20:00'),
('umar.walker@email.com',     '$2b$12$ijk123hashed', 'Umar Walker',     '{"vegan":false,"gluten_free":false,"allergies":[]}',                    '2024-02-25 15:10:00'),
('vera.hall@email.com',       '$2b$12$lmn456hashed', 'Vera Hall',       '{"vegan":true,"gluten_free":true,"allergies":["corn"]}',                '2024-02-28 11:30:00');


-- ------------------------------------------------------------
-- 2.2  ingredients  (30 rows)
-- ------------------------------------------------------------
INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit, added_date) VALUES
(1,  'Spinach',        300.00, 'g',   '2026-08-01', 'refrigerator', 23,  '2026-04-10 08:00:00'),
(1,  'Almond Milk',      1.00, 'l',   '2026-08-05', 'refrigerator', 17,  '2026-04-10 08:05:00'),
(1,  'Chickpeas',      500.00, 'g',   '2027-01-10', 'pantry',       164, '2026-04-05 09:00:00'),
(2,  'Chicken Breast', 600.00, 'g',   '2026-04-28', 'refrigerator', 165, '2026-04-09 10:00:00'),
(2,  'Rice',             2.00, 'kg',  '2027-06-01', 'pantry',       130, '2026-03-10 11:00:00'),
(2,  'Broccoli',       400.00, 'g',   '2026-04-20', 'refrigerator', 55,  '2026-04-08 09:30:00'),
(3,  'Eggs',            12.00, 'pcs', '2026-05-10', 'refrigerator', 78,  '2026-04-07 07:45:00'),
(3,  'Cheddar Cheese', 250.00, 'g',   '2026-05-15', 'refrigerator', 402, '2026-04-05 08:30:00'),
(3,  'Tomatoes',       500.00, 'g',   '2026-04-20', 'refrigerator', 18,  '2026-04-09 10:15:00'),
(4,  'Lentils',        800.00, 'g',   '2027-03-01', 'pantry',       116, '2026-03-15 09:00:00'),
(4,  'Coconut Oil',    500.00, 'ml',  '2027-12-01', 'pantry',       862, '2026-03-10 10:00:00'),
(4,  'Kale',           250.00, 'g',   '2026-04-19', 'refrigerator', 49,  '2026-04-09 08:00:00'),
(5,  'Salmon Fillet',  400.00, 'g',   '2026-04-20', 'freezer',      208, '2026-04-05 11:00:00'),
(5,  'Asparagus',      300.00, 'g',   '2026-04-22', 'refrigerator', 20,  '2026-04-09 09:00:00'),
(5,  'Olive Oil',      750.00, 'ml',  '2027-09-01', 'pantry',       884, '2026-01-01 10:00:00'),
(6,  'Ground Beef',    500.00, 'g',   '2026-04-26', 'freezer',      250, '2026-04-07 12:00:00'),
(6,  'Onions',           1.00, 'kg',  '2026-08-20', 'pantry',       40,  '2026-03-15 08:00:00'),
(6,  'Garlic',         200.00, 'g',   '2026-09-01', 'pantry',       149, '2026-03-10 09:00:00'),
(7,  'Greek Yogurt',   500.00, 'g',   '2026-05-03', 'refrigerator', 59,  '2026-04-08 07:30:00'),
(7,  'Honey',          300.00, 'ml',  '2028-01-01', 'pantry',       304, '2026-01-01 10:00:00'),
(7,  'Blueberries',    250.00, 'g',   '2026-04-20', 'refrigerator', 57,  '2026-04-09 08:30:00'),
(8,  'Oats',             1.00, 'kg',  '2027-04-01', 'pantry',       389, '2026-02-05 09:00:00'),
(8,  'Banana',           6.00, 'pcs', '2026-04-19', 'pantry',       89,  '2026-04-09 10:00:00'),
(9,  'Tofu',           400.00, 'g',   '2026-05-02', 'refrigerator', 76,  '2026-04-08 08:00:00'),
(9,  'Soy Sauce',      500.00, 'ml',  '2027-10-01', 'pantry',       60,  '2026-03-10 09:00:00'),
(10, 'Pasta',          500.00, 'g',   '2027-07-01', 'pantry',       158, '2026-03-12 10:00:00'),
(10, 'Marinara Sauce', 400.00, 'ml',  '2026-10-01', 'pantry',       45,  '2026-03-15 11:00:00'),
(11, 'Sweet Potato',   800.00, 'g',   '2026-05-15', 'pantry',       86,  '2026-04-03 09:00:00'),
(12, 'Black Beans',    600.00, 'g',   '2027-02-01', 'pantry',       132, '2026-04-05 08:30:00'),
(13, 'Quinoa',         500.00, 'g',   '2027-05-01', 'pantry',       120, '2026-04-07 09:00:00');


-- ------------------------------------------------------------
-- 2.3  recipes  (22 rows)
-- ------------------------------------------------------------
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
  5, '{"calories":350,"protein":12,"carbs":60,"fat":8,"fiber":10}', 'Easy'),

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


-- ------------------------------------------------------------
-- 2.4  recipe_ingredients
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- 2.5  meal_logs  (55 rows)
-- ------------------------------------------------------------
INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES
(1,   1, '2026-01-01', 5),
(1,   4, '2026-01-03', 4),
(1,  13, '2026-01-05', 5),
(1,  17, '2026-01-08', 4),
(2,   2, '2026-01-02', 5),
(2,   6, '2026-01-04', 4),
(2,  10, '2026-01-06', 3),
(2,  18, '2026-01-09', 5),
(3,   3, '2026-01-01', 4),
(3,   7, '2026-01-03', 5),
(3,  14, '2026-01-07', 4),
(3,  19, '2026-01-10', 3),
(4,   4, '2026-01-02', 5),
(4,   9, '2026-01-05', 4),
(4,  12, '2026-01-08', 5),
(5,   5, '2026-01-01', 5),
(5,  16, '2026-01-04', 4),
(5,  20, '2026-01-07', 3),
(6,   6, '2026-01-02', 4),
(6,  10, '2026-01-06', 4),
(6,  18, '2026-01-09', 5),
(7,   7, '2026-01-03', 5),
(7,   8, '2026-01-05', 4),
(7,  15, '2026-01-08', 5),
(8,   8, '2026-01-01', 4),
(8,  14, '2026-01-04', 3),
(8,  21, '2026-01-07', 4),
(9,   9, '2026-01-02', 5),
(9,  12, '2026-01-05', 4),
(9,  22, '2026-01-09', 5),
(10, 10, '2026-01-03', 3),
(10, 16, '2026-01-06', 4),
(11, 11, '2026-01-01', 5),
(11, 17, '2026-01-04', 4),
(12,  4, '2026-01-02', 5),
(12, 11, '2026-01-07', 4),
(13,  9, '2026-01-01', 5),
(13, 12, '2026-01-05', 5),
(14,  2, '2026-01-03', 4),
(14,  6, '2026-01-06', 3),
(15,  3, '2026-01-02', 4),
(15, 19, '2026-01-05', 5),
(16, 10, '2026-01-04', 3),
(16, 20, '2026-01-08', 4),
(17,  1, '2026-01-01', 5),
(17, 13, '2026-01-06', 4),
(18,  5, '2026-01-03', 5),
(18, 21, '2026-01-07', 4),
(19, 16, '2026-01-02', 4),
(19, 18, '2026-01-05', 5),
(20,  7, '2026-01-04', 5),
(20,  8, '2026-01-07', 4),
(21,  6, '2026-01-03', 4),
(21, 22, '2026-01-06', 5),
(22,  9, '2026-01-01', 5);


-- ============================================================
-- SECTION 3 : CONSTRAINT QUERIES  (Chapter 3.1)
-- ============================================================

-- Q1: Show columns and constraints on users table
DESCRIBE users;

-- Q2: Show columns and constraints on meal_logs table
DESCRIBE meal_logs;

-- Q3: Test UNIQUE constraint — duplicate email (will fail as expected)
-- INSERT INTO users (email, password_hash, name)
-- VALUES ('alice.johnson@email.com', 'test', 'Duplicate Alice');

-- Q4: Test CHECK constraint — rating out of range (will fail as expected)
-- INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating)
-- VALUES (1, 1, CURDATE(), 10);

-- Q5: Test FOREIGN KEY — referencing non-existent user_id (will fail)
-- INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
-- VALUES (999, 'Ghost Item', 1, 'g', '2027-12-01', 'pantry', 0);

-- Q6: Test ON DELETE CASCADE — delete user 22 cascades to ingredients/meal_logs
-- DELETE FROM users WHERE user_id = 22;
-- SELECT * FROM ingredients WHERE user_id = 22;  -- returns 0 rows

-- Q7: Ingredients expiring within the next 3 days
SELECT i.name AS ingredient, i.expiration_date,
       DATEDIFF(i.expiration_date, CURDATE()) AS days_left
FROM ingredients i
WHERE i.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
ORDER BY i.expiration_date;

-- Q8: Get recipes with their ingredients
SELECT r.name AS recipe, ri.ingredient_name, ri.quantity, ri.unit
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
ORDER BY r.name, ri.ingredient_name;


-- ============================================================
-- SECTION 4 : AGGREGATE FUNCTION QUERIES  (Chapter 3.2)
-- ============================================================

-- Q1: Count total number of users
SELECT COUNT(*) AS total_users FROM users;

-- Q2: Count ingredients per user (with user name)
SELECT u.name, COUNT(i.ingredient_id) AS total_ingredients
FROM users u
LEFT JOIN ingredients i ON u.user_id = i.user_id
GROUP BY u.user_id, u.name
ORDER BY total_ingredients DESC;

-- Q3: Total calories across entire inventory
SELECT ROUND(SUM(quantity * calories_per_unit), 0) AS total_calories
FROM ingredients;

-- Q4: Average rating per recipe
SELECT r.name AS recipe,
       ROUND(AVG(ml.rating), 2) AS avg_rating,
       COUNT(ml.log_id) AS times_cooked
FROM recipes r
JOIN meal_logs ml ON r.recipe_id = ml.recipe_id
GROUP BY r.recipe_id, r.name
ORDER BY avg_rating DESC;

-- Q5: User who logged the most meals
SELECT u.name, COUNT(ml.log_id) AS meals_logged
FROM users u
JOIN meal_logs ml ON u.user_id = ml.user_id
GROUP BY u.user_id, u.name
ORDER BY meals_logged DESC
LIMIT 1;

-- Q6: MIN, MAX, AVG prep time across all recipes
SELECT MIN(prep_time) AS min_prep,
       MAX(prep_time) AS max_prep,
       ROUND(AVG(prep_time), 1) AS avg_prep
FROM recipes;

-- Q7: Ingredient count by storage location
SELECT location, COUNT(*) AS ingredient_count
FROM ingredients
GROUP BY location
ORDER BY ingredient_count DESC;


-- ============================================================
-- SECTION 5 : SET OPERATION QUERIES  (Chapter 3.3)
-- ============================================================

-- Q1: INTERSECT equivalent — ingredients common to inventory and recipes
SELECT DISTINCT i.name AS ingredient_in_both
FROM ingredients i
INNER JOIN recipe_ingredients ri ON i.name = ri.ingredient_name;

-- Q2: EXCEPT equivalent — inventory items NOT used in any recipe
SELECT DISTINCT i.name AS only_in_inventory
FROM ingredients i
LEFT JOIN recipe_ingredients ri ON i.name = ri.ingredient_name
WHERE ri.ingredient_name IS NULL;

-- Q3: UNION — all unique ingredient names from both tables
SELECT name AS item_name, 'Inventory' AS source FROM ingredients
UNION
SELECT ingredient_name, 'Recipe'    AS source FROM recipe_ingredients;

-- Q4: Reverse EXCEPT — recipe ingredients NOT available in inventory
SELECT DISTINCT ri.ingredient_name AS missing_from_inventory
FROM recipe_ingredients ri
LEFT JOIN ingredients i ON ri.ingredient_name = i.name
WHERE i.name IS NULL;

-- Q5: UNION ALL to include duplicates (for count analysis)
SELECT name AS item_name FROM ingredients
UNION ALL
SELECT ingredient_name FROM recipe_ingredients;


-- ============================================================
-- SECTION 6 : SUBQUERY QUERIES  (Chapter 3.4)
-- ============================================================

-- Q1: Users who have NOT logged any meals
SELECT name
FROM users
WHERE user_id NOT IN (
    SELECT DISTINCT user_id FROM meal_logs
);

-- Q2: Recipes that use at least one ingredient available in inventory
SELECT DISTINCT r.name
FROM recipes r
WHERE r.recipe_id IN (
    SELECT ri.recipe_id
    FROM recipe_ingredients ri
    WHERE ri.ingredient_name IN (SELECT name FROM ingredients)
);

-- Q3: All highest-rated meal logs (rating = max rating)
SELECT ml.log_id, u.name AS user_name, r.name AS recipe, ml.rating
FROM meal_logs ml
JOIN users u ON ml.user_id = u.user_id
JOIN recipes r ON ml.recipe_id = r.recipe_id
WHERE ml.rating = (SELECT MAX(rating) FROM meal_logs);

-- Q4: Users whose avg rating is above the overall average
SELECT u.name, ROUND(AVG(ml.rating), 2) AS user_avg_rating
FROM users u
JOIN meal_logs ml ON u.user_id = ml.user_id
GROUP BY u.user_id, u.name
HAVING AVG(ml.rating) > (SELECT AVG(rating) FROM meal_logs)
ORDER BY user_avg_rating DESC;

-- Q5: Recipes never cooked by any user
SELECT name AS uncoooked_recipe
FROM recipes
WHERE recipe_id NOT IN (
    SELECT DISTINCT recipe_id FROM meal_logs WHERE recipe_id IS NOT NULL
);

-- Q6: User with the most ingredients in inventory
SELECT name
FROM users
WHERE user_id = (
    SELECT user_id
    FROM ingredients
    GROUP BY user_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);


-- ============================================================
-- SECTION 7 : JOIN QUERIES  (Chapter 3.5)
-- ============================================================

-- Q1: All users and their meals, including users with no meals (LEFT JOIN)
SELECT u.name AS user_name, r.name AS recipe, ml.consumed_date, ml.rating
FROM users u
LEFT JOIN meal_logs ml ON u.user_id = ml.user_id
LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
ORDER BY u.name;

-- Q2: Ingredients and the recipes they appear in (INNER JOIN)
SELECT i.name AS ingredient, r.name AS recipe
FROM ingredients i
JOIN recipe_ingredients ri ON i.name = ri.ingredient_name
JOIN recipes r ON ri.recipe_id = r.recipe_id
ORDER BY i.name;

-- Q3: Recipes that can be made from available inventory
SELECT DISTINCT r.name AS recipe, r.difficulty_level, r.prep_time
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
JOIN ingredients i ON ri.ingredient_name = i.name
ORDER BY r.name;

-- Q4: Full meal history — user, recipe, difficulty, date, rating
SELECT u.name AS user_name,
       r.name AS recipe,
       r.difficulty_level,
       ml.consumed_date,
       ml.rating
FROM meal_logs ml
JOIN users u ON ml.user_id = u.user_id
JOIN recipes r ON ml.recipe_id = r.recipe_id
ORDER BY ml.consumed_date;

-- Q5: CROSS JOIN — sample of all user-recipe combinations
SELECT u.name AS user_name, r.name AS recipe
FROM users u
CROSS JOIN recipes r
LIMIT 20;

-- Q6: SELF JOIN — users who registered on the same date
SELECT u1.name AS user1, u2.name AS user2, DATE(u1.created_at) AS signup_date
FROM users u1
JOIN users u2
  ON DATE(u1.created_at) = DATE(u2.created_at)
 AND u1.user_id < u2.user_id;


-- ============================================================
-- SECTION 8 : VIEWS  (Chapter 3.6)
-- ============================================================

-- View 1: Full recipe details with ingredients
DROP VIEW IF EXISTS recipe_details_view;
CREATE VIEW recipe_details_view AS
SELECT r.name AS recipe, r.difficulty_level, r.prep_time,
       ri.ingredient_name, ri.quantity, ri.unit
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id;

-- Verify:
SELECT * FROM recipe_details_view ORDER BY recipe LIMIT 10;

-- ---

-- View 2: Ingredients expiring within 3 days (real-time alert dashboard)
DROP VIEW IF EXISTS expiring_ingredients_view;
CREATE VIEW expiring_ingredients_view AS
SELECT u.name AS user_name, i.name AS ingredient,
       i.quantity, i.unit, i.expiration_date,
       DATEDIFF(i.expiration_date, CURDATE()) AS days_remaining
FROM ingredients i
JOIN users u ON i.user_id = u.user_id
WHERE i.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY);

-- Verify:
SELECT * FROM expiring_ingredients_view;

-- ---

-- View 3: User meal count summary
DROP VIEW IF EXISTS user_meal_count_view;
CREATE VIEW user_meal_count_view AS
SELECT u.name, COUNT(m.log_id) AS total_meals,
       ROUND(AVG(m.rating), 1) AS avg_rating
FROM users u
LEFT JOIN meal_logs m ON u.user_id = m.user_id
GROUP BY u.user_id, u.name;

-- Verify:
SELECT * FROM user_meal_count_view ORDER BY total_meals DESC;

-- ---

-- View 4: Nutritional overview per user (calories per ingredient)
DROP VIEW IF EXISTS user_nutrition_view;
CREATE VIEW user_nutrition_view AS
SELECT u.name AS user_name, i.location,
       i.name AS ingredient, i.quantity, i.unit,
       i.calories_per_unit,
       ROUND(i.quantity * i.calories_per_unit, 0) AS total_calories
FROM ingredients i
JOIN users u ON i.user_id = u.user_id;

-- Verify:
SELECT * FROM user_nutrition_view WHERE user_name = 'Alice Johnson';


-- ============================================================
-- SECTION 9 : TRIGGERS  (Chapter 3.7)
-- ============================================================

-- -----------------------------------------------------------
-- Trigger 1: Auto-set default rating = 3 when NULL on insert
-- -----------------------------------------------------------
DROP TRIGGER IF EXISTS set_default_rating;
DELIMITER //
CREATE TRIGGER set_default_rating
BEFORE INSERT ON meal_logs
FOR EACH ROW
BEGIN
    IF NEW.rating IS NULL THEN
        SET NEW.rating = 3;
    END IF;
END;
//
DELIMITER ;

-- Test:
-- INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES (1, 2, CURDATE(), NULL);
-- SELECT * FROM meal_logs ORDER BY log_id DESC LIMIT 1;
-- Expected: rating = 3


-- -----------------------------------------------------------
-- Trigger 2: Reduce ingredient quantity by 1 after a meal log
-- -----------------------------------------------------------
DROP TRIGGER IF EXISTS reduce_ingredient_after_meal;
DELIMITER //
CREATE TRIGGER reduce_ingredient_after_meal
AFTER INSERT ON meal_logs
FOR EACH ROW
BEGIN
    UPDATE ingredients
    SET quantity = quantity - 1
    WHERE user_id = NEW.user_id;
END;
//
DELIMITER ;

-- Test:
-- SELECT quantity FROM ingredients WHERE user_id = 1 LIMIT 1;
-- INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES (1, 3, CURDATE(), 4);
-- SELECT quantity FROM ingredients WHERE user_id = 1 LIMIT 1;  -- quantity reduced by 1


-- -----------------------------------------------------------
-- Trigger 3: Block insertion of already-expired ingredients
-- -----------------------------------------------------------
DROP TRIGGER IF EXISTS check_expiry_date;
DELIMITER //
CREATE TRIGGER check_expiry_date
BEFORE INSERT ON ingredients
FOR EACH ROW
BEGIN
    IF NEW.expiration_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add expired ingredient';
    END IF;
END;
//
DELIMITER ;

-- Test (should raise error):
-- INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
-- VALUES (1, 'Old Milk', 1.00, 'l', '2020-01-01', 'refrigerator', 42);
-- ERROR: Cannot add expired ingredient


-- ============================================================
-- SECTION 10 : CURSORS  (Chapter 3.8)
-- ============================================================

-- -----------------------------------------------------------
-- Cursor 1: Display all ingredient names one by one
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS get_ingredients;
DELIMITER //
CREATE PROCEDURE get_ingredients()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE ing_name VARCHAR(100);

    DECLARE cur CURSOR FOR
        SELECT name FROM ingredients;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO ing_name;
        IF done THEN LEAVE read_loop; END IF;
        SELECT ing_name AS ingredient_name;
    END LOOP;
    CLOSE cur;
END;
//
DELIMITER ;

-- Call: CALL get_ingredients();


-- -----------------------------------------------------------
-- Cursor 2: Count total ingredients using a cursor
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS count_ingredients;
DELIMITER //
CREATE PROCEDURE count_ingredients()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE total INT DEFAULT 0;
    DECLARE ing_id INT;

    DECLARE cur CURSOR FOR
        SELECT ingredient_id FROM ingredients;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO ing_id;
        IF done THEN LEAVE read_loop; END IF;
        SET total = total + 1;
    END LOOP;
    CLOSE cur;

    SELECT total AS total_ingredients;
END;
//
DELIMITER ;

-- Call: CALL count_ingredients();


-- -----------------------------------------------------------
-- Cursor 3: List ingredients with low stock (quantity < 2)
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS low_stock;
DELIMITER //
CREATE PROCEDURE low_stock()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE ing_name VARCHAR(100);
    DECLARE qty DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT name, quantity FROM ingredients;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO ing_name, qty;
        IF done THEN LEAVE read_loop; END IF;
        IF qty < 2 THEN
            SELECT ing_name AS ingredient, qty AS quantity;
        END IF;
    END LOOP;
    CLOSE cur;
END;
//
DELIMITER ;

-- Call: CALL low_stock();


-- ============================================================
-- SECTION 11 : TRANSACTIONS & TCL  (Chapter 5)
-- ============================================================

-- -----------------------------------------------------------
-- Transaction 1: Log a meal and deduct inventory
-- -----------------------------------------------------------
START TRANSACTION;

INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating)
VALUES (1, 1, CURDATE(), 5);

SAVEPOINT after_meal_log;

UPDATE ingredients
SET quantity = quantity - 0.25
WHERE user_id = 1 AND name = 'Spinach';

UPDATE ingredients
SET quantity = quantity - 0.10
WHERE user_id = 1 AND name = 'Chickpeas';

COMMIT;


-- -----------------------------------------------------------
-- Transaction 2: Add a fresh ingredient; expired one is blocked
-- -----------------------------------------------------------
START TRANSACTION;

INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
VALUES (2, 'Kale', 0.30, 'kg', '2026-08-01', 'refrigerator', 35);

SAVEPOINT after_kale_insert;

-- Attempting expired item would trigger check_expiry_date and fail:
-- INSERT INTO ingredients ... expiration_date = '2020-01-01' → SIGNAL raised

COMMIT;


-- -----------------------------------------------------------
-- Transaction 3: Register new user and add starter ingredients
-- -----------------------------------------------------------
START TRANSACTION;

INSERT INTO users (name, email, password_hash, dietary_preferences, created_at)
VALUES ('Test User', 'testuser@email.com', 'hash_test', '{"vegan":false}', NOW());

SAVEPOINT after_user_insert;

INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location)
VALUES (LAST_INSERT_ID(), 'Rice', 5.00, 'kg', '2027-06-01', 'pantry');

INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location)
VALUES (LAST_INSERT_ID(), 'Dal', 2.00, 'kg', '2027-05-01', 'pantry');

COMMIT;


-- -----------------------------------------------------------
-- Transaction 4: Rollback demonstration (bad recipe_id)
-- -----------------------------------------------------------
START TRANSACTION;

SAVEPOINT before_bad_insert;

-- This would fail FK check (recipe_id = 9999 does not exist):
-- INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating)
-- VALUES (1, 9999, CURDATE(), 4);

ROLLBACK TO before_bad_insert;

-- Continue with valid insert:
INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating)
VALUES (1, 5, CURDATE(), 4);

COMMIT;


-- -----------------------------------------------------------
-- Transaction 5: Bulk delete expired ingredients with safety savepoint
-- -----------------------------------------------------------
START TRANSACTION;

SAVEPOINT before_cleanup;

DELETE FROM ingredients
WHERE expiration_date < CURDATE();

-- If deletion count was unexpected, can rollback:
-- ROLLBACK TO before_cleanup;

COMMIT;


-- ============================================================
-- SECTION 12 : CONCURRENCY CONTROL  (Chapter 5.4)
-- ============================================================

-- -----------------------------------------------------------
-- Example: Row-Level Lock (SELECT ... FOR UPDATE)
-- Two concurrent users trying to use the same ingredient row
-- -----------------------------------------------------------

-- Session A:
START TRANSACTION;
SELECT * FROM ingredients
WHERE user_id = 1 AND name = 'Spinach'
FOR UPDATE;                               -- acquires row lock

UPDATE ingredients
SET quantity = quantity - 0.25
WHERE user_id = 1 AND name = 'Spinach';

COMMIT;                                   -- releases lock

-- Session B (runs concurrently — waits for Session A to commit):
-- START TRANSACTION;
-- SELECT * FROM ingredients WHERE user_id = 1 AND name = 'Spinach' FOR UPDATE;
-- UPDATE ingredients SET quantity = quantity - 0.10 WHERE user_id = 1 AND name = 'Spinach';
-- COMMIT;


-- Table-Level Lock example:
LOCK TABLES ingredients WRITE;
DELETE FROM ingredients WHERE expiration_date < CURDATE();
UNLOCK TABLES;


-- ============================================================
-- SECTION 13 : USEFUL APP QUERIES
-- ============================================================

-- Smart recipe recommendation for user_id = 1
SELECT r.name, r.difficulty_level, r.prep_time,
       COUNT(DISTINCT ri.ingredient_name) AS matched_ingredients
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
JOIN ingredients i
  ON LOWER(i.name) = LOWER(ri.ingredient_name)
 AND i.user_id = 1
GROUP BY r.recipe_id
HAVING COUNT(DISTINCT ri.ingredient_name) >= 2
ORDER BY matched_ingredients DESC, r.prep_time;


-- Top-rated recipes leaderboard
SELECT r.name, r.difficulty_level,
       ROUND(AVG(ml.rating), 2) AS avg_rating,
       COUNT(ml.log_id) AS times_cooked
FROM meal_logs ml
JOIN recipes r ON ml.recipe_id = r.recipe_id
GROUP BY r.recipe_id
ORDER BY avg_rating DESC, times_cooked DESC
LIMIT 10;


-- Full nutritional inventory for user_id = 1
SELECT location, name, quantity, unit, expiration_date,
       calories_per_unit,
       ROUND(quantity * calories_per_unit, 0) AS total_calories
FROM ingredients
WHERE user_id = 1
ORDER BY location, expiration_date;


-- User engagement dashboard
SELECT u.name,
       COUNT(ml.log_id) AS meals_logged,
       ROUND(AVG(ml.rating), 1) AS avg_meal_rating
FROM users u
LEFT JOIN meal_logs ml ON u.user_id = ml.user_id
GROUP BY u.user_id
ORDER BY meals_logged DESC;


-- ============================================================
-- END OF WEIGHT COACH APP DATABASE SCRIPT
-- ============================================================
