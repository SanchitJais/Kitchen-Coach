-- ============================================================
--  KITCHEN COACH APP — Fully Normalized Schema (1NF → 5NF)
--  Database: MySQL 8.0
-- ============================================================

DROP DATABASE IF EXISTS kitchen_coach_db;
CREATE DATABASE kitchen_coach_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE kitchen_coach_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- TABLE: users (1NF — atomic values only)
-- ============================================================
CREATE TABLE users (
    user_id       INT           AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(255)  UNIQUE NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABLE: user_dietary_preferences (4NF — removes multi-valued dependency)
-- ============================================================
CREATE TABLE user_dietary_preferences (
    user_id            INT          NOT NULL,
    dietary_preference VARCHAR(50)  NOT NULL,
    PRIMARY KEY (user_id, dietary_preference),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: storage_locations (3NF — removes transitive dependency)
-- ============================================================
CREATE TABLE storage_locations (
    location          VARCHAR(50)  PRIMARY KEY,
    location_type     VARCHAR(50)  NOT NULL,
    temperature_range VARCHAR(30)
);

-- ============================================================
-- TABLE: ingredient_units (BCNF — every determinant is a super key)
-- ============================================================
CREATE TABLE ingredient_units (
    ingredient_name VARCHAR(100) PRIMARY KEY,
    standard_unit   VARCHAR(20)  NOT NULL
);

-- ============================================================
-- TABLE: ingredients (2NF — no partial dependency)
-- ============================================================
CREATE TABLE ingredients (
    ingredient_id   INT            AUTO_INCREMENT PRIMARY KEY,
    user_id         INT            NOT NULL,
    name            VARCHAR(100)   NOT NULL,
    quantity        DECIMAL(10,2)  DEFAULT 0,
    unit            VARCHAR(20),
    expiration_date DATE,
    location        VARCHAR(50),
    calories_per_unit INT          DEFAULT 0,
    added_date      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (location) REFERENCES storage_locations(location) ON UPDATE CASCADE
);

-- ============================================================
-- TABLE: recipes (1NF)
-- ============================================================
CREATE TABLE recipes (
    recipe_id        INT           AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(200)  NOT NULL,
    instructions     TEXT,
    prep_time        INT,
    difficulty_level VARCHAR(20),
    image_url        VARCHAR(500)
);

-- ============================================================
-- TABLE: recipe_ingredients (BCNF — composite PK, determinant is super key)
-- ============================================================
CREATE TABLE recipe_ingredients (
    recipe_id       INT            NOT NULL,
    ingredient_name VARCHAR(100)   NOT NULL,
    quantity        DECIMAL(10,2),
    unit            VARCHAR(20),
    PRIMARY KEY (recipe_id, ingredient_name),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: meal_logs (2NF)
-- ============================================================
CREATE TABLE meal_logs (
    log_id        INT   AUTO_INCREMENT PRIMARY KEY,
    user_id       INT   NOT NULL,
    recipe_id     INT,
    consumed_date DATE  NOT NULL,
    rating        INT   CHECK (rating BETWEEN 1 AND 5),
    notes         TEXT,
    FOREIGN KEY (user_id)   REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE SET NULL
);

-- ============================================================
-- TABLE: user_recipes (5NF — decomposes join dependency)
-- ============================================================
CREATE TABLE user_recipes (
    user_id   INT NOT NULL,
    recipe_id INT NOT NULL,
    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id)   REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: recipe_categories (5NF)
-- ============================================================
CREATE TABLE recipe_categories (
    recipe_id INT          NOT NULL,
    category  VARCHAR(50)  NOT NULL,
    PRIMARY KEY (recipe_id, category),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: user_categories (5NF)
-- ============================================================
CREATE TABLE user_categories (
    user_id  INT          NOT NULL,
    category VARCHAR(50)  NOT NULL,
    PRIMARY KEY (user_id, category),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Users (password is 'password123' hashed with bcrypt)
INSERT INTO users (name, email, password_hash) VALUES
('Alice Johnson',   'alice@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Bob Smith',       'bob@example.com',     '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Carol White',     'carol@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('David Lee',       'david@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Eva Martinez',    'eva@example.com',     '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Frank Brown',     'frank@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Grace Wilson',    'grace@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Henry Taylor',    'henry@example.com',   '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Isabella Davis',  'isabella@example.com','$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6'),
('Jack Miller',     'jack@example.com',    '$2b$10$xJ8Kq2M5Q7mZ3vR9wL4nOeYp1sT6uA0dF3gH5jK7lM9nP2qR4sT6');

-- Dietary preferences (4NF)
INSERT INTO user_dietary_preferences (user_id, dietary_preference) VALUES
(1, 'vegan'), (1, 'gluten_free'),
(2, 'keto'),
(3, 'vegetarian'),
(4, 'vegan'), (4, 'gluten_free'),
(5, 'pescatarian'),
(6, 'high_protein'),
(7, 'vegetarian'), (7, 'dairy_free'),
(8, 'low_carb'),
(9, 'vegan'),
(10, 'paleo');

-- Storage locations (3NF)
INSERT INTO storage_locations (location, location_type, temperature_range) VALUES
('refrigerator', 'cold_storage',   '1°C – 4°C'),
('freezer',      'frozen_storage', '-18°C – 0°C'),
('pantry',       'dry_storage',    '10°C – 21°C'),
('countertop',   'room_temp',      '18°C – 25°C'),
('spice_rack',   'dry_storage',    '18°C – 25°C');

-- Ingredient units (BCNF)
INSERT INTO ingredient_units (ingredient_name, standard_unit) VALUES
('Spinach', 'g'), ('Almond Milk', 'ml'), ('Chickpeas', 'g'),
('Chicken Breast', 'g'), ('Rice', 'g'), ('Broccoli', 'g'),
('Eggs', 'pcs'), ('Cheddar Cheese', 'g'), ('Tomatoes', 'g'),
('Lentils', 'g'), ('Coconut Oil', 'ml'), ('Kale', 'g'),
('Salmon Fillet', 'g'), ('Asparagus', 'g'), ('Olive Oil', 'ml'),
('Ground Beef', 'g'), ('Onions', 'g'), ('Garlic', 'g'),
('Greek Yogurt', 'g'), ('Honey', 'ml'), ('Blueberries', 'g'),
('Oats', 'g'), ('Banana', 'pcs'), ('Tofu', 'g'),
('Soy Sauce', 'ml'), ('Pasta', 'g'), ('Marinara Sauce', 'ml'),
('Sweet Potato', 'g'), ('Black Beans', 'g'), ('Quinoa', 'g');

-- Ingredients
INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit) VALUES
(1, 'Spinach',        300.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 2 DAY),  'refrigerator', 23),
(1, 'Almond Milk',      1.00, 'l',   DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'refrigerator', 17),
(1, 'Chickpeas',      500.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 90 DAY), 'pantry',       164),
(2, 'Chicken Breast', 600.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 1 DAY),  'refrigerator', 165),
(2, 'Rice',          2000.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 180 DAY),'pantry',       130),
(2, 'Broccoli',       400.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 3 DAY),  'refrigerator', 55),
(3, 'Eggs',            12.00, 'pcs', DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'refrigerator', 78),
(3, 'Cheddar Cheese', 250.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'refrigerator', 402),
(3, 'Tomatoes',       500.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 5 DAY),  'refrigerator', 18),
(4, 'Lentils',        800.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 120 DAY),'pantry',       116),
(4, 'Coconut Oil',    500.00, 'ml',  DATE_ADD(CURDATE(), INTERVAL 365 DAY),'pantry',       862),
(4, 'Kale',           250.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 2 DAY),  'refrigerator', 49),
(5, 'Salmon Fillet',  400.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 3 DAY),  'freezer',      208),
(5, 'Asparagus',      300.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 4 DAY),  'refrigerator', 20),
(5, 'Olive Oil',      750.00, 'ml',  DATE_ADD(CURDATE(), INTERVAL 200 DAY),'pantry',       884),
(6, 'Ground Beef',    500.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 5 DAY),  'freezer',      250),
(6, 'Onions',        1000.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'pantry',       40),
(6, 'Garlic',         200.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 60 DAY), 'pantry',       149),
(7, 'Greek Yogurt',   500.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 7 DAY),  'refrigerator', 59),
(7, 'Honey',          300.00, 'ml',  DATE_ADD(CURDATE(), INTERVAL 400 DAY),'pantry',       304),
(7, 'Blueberries',    250.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 3 DAY),  'refrigerator', 57),
(8, 'Oats',          1000.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 150 DAY),'pantry',       389),
(8, 'Banana',           6.00, 'pcs', DATE_ADD(CURDATE(), INTERVAL 2 DAY),  'countertop',   89),
(9, 'Tofu',           400.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 6 DAY),  'refrigerator', 76),
(9, 'Soy Sauce',      500.00, 'ml',  DATE_ADD(CURDATE(), INTERVAL 250 DAY),'pantry',       60),
(10,'Pasta',           500.00,'g',   DATE_ADD(CURDATE(), INTERVAL 200 DAY),'pantry',       158),
(10,'Marinara Sauce',  400.00,'ml',  DATE_ADD(CURDATE(), INTERVAL 90 DAY), 'pantry',       45),
(1, 'Sweet Potato',   800.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'pantry',       86),
(2, 'Black Beans',    600.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 120 DAY),'pantry',       132),
(3, 'Quinoa',         500.00, 'g',   DATE_ADD(CURDATE(), INTERVAL 180 DAY),'pantry',       120);

