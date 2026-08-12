-- ============================================================
-- WEIGHT COACH APP - DBMS Practical SQL Queries
-- Database: weight_coach_db (MySQL 8.0)
-- ============================================================

USE weight_coach_db;


-- ************************************************************
--                      CONSTRAINTS
-- ************************************************************

-- Q1: Show the PRIMARY KEY, UNIQUE, and NOT NULL constraints on users table
DESCRIBE users;

-- Q2: Show the CHECK and FOREIGN KEY constraints on meal_logs table
DESCRIBE meal_logs;

-- Q3: Test UNIQUE constraint — inserting duplicate email (will fail)
INSERT INTO users (email, password_hash, name) VALUES ('alice.johnson@email.com', 'test', 'Duplicate Alice');

-- Q4: Test CHECK constraint — inserting invalid rating (will fail)
INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES (1, 1, CURDATE(), 10);

-- Q5: Test FOREIGN KEY constraint — referencing non-existent user (will fail)
INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
VALUES (999, 'Ghost Item', 1, 'g', '2026-12-01', 'pantry', 0);

-- Q6: Test ON DELETE CASCADE — deleting a user deletes their ingredients too
DELETE FROM users WHERE user_id = 22;
SELECT * FROM ingredients WHERE user_id = 22;  -- should return empty

-- Q7: Find ingredients expiring within the next 3 days
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


-- ************************************************************
--                   AGGREGATE FUNCTIONS
-- ************************************************************

-- Q1: Count total number of users
SELECT COUNT(*) AS total_users FROM users;

-- Q2: Count total ingredients per user
SELECT u.name, COUNT(i.ingredient_id) AS total_ingredients
FROM users u
LEFT JOIN ingredients i ON u.user_id = i.user_id
GROUP BY u.user_id, u.name
ORDER BY total_ingredients DESC;

-- Q3: Total calories available across all inventory
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

-- Q5: Find the user who logged the most meals
SELECT u.name, COUNT(ml.log_id) AS meals_logged
FROM users u
JOIN meal_logs ml ON u.user_id = ml.user_id
GROUP BY u.user_id, u.name
ORDER BY meals_logged DESC
LIMIT 1;

-- Q6: Minimum, Maximum, and Average prep time of recipes
SELECT MIN(prep_time) AS min_prep,
       MAX(prep_time) AS max_prep,
       ROUND(AVG(prep_time), 1) AS avg_prep
FROM recipes;

-- Q7: Total ingredients stored per location
SELECT location, COUNT(*) AS ingredient_count
FROM ingredients
GROUP BY location
ORDER BY ingredient_count DESC;


-- ************************************************************
--                    SET OPERATIONS
-- ************************************************************

-- Q1: Find common ingredient names in both inventory and recipes (INTERSECT equivalent)
SELECT DISTINCT i.name
FROM ingredients i
INNER JOIN recipe_ingredients ri ON i.name = ri.ingredient_name;

-- Q2: Ingredients in inventory but NOT used in any recipe (EXCEPT equivalent)
SELECT DISTINCT i.name
FROM ingredients i
LEFT JOIN recipe_ingredients ri ON i.name = ri.ingredient_name
WHERE ri.ingredient_name IS NULL;

-- Q3: All unique ingredient names from both inventory and recipes (UNION)
SELECT name AS ingredient_name, 'Inventory' AS source FROM ingredients
UNION
SELECT ingredient_name, 'Recipe' AS source FROM recipe_ingredients;

-- Q4: Ingredients used in recipes but NOT available in inventory (reverse EXCEPT)
SELECT DISTINCT ri.ingredient_name
FROM recipe_ingredients ri
LEFT JOIN ingredients i ON ri.ingredient_name = i.name
WHERE i.name IS NULL;

-- Q5: All unique ingredient names without duplicates (UNION removes duplicates)
SELECT name AS item_name FROM ingredients
UNION
SELECT ingredient_name FROM recipe_ingredients;


-- ************************************************************
--                      SUBQUERIES
-- ************************************************************

-- Q1: Find users who have NOT logged any meals
SELECT name
FROM users
WHERE user_id NOT IN (
    SELECT DISTINCT user_id FROM meal_logs
);

-- Q2: Find recipes that use at least one ingredient available in inventory
SELECT DISTINCT r.name
FROM recipes r
WHERE r.recipe_id IN (
    SELECT ri.recipe_id
    FROM recipe_ingredients ri
    WHERE ri.ingredient_name IN (
        SELECT name FROM ingredients
    )
);

-- Q3: Find the highest rated meals
SELECT ml.log_id, u.name AS user_name, r.name AS recipe, ml.rating
FROM meal_logs ml
JOIN users u ON ml.user_id = u.user_id
JOIN recipes r ON ml.recipe_id = r.recipe_id
WHERE ml.rating = (
    SELECT MAX(rating) FROM meal_logs
);

