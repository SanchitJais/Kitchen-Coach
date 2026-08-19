-- ============================================================
-- KITCHEN COACH APP - DBMS Practical Queries Document
-- Database: kitchen_coach_db (MySQL 8.0)
-- ============================================================

USE kitchen_coach_db;


-- ============================================================
-- 3.1  Adding Constraints and Queries Based on Constraints
-- Complex Queries Based on Constraints, Sets, Joins,
-- Views, Triggers and Cursors
-- ============================================================

-- Question 1: Ensure unique email and valid user data
-- SQL Statement:
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name          VARCHAR(100),
    dietary_preferences JSON,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Explanation: PRIMARY KEY ensures user_id is unique and NOT NULL.
-- UNIQUE on email prevents duplicate registrations.
-- NOT NULL on email and password_hash enforces mandatory fields.


-- Question 2: Restrict rating between 1 and 5
-- SQL Statement:
CREATE TABLE meal_logs (
    log_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT,
    recipe_id     INT,
    consumed_date DATE,
    rating        INT CHECK (rating BETWEEN 1 AND 5),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE SET NULL
);
-- Explanation: CHECK constraint ensures rating is always between 1 and 5.
-- FOREIGN KEY constraints maintain referential integrity with users and recipes.


-- Question 3: Find ingredients expiring soon (next 3 days)
-- SQL Statement:
SELECT name, expiration_date
FROM ingredients
WHERE expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY);
-- Explanation: Uses DATE_ADD with INTERVAL to find ingredients
-- expiring within the next 3 days for waste prevention alerts.


-- Question 4: Get recipes with their ingredients
-- SQL Statement:
SELECT r.name AS recipe, ri.ingredient_name
FROM recipes r
JOIN recipe_ingredients ri
ON r.recipe_id = ri.recipe_id;
-- Explanation: INNER JOIN connects recipes with their required
-- ingredients using the recipe_id foreign key relationship.




-- ============================================================
-- 3.2  Queries Based on Aggregate Functions
-- ============================================================

-- Question 1: Count total number of users
-- SQL Statement:
SELECT COUNT(*) AS total_users
FROM users;
-- Explanation: COUNT(*) returns the total number of rows in the users table.


-- Question 2: Find total number of ingredients per user
-- SQL Statement:
SELECT user_id, COUNT(*) AS total_ingredients
FROM ingredients
GROUP BY user_id;
-- Explanation: GROUP BY groups rows by user_id, and COUNT(*)
-- counts ingredients for each user separately.


-- Question 3: Find total calories available in inventory
-- SQL Statement:
SELECT SUM(quantity * calories_per_unit) AS total_calories
FROM ingredients;
-- Explanation: SUM calculates the total caloric value across
-- all ingredients by multiplying quantity with calories_per_unit.




-- ============================================================
-- 3.3  Complex Queries Based on Sets
-- ============================================================

-- Question 1: Find common ingredients in both inventory and recipes (INTERSECT)
-- SQL Statement:
-- NOTE: MySQL does not support INTERSECT directly.
-- Using INNER JOIN as equivalent:
SELECT DISTINCT i.name
FROM ingredients i
INNER JOIN recipe_ingredients ri
ON i.name = ri.ingredient_name;
-- Explanation: Finds ingredient names that exist in both the
-- ingredients inventory and the recipe_ingredients table.


-- Question 2: Find ingredients in inventory but NOT used in any recipe (EXCEPT)
-- SQL Statement:
-- NOTE: MySQL does not support EXCEPT directly.
-- Using LEFT JOIN with NULL check as equivalent:
SELECT DISTINCT i.name
FROM ingredients i
LEFT JOIN recipe_ingredients ri
ON i.name = ri.ingredient_name
WHERE ri.ingredient_name IS NULL;
-- Explanation: LEFT JOIN keeps all inventory ingredients;
-- WHERE NULL filter finds those with no recipe match.


-- Question 3: Get all unique ingredient names used in recipes and inventory (UNION)
-- SQL Statement:
SELECT name AS item_name FROM ingredients
UNION
SELECT ingredient_name FROM recipe_ingredients;
-- Explanation: UNION combines both result sets and automatically
-- removes duplicates, giving all unique ingredient names.




-- ============================================================
-- 3.4  Complex Queries Based on Subqueries
-- ============================================================

-- Question 1: Find users who have not logged any meals
-- SQL Statement:
SELECT name
FROM users
WHERE user_id NOT IN (
    SELECT user_id FROM meal_logs
);
-- Explanation: The subquery returns all user_ids that appear in
-- meal_logs. NOT IN finds users not present in that list.


-- Question 2: Find recipes that require ingredients available in inventory
-- SQL Statement:
SELECT DISTINCT recipe_id
FROM recipe_ingredients
WHERE ingredient_name IN (
    SELECT name FROM ingredients
);
-- Explanation: The subquery returns all ingredient names from
-- inventory. The outer query finds recipes using those ingredients.