-- Recipes
INSERT INTO recipes (name, instructions, prep_time, difficulty_level) VALUES
('Vegan Chickpea Curry',
 '1. Heat oil. 2. Saute onion and garlic 3 min. 3. Add spices. 4. Add chickpeas and tomatoes. 5. Simmer 20 min. 6. Serve with rice.',
 30, 'Easy'),
('Grilled Chicken Broccoli Bowl',
 '1. Marinate chicken. 2. Grill 6-7 min per side. 3. Steam broccoli. 4. Cook rice. 5. Assemble bowl.',
 35, 'Easy'),
('Spinach and Egg Frittata',
 '1. Preheat oven 375F. 2. Saute spinach and onion. 3. Beat eggs with cheese. 4. Bake 15 min.',
 25, 'Medium'),
('Lentil Soup',
 '1. Saute onion, garlic, carrots. 2. Add lentils and broth. 3. Simmer 25 min. 4. Season and serve.',
 40, 'Easy'),
('Roasted Salmon with Asparagus',
 '1. Preheat oven 400F. 2. Season salmon. 3. Toss asparagus in oil. 4. Roast 15-18 min.',
 25, 'Easy'),
('Beef Stir-Fry',
 '1. Slice beef. 2. Stir-fry 3 min. 3. Add vegetables. 4. Add sauces. 5. Serve over rice.',
 20, 'Medium'),