-- Q4: Find users whose average rating is above the overall average
SELECT u.name, ROUND(AVG(ml.rating), 2) AS user_avg_rating
FROM users u
JOIN meal_logs ml ON u.user_id = ml.user_id
GROUP BY u.user_id, u.name
HAVING AVG(ml.rating) > (
    SELECT AVG(rating) FROM meal_logs
)
ORDER BY user_avg_rating DESC;

-- Q5: Find recipes never cooked by any user
SELECT name
FROM recipes
WHERE recipe_id NOT IN (
    SELECT DISTINCT recipe_id FROM meal_logs WHERE recipe_id IS NOT NULL
);

-- Q6: Find the user with the most ingredients in inventory
SELECT name
FROM users
WHERE user_id = (
    SELECT user_id
    FROM ingredients
    GROUP BY user_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);


-- ************************************************************
--                        JOINS
-- ************************************************************

-- Q1: Get users and their meals including users with no meals (LEFT JOIN)
SELECT u.name AS user_name, r.name AS recipe, ml.consumed_date, ml.rating
FROM users u
LEFT JOIN meal_logs ml ON u.user_id = ml.user_id
LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
ORDER BY u.name;

-- Q2: Find ingredients and the recipes they are used in (INNER JOIN)
SELECT i.name AS ingredient, r.name AS recipe
FROM ingredients i
JOIN recipe_ingredients ri ON i.name = ri.ingredient_name
JOIN recipes r ON ri.recipe_id = r.recipe_id
ORDER BY i.name;

-- Q3: Get all recipes that can be made using available ingredients
SELECT DISTINCT r.name AS recipe, r.difficulty_level, r.prep_time
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
JOIN ingredients i ON ri.ingredient_name = i.name
ORDER BY r.name;

-- Q4: User meal history with recipe details (multi-table JOIN)
SELECT u.name AS user_name,
       r.name AS recipe,
       r.difficulty_level,
       ml.consumed_date,
       ml.rating
FROM meal_logs ml
JOIN users u ON ml.user_id = u.user_id
JOIN recipes r ON ml.recipe_id = r.recipe_id
ORDER BY ml.consumed_date;

-- Q5: Cross Join — all possible user-recipe combinations (sample)
SELECT u.name AS user_name, r.name AS recipe
FROM users u
CROSS JOIN recipes r
LIMIT 20;

-- Q6: Self Join — find users who signed up on the same date
SELECT u1.name AS user1, u2.name AS user2, DATE(u1.created_at) AS signup_date
FROM users u1
JOIN users u2 ON DATE(u1.created_at) = DATE(u2.created_at) AND u1.user_id < u2.user_id;


-- ************************************************************
--                        VIEWS
-- ************************************************************

-- Q1: View — Recipe details with all ingredients
DROP VIEW IF EXISTS recipe_details_view;
CREATE VIEW recipe_details_view AS
SELECT r.name AS recipe, r.difficulty_level, r.prep_time,
       ri.ingredient_name, ri.quantity, ri.unit
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id;

-- Verify:
SELECT * FROM recipe_details_view ORDER BY recipe LIMIT 10;

-- Q2: View — Ingredients expiring soon
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

-- Q3: View — User meal count summary
DROP VIEW IF EXISTS user_meal_count_view;
CREATE VIEW user_meal_count_view AS
SELECT u.name, COUNT(m.log_id) AS total_meals,
       ROUND(AVG(m.rating), 1) AS avg_rating
FROM users u
LEFT JOIN meal_logs m ON u.user_id = m.user_id
GROUP BY u.user_id, u.name;

-- Verify:
SELECT * FROM user_meal_count_view ORDER BY total_meals DESC;

-- Q4: View — Nutritional overview per user
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


-- ************************************************************
--                       TRIGGERS
-- ************************************************************

-- Q1: Automatically set default rating to 3 if NULL
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


-- Q2: Reduce ingredient quantity after a meal is logged
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


-- Q3: Prevent inserting expired ingredients
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


-- ************************************************************
--                       CURSORS
-- ************************************************************

-- Q1: Display all ingredient names using a cursor
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
        IF done THEN
            LEAVE read_loop;
        END IF;
        SELECT ing_name;
    END LOOP;
    CLOSE cur;
END;
//
DELIMITER ;

-- Call:
-- CALL get_ingredients();


-- Q2: Count total ingredients using a cursor
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
        IF done THEN
            LEAVE read_loop;
        END IF;
        SET total = total + 1;
    END LOOP;
    CLOSE cur;

    SELECT total AS total_ingredients;
END;
//
DELIMITER ;

-- Call:
-- CALL count_ingredients();


-- Q3: Show ingredients with low stock (quantity < 2)
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
        IF done THEN
            LEAVE read_loop;
        END IF;
        IF qty < 2 THEN
            SELECT ing_name AS ingredient, qty AS quantity;
        END IF;
    END LOOP;
    CLOSE cur;
END;
//
DELIMITER ;

-- Call:
-- CALL low_stock();


-- ============================================================
-- END OF PRACTICAL QUERIES DOCUMENT
-- ============================================================