-- Question 3: Find highest rated meal
-- SQL Statement:
SELECT *
FROM meal_logs
WHERE rating = (
    SELECT MAX(rating) FROM meal_logs
);
-- Explanation: The subquery finds the maximum rating value.
-- The outer query returns all meal logs that have that rating.




-- ============================================================
-- 3.5  Complex Queries Based on Joins
-- ============================================================

-- Question 1: Get users and their meals (including users with no meals)
-- SQL Statement:
SELECT u.name, m.recipe_id
FROM users u
LEFT JOIN meal_logs m
ON u.user_id = m.user_id;
-- Explanation: LEFT JOIN ensures all users appear in the result,
-- even those who have not logged any meals (shown as NULL).


-- Question 2: Find ingredients and recipes they are used in
-- SQL Statement:
SELECT i.name AS ingredient, r.name AS recipe
FROM ingredients i
JOIN recipe_ingredients ri
ON i.name = ri.ingredient_name
JOIN recipes r
ON ri.recipe_id = r.recipe_id;
-- Explanation: Double JOIN connects inventory ingredients to
-- recipe_ingredients and then to recipes to show the mapping.


-- Question 3: Get recipes that can be made using available ingredients
-- SQL Statement:
SELECT DISTINCT r.name
FROM recipes r
JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
JOIN ingredients i ON ri.ingredient_name = i.name;
-- Explanation: Joins recipes through recipe_ingredients to
-- available inventory, returning recipes with at least one
-- matching ingredient in stock.




-- ============================================================
-- 3.6  Complex Queries Based on Views
-- ============================================================

-- Question 1: Create a view for recipes with ingredients
-- SQL Statement:
CREATE VIEW recipe_details_view AS
SELECT r.name AS recipe, ri.ingredient_name, ri.quantity
FROM recipes r
JOIN recipe_ingredients ri
ON r.recipe_id = ri.recipe_id;
-- Explanation: Creates a virtual table that always shows the
-- latest recipe-ingredient data without storing it separately.

-- Verify:
SELECT * FROM recipe_details_view;


-- Question 2: View for expiring ingredients
-- SQL Statement:
CREATE VIEW expiring_ingredients_view AS
SELECT name, expiration_date
FROM ingredients
WHERE expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY);
-- Explanation: This view acts as a real-time alert dashboard
-- showing ingredients that are about to expire.

-- Verify:
SELECT * FROM expiring_ingredients_view;


-- Question 3: View for user meal count
-- SQL Statement:
CREATE VIEW user_meal_count_view AS
SELECT u.name, COUNT(m.log_id) AS total_meals
FROM users u
LEFT JOIN meal_logs m
ON u.user_id = m.user_id
GROUP BY u.name;
-- Explanation: This view provides a summary of how many meals
-- each user has logged, including users with zero meals.

-- Verify:
SELECT * FROM user_meal_count_view;




-- ============================================================
-- 3.7  Complex Queries Based on Triggers
-- ============================================================

-- Question 1: Automatically set default rating if NULL
-- SQL Statement:
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
-- Explanation: BEFORE INSERT trigger fires before each new meal_log
-- row is inserted. If rating is NULL, it automatically sets it to 3.

-- Test:
-- INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating) VALUES (1, 1, CURDATE(), NULL);
-- SELECT * FROM meal_logs ORDER BY log_id DESC LIMIT 1;


-- Question 2: Update ingredient quantity after meal is logged
-- SQL Statement:
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
-- Explanation: AFTER INSERT trigger fires after a meal is logged.
-- It reduces ingredient quantity by 1 for the user who logged the meal,
-- simulating consumption of inventory.


-- Question 3: Prevent inserting expired ingredient
-- SQL Statement:
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
-- Explanation: BEFORE INSERT trigger validates the expiration_date.
-- If someone tries to insert an ingredient that is already expired,
-- SIGNAL raises an error and blocks the insert.

-- Test:
-- INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
-- VALUES (1, 'Old Milk', 1.00, 'l', '2020-01-01', 'refrigerator', 42);
-- ERROR: Cannot add expired ingredient




-- ============================================================
-- 3.8  Complex Queries Based on Cursors
-- ============================================================

-- Question 1: Display all ingredient names using cursor
-- SQL Statement:
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
-- Explanation: The cursor iterates row-by-row through all
-- ingredient names and displays each one individually.

-- Call Procedure:
-- CALL get_ingredients();


-- Question 2: Count total ingredients using cursor
-- SQL Statement:
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
-- Explanation: The cursor walks through each ingredient_id row
-- and increments a counter, then displays the total count.

-- Call:
-- CALL count_ingredients();


-- Question 3: Show ingredients with low stock (quantity < 2)
-- SQL Statement:
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
            SELECT ing_name, qty;
        END IF;
    END LOOP;

    CLOSE cur;
END;
//

DELIMITER ;
-- Explanation: The cursor scans all ingredients and checks
-- quantity. Only ingredients with quantity < 2 are displayed,
-- helping identify items that need restocking.

-- Call:
-- CALL low_stock();


-- ============================================================
-- END OF DOCUMENT
-- ============================================================