('Blueberry Greek Yogurt Parfait',
 '1. Layer yogurt. 2. Add blueberries. 3. Drizzle honey. 4. Top with granola.',
 10, 'Easy'),
('Banana Overnight Oats',
 '1. Combine oats, milk, chia seeds. 2. Add honey. 3. Refrigerate overnight. 4. Top with banana.',
 5, 'Easy'),
('Tofu Teriyaki Bowl',
 '1. Press and cube tofu. 2. Pan-fry until golden. 3. Make teriyaki sauce. 4. Serve over rice.',
 30, 'Medium'),
('Pasta Marinara',
 '1. Boil pasta. 2. Saute garlic. 3. Add marinara, simmer 10 min. 4. Toss with pasta.',
 20, 'Easy'),
('Sweet Potato Black Bean Tacos',
 '1. Roast sweet potato. 2. Season beans. 3. Warm tortillas. 4. Assemble.',
 35, 'Easy'),
('Quinoa Power Bowl',
 '1. Cook quinoa. 2. Roast vegetables. 3. Prepare dressing. 4. Assemble bowl.',
 40, 'Medium'),
('Kale Caesar Salad',
 '1. Massage kale. 2. Make dressing. 3. Toss kale. 4. Add croutons and chickpeas.',
 15, 'Easy'),
('Veggie Omelette',
 '1. Whisk eggs. 2. Saute vegetables. 3. Pour eggs over veggies. 4. Fold and add cheese.',
 15, 'Easy'),
('Banana Smoothie Bowl',
 '1. Blend frozen bananas with milk. 2. Pour into bowl. 3. Top with granola.',
 10, 'Easy'),
('Coconut Lentil Dal',
 '1. Saute aromatics. 2. Add lentils and coconut milk. 3. Season. 4. Simmer 20 min.',
 35, 'Easy');

