const express = require('express');
const pool = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/shopping-list — auto-generated missing ingredients
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user's bookmarked recipes and find missing ingredients
    const [missing] = await pool.query(
      `SELECT ri.ingredient_name, ri.quantity AS required_quantity, ri.unit,
              r.name AS recipe_name, r.recipe_id,
              COALESCE(i.quantity, 0) AS available_quantity,
              GREATEST(ri.quantity - COALESCE(i.quantity, 0), 0) AS needed_quantity
       FROM user_recipes ur
       JOIN recipe_ingredients ri ON ur.recipe_id = ri.recipe_id
       JOIN recipes r ON ur.recipe_id = r.recipe_id
       LEFT JOIN ingredients i
         ON LOWER(i.name) = LOWER(ri.ingredient_name)
         AND i.user_id = ?
       WHERE i.name IS NULL
          OR i.quantity < ri.quantity
       ORDER BY r.name, ri.ingredient_name`,
      [userId]
    );

    // Group by ingredient
    const grouped = {};
    for (const item of missing) {
      const key = item.ingredient_name.toLowerCase();
      if (!grouped[key]) {
        grouped[key] = {
          ingredient_name: item.ingredient_name,
          unit: item.unit,
          total_needed: 0,
          available: item.available_quantity,
          recipes: [],
        };
      }
      grouped[key].total_needed += parseFloat(item.needed_quantity);
      grouped[key].recipes.push(item.recipe_name);
    }

    res.json({
      items: Object.values(grouped),
      total_items: Object.keys(grouped).length,
    });
  } catch (err) {
    console.error('Shopping list error:', err);
    res.status(500).json({ error: 'Failed to generate shopping list.' });
  }
});

module.exports = router;
