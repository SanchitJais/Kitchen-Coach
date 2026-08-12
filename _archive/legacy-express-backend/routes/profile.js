const express = require('express');
const pool = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/profile — user profile with dietary preferences and categories
router.get('/', auth, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT user_id, name, email, created_at FROM users WHERE user_id = ?',
      [req.user.userId]
    );
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const user = users[0];

    // Get dietary preferences (4NF table)
    const [prefs] = await pool.query(
      'SELECT dietary_preference FROM user_dietary_preferences WHERE user_id = ?',
      [req.user.userId]
    );
    user.dietary_preferences = prefs.map(p => p.dietary_preference);

    // Get category preferences (5NF table)
    const [cats] = await pool.query(
      'SELECT category FROM user_categories WHERE user_id = ?',
      [req.user.userId]
    );
    user.categories = cats.map(c => c.category);

    // Get stats
    const [ingredientCount] = await pool.query(
      'SELECT COUNT(*) AS count FROM ingredients WHERE user_id = ?',
      [req.user.userId]
    );
    const [mealCount] = await pool.query(
      'SELECT COUNT(*) AS count FROM meal_logs WHERE user_id = ?',
      [req.user.userId]
    );
    const [expiringCount] = await pool.query(
      `SELECT COUNT(*) AS count FROM ingredients
       WHERE user_id = ? AND expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
         AND expiration_date >= CURDATE()`,
      [req.user.userId]
    );

    user.stats = {
      total_ingredients: ingredientCount[0].count,
      total_meals: mealCount[0].count,
      expiring_items: expiringCount[0].count,
    };

    res.json(user);
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Failed to fetch profile.' });
  }
});

// PUT /api/profile — update user name/email
router.put('/', auth, async (req, res) => {
  try {
    const { name, email } = req.body;

    await pool.query(
      'UPDATE users SET name = COALESCE(?, name), email = COALESCE(?, email) WHERE user_id = ?',
      [name, email, req.user.userId]
    );

    const [updated] = await pool.query(
      'SELECT user_id, name, email, created_at FROM users WHERE user_id = ?',
      [req.user.userId]
    );
    res.json(updated[0]);
  } catch (err) {
    console.error('Update profile error:', err);
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Email already in use.' });
    }
    res.status(500).json({ error: 'Failed to update profile.' });
  }
});

// PUT /api/profile/preferences — update dietary preferences (4NF)
router.put('/preferences', auth, async (req, res) => {
  try {
    const { dietary_preferences, categories } = req.body;

    // Replace dietary preferences
    if (Array.isArray(dietary_preferences)) {
      await pool.query('DELETE FROM user_dietary_preferences WHERE user_id = ?', [req.user.userId]);
      for (const pref of dietary_preferences) {
        await pool.query(
          'INSERT INTO user_dietary_preferences (user_id, dietary_preference) VALUES (?, ?)',
          [req.user.userId, pref]
        );
      }
    }

    // Replace category preferences (5NF)
    if (Array.isArray(categories)) {
      await pool.query('DELETE FROM user_categories WHERE user_id = ?', [req.user.userId]);
      for (const cat of categories) {
        await pool.query(
          'INSERT INTO user_categories (user_id, category) VALUES (?, ?)',
          [req.user.userId, cat]
        );
      }
    }

    // Return updated preferences
    const [prefs] = await pool.query(
      'SELECT dietary_preference FROM user_dietary_preferences WHERE user_id = ?',
      [req.user.userId]
    );
    const [cats] = await pool.query(
      'SELECT category FROM user_categories WHERE user_id = ?',
      [req.user.userId]
    );

    res.json({
      dietary_preferences: prefs.map(p => p.dietary_preference),
      categories: cats.map(c => c.category),
    });
  } catch (err) {
    console.error('Update preferences error:', err);
    res.status(500).json({ error: 'Failed to update preferences.' });
  }
});

// GET /api/profile/dashboard — dashboard summary stats
router.get('/dashboard', auth, async (req, res) => {
  try {
    const userId = req.user.userId;

    const [ingredientCount] = await pool.query(
      'SELECT COUNT(*) AS total FROM ingredients WHERE user_id = ?', [userId]
    );
    const [expiringCount] = await pool.query(
      `SELECT COUNT(*) AS total FROM ingredients
       WHERE user_id = ? AND expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
         AND expiration_date >= CURDATE()`, [userId]
    );
    const [mealCount] = await pool.query(
      'SELECT COUNT(*) AS total FROM meal_logs WHERE user_id = ?', [userId]
    );
    const [recipeCount] = await pool.query(
      'SELECT COUNT(*) AS total FROM user_recipes WHERE user_id = ?', [userId]
    );
    const [recentMeals] = await pool.query(
      `SELECT ml.consumed_date, ml.rating, r.name AS recipe_name
       FROM meal_logs ml LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
       WHERE ml.user_id = ? ORDER BY ml.consumed_date DESC LIMIT 5`, [userId]
    );
    const [expiringItems] = await pool.query(
      `SELECT name, quantity, unit, expiration_date,
              DATEDIFF(expiration_date, CURDATE()) AS days_left
       FROM ingredients
       WHERE user_id = ? AND expiration_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
         AND expiration_date >= CURDATE()
       ORDER BY expiration_date ASC`, [userId]
    );

    res.json({
      total_ingredients: ingredientCount[0].total,
      expiring_items: expiringCount[0].total,
      meals_tracked: mealCount[0].total,
      bookmarked_recipes: recipeCount[0].total,
      recent_meals: recentMeals,
      expiring_soon: expiringItems,
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch dashboard data.' });
  }
});

module.exports = router;