-- Recipe ingredients (BCNF)
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, quantity, unit) VALUES
(1, 'Chickpeas',      400.00, 'g'),
(1, 'Tomatoes',       300.00, 'g'),
(1, 'Onions',         150.00, 'g'),
(1, 'Garlic',          10.00, 'g'),
(1, 'Coconut Oil',     15.00, 'ml'),
(2, 'Chicken Breast', 300.00, 'g'),
(2, 'Broccoli',       200.00, 'g'),
(2, 'Rice',           200.00, 'g'),
(2, 'Olive Oil',       15.00, 'ml'),
(3, 'Spinach',        150.00, 'g'),
(3, 'Eggs',             4.00, 'pcs'),
(3, 'Cheddar Cheese',  50.00, 'g'),
(3, 'Onions',          80.00, 'g'),
(4, 'Lentils',        300.00, 'g'),
(4, 'Onions',         100.00, 'g'),
(4, 'Garlic',           8.00, 'g'),
(4, 'Olive Oil',       10.00, 'ml'),
(5, 'Salmon Fillet',  200.00, 'g'),
(5, 'Asparagus',      150.00, 'g'),
(5, 'Olive Oil',       15.00, 'ml'),
(6, 'Ground Beef',    250.00, 'g'),
(6, 'Onions',         100.00, 'g'),
(6, 'Garlic',           8.00, 'g'),
(6, 'Rice',           150.00, 'g'),
(7, 'Greek Yogurt',   200.00, 'g'),
(7, 'Blueberries',    100.00, 'g'),
(7, 'Honey',           20.00, 'ml'),
(8, 'Oats',            80.00, 'g'),
(8, 'Almond Milk',    200.00, 'ml'),
(8, 'Banana',           1.00, 'pcs'),
(8, 'Honey',           15.00, 'ml'),
(9, 'Tofu',           200.00, 'g'),
(9, 'Soy Sauce',       40.00, 'ml'),
(9, 'Rice',           150.00, 'g'),
(10,'Pasta',           200.00, 'g'),
(10,'Marinara Sauce',  200.00, 'ml'),
(10,'Garlic',            5.00, 'g'),
(10,'Olive Oil',        10.00, 'ml'),
(11,'Sweet Potato',    300.00, 'g'),
(11,'Black Beans',     200.00, 'g'),
(12,'Quinoa',          200.00, 'g'),
(13,'Kale',            150.00, 'g'),
(13,'Chickpeas',       100.00, 'g'),
(13,'Olive Oil',        15.00, 'ml'),
(14,'Eggs',              3.00, 'pcs'),
(14,'Spinach',          80.00, 'g'),
(14,'Cheddar Cheese',   40.00, 'g'),
(15,'Banana',            2.00, 'pcs'),
(15,'Almond Milk',     100.00, 'ml'),
(15,'Honey',            15.00, 'ml'),
(16,'Lentils',         250.00, 'g'),
(16,'Coconut Oil',      15.00, 'ml'),
(16,'Spinach',         100.00, 'g');

-- Meal logs
INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES
(1, 1,  DATE_SUB(CURDATE(), INTERVAL 1 DAY), 5),
(1, 4,  DATE_SUB(CURDATE(), INTERVAL 3 DAY), 4),
(1, 13, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 5),
(2, 2,  DATE_SUB(CURDATE(), INTERVAL 2 DAY), 5),
(2, 6,  DATE_SUB(CURDATE(), INTERVAL 4 DAY), 4),
(2, 10, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 3),
(3, 3,  DATE_SUB(CURDATE(), INTERVAL 1 DAY), 4),
(3, 7,  DATE_SUB(CURDATE(), INTERVAL 3 DAY), 5),
(3, 14, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 4),
(4, 4,  DATE_SUB(CURDATE(), INTERVAL 2 DAY), 5),
(4, 9,  DATE_SUB(CURDATE(), INTERVAL 5 DAY), 4),
(4, 12, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 5),
(5, 5,  DATE_SUB(CURDATE(), INTERVAL 1 DAY), 5),
(5, 16, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 4),
(6, 6,  DATE_SUB(CURDATE(), INTERVAL 2 DAY), 4),
(6, 10, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 4),
(7, 7,  DATE_SUB(CURDATE(), INTERVAL 3 DAY), 5),
(7, 8,  DATE_SUB(CURDATE(), INTERVAL 5 DAY), 4),
(8, 8,  DATE_SUB(CURDATE(), INTERVAL 1 DAY), 4),
(8, 14, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 3),
(9, 9,  DATE_SUB(CURDATE(), INTERVAL 2 DAY), 5),
(9, 12, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 4),
(10,10, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 3),
(10,16, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 4);

-- User bookmarked recipes (5NF)
INSERT INTO user_recipes (user_id, recipe_id) VALUES
(1,1),(1,4),(1,13),(1,16),
(2,2),(2,6),(2,10),
(3,3),(3,7),(3,14),
(4,4),(4,9),(4,12),
(5,5),(5,16),
(6,6),(6,10),
(7,7),(7,8),(7,15),
(8,8),(8,14),
(9,9),(9,12),
(10,10),(10,16);

-- Recipe categories (5NF)
INSERT INTO recipe_categories (recipe_id, category) VALUES
(1,'vegan'),(1,'curry'),(1,'high_fiber'),
(2,'high_protein'),(2,'meal_prep'),
(3,'vegetarian'),(3,'breakfast'),
(4,'vegan'),(4,'soup'),(4,'high_fiber'),
(5,'pescatarian'),(5,'low_carb'),
(6,'high_protein'),(6,'quick_meal'),
(7,'vegetarian'),(7,'breakfast'),(7,'snack'),
(8,'breakfast'),(8,'meal_prep'),
(9,'vegan'),(9,'asian'),
(10,'vegetarian'),(10,'quick_meal'),
(11,'vegan'),(11,'mexican'),
(12,'vegan'),(12,'meal_prep'),
(13,'vegan'),(13,'salad'),
(14,'vegetarian'),(14,'breakfast'),
(15,'vegan'),(15,'breakfast'),(15,'snack'),
(16,'vegan'),(16,'curry'),(16,'high_fiber');

-- User category preferences (5NF)
INSERT INTO user_categories (user_id, category) VALUES
(1,'vegan'),(1,'curry'),(1,'high_fiber'),
(2,'high_protein'),(2,'meal_prep'),
(3,'vegetarian'),(3,'breakfast'),
(4,'vegan'),(4,'soup'),
(5,'pescatarian'),(5,'low_carb'),
(6,'high_protein'),(6,'quick_meal'),
(7,'vegetarian'),(7,'breakfast'),(7,'snack'),
(8,'breakfast'),(8,'low_carb'),
(9,'vegan'),(9,'asian'),
(10,'quick_meal'),(10,'vegetarian');

-- ============================================================
-- VIEWS
-- ============================================================

-- Expiring ingredients (within 3 days)
CREATE VIEW expiring_ingredients_view AS
SELECT u.name AS user_name, i.ingredient_id, i.name AS ingredient,
       i.quantity, i.unit, i.expiration_date,
       DATEDIFF(i.expiration_date, CURDATE()) AS days_remaining
FROM ingredients i
JOIN users u ON i.user_id = u.user_id
WHERE i.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
  AND i.expiration_date >= CURDATE();

-- Recipe details with ingredients
CREATE VIEW recipe_details_view AS
SELECT r.recipe_id, r.name AS recipe, r.difficulty_level, r.prep_time,
       ri.ingredient_name, ri.quantity, ri.unit
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id;

-- User meal summary
CREATE VIEW user_meal_summary_view AS
SELECT u.user_id, u.name, COUNT(m.log_id) AS total_meals,
       ROUND(AVG(m.rating), 1) AS avg_rating
FROM users u
LEFT JOIN meal_logs m ON u.user_id = m.user_id
GROUP BY u.user_id, u.name;

-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER //

-- Auto-set default rating to 3 if NULL
CREATE TRIGGER set_default_rating
BEFORE INSERT ON meal_logs
FOR EACH ROW
BEGIN
    IF NEW.rating IS NULL THEN
        SET NEW.rating = 3;
    END IF;
END //

-- Block insertion of expired ingredients
CREATE TRIGGER check_expiry_date
BEFORE INSERT ON ingredients
FOR EACH ROW
BEGIN
    IF NEW.expiration_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add expired ingredient';
    END IF;
END //

DELIMITER ;
