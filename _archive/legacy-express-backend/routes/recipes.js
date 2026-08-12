const express = require('express');
const pool = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/recipes — all recipes with ingredients
router.get('/', async (req, res) => {
  try {
    const [recipes] = await pool.query(
      `SELECT r.*, GROUP_CONCAT(DISTINCT rc.category) AS categories
       FROM recipes r
       LEFT JOIN recipe_categories rc ON r.recipe_id = rc.recipe_id
       GROUP BY r.recipe_id
       ORDER BY r.name`
    );

    // Fetch ingredients for each recipe
    for (let recipe of recipes) {
      const [ingredients] = await pool.query(
        'SELECT ingredient_name, quantity, unit FROM recipe_ingredients WHERE recipe_id = ?',
        [recipe.recipe_id]
      );
      recipe.ingredients = ingredients;
      recipe.categories = recipe.categories ? recipe.categories.split(',') : [];
    }

    res.json(recipes);
  } catch (err) {
    console.error('Get recipes error:', err);
    res.status(500).json({ error: 'Failed to fetch recipes.' });
  }
});

// GET /api/recipes/suggestions — ranked by ingredient match for user
router.get('/suggestions', auth, async (req, res) => {
  try {
    const userId = req.user.userId;

    const [recipes] = await pool.query(
      `SELECT r.recipe_id, r.name, r.instructions, r.prep_time, r.difficulty_level, r.image_url,
              COUNT(DISTINCT ri.ingredient_name) AS total_ingredients,
              COUNT(DISTINCT CASE WHEN i.name IS NOT NULL THEN ri.ingredient_name END) AS matched_ingredients,
              ROUND(
                COUNT(DISTINCT CASE WHEN i.name IS NOT NULL THEN ri.ingredient_name END) * 100.0
                / COUNT(DISTINCT ri.ingredient_name), 0
              ) AS match_percentage
       FROM recipes r
       JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
       LEFT JOIN ingredients i
         ON LOWER(i.name) = LOWER(ri.ingredient_name)
         AND i.user_id = ?
         AND i.quantity > 0
       GROUP BY r.recipe_id
       HAVING matched_ingredients >= 1
       ORDER BY match_percentage DESC, r.prep_time ASC`,
      [userId]
    );

    // Attach ingredient details
    for (let recipe of recipes) {
      const [ingredients] = await pool.query(
        `SELECT ri.ingredient_name, ri.quantity, ri.unit,
                CASE WHEN i.name IS NOT NULL THEN 1 ELSE 0 END AS available
         FROM recipe_ingredients ri
         LEFT JOIN ingredients i
           ON LOWER(i.name) = LOWER(ri.ingredient_name)
           AND i.user_id = ?
         WHERE ri.recipe_id = ?`,
        [userId, recipe.recipe_id]
      );
      recipe.ingredients = ingredients;

      const [categories] = await pool.query(
        'SELECT category FROM recipe_categories WHERE recipe_id = ?',
        [recipe.recipe_id]
      );
      recipe.categories = categories.map(c => c.category);
    }

    res.json(recipes);
  } catch (err) {
    console.error('Suggestions error:', err);
    res.status(500).json({ error: 'Failed to get suggestions.' });
  }
});

// GET /api/recipes/:id — single recipe detail
router.get('/:id', async (req, res) => {
  try {
    const [recipes] = await pool.query('SELECT * FROM recipes WHERE recipe_id = ?', [req.params.id]);
    if (recipes.length === 0) {
      return res.status(404).json({ error: 'Recipe not found.' });
    }

    const recipe = recipes[0];

    const [ingredients] = await pool.query(
      'SELECT ingredient_name, quantity, unit FROM recipe_ingredients WHERE recipe_id = ?',
      [recipe.recipe_id]
    );
    recipe.ingredients = ingredients;

    const [categories] = await pool.query(
      'SELECT category FROM recipe_categories WHERE recipe_id = ?',
      [recipe.recipe_id]
    );
    recipe.categories = categories.map(c => c.category);

    res.json(recipe);
  } catch (err) {
    console.error('Get recipe error:', err);
    res.status(500).json({ error: 'Failed to fetch recipe.' });
  }
});

// POST /api/recipes/:id/bookmark — bookmark a recipe
router.post('/:id/bookmark', auth, async (req, res) => {
  try {
    await pool.query(
      'INSERT IGNORE INTO user_recipes (user_id, recipe_id) VALUES (?, ?)',
      [req.user.userId, req.params.id]
    );
    res.json({ message: 'Recipe bookmarked.' });
  } catch (err) {
    console.error('Bookmark error:', err);
    res.status(500).json({ error: 'Failed to bookmark recipe.' });
  }
});

// DELETE /api/recipes/:id/bookmark — remove bookmark
router.delete('/:id/bookmark', auth, async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM user_recipes WHERE user_id = ? AND recipe_id = ?',
      [req.user.userId, req.params.id]
    );
    res.json({ message: 'Bookmark removed.' });
  } catch (err) {
    console.error('Remove bookmark error:', err);
    res.status(500).json({ error: 'Failed to remove bookmark.' });
  }
});

// GET /api/recipes/bookmarked/list — get user's bookmarked recipes
router.get('/bookmarked/list', auth, async (req, res) => {
  try {
    const [recipes] = await pool.query(
      `SELECT r.*
       FROM recipes r
       JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
       WHERE ur.user_id = ?
       ORDER BY r.name`,
      [req.user.userId]
    );

    for (let recipe of recipes) {
      const [ingredients] = await pool.query(
        'SELECT ingredient_name, quantity, unit FROM recipe_ingredients WHERE recipe_id = ?',
        [recipe.recipe_id]
      );
      recipe.ingredients = ingredients;
    }

    res.json(recipes);
  } catch (err) {
    console.error('Get bookmarks error:', err);
    res.status(500).json({ error: 'Failed to fetch bookmarked recipes.' });
  }
});

module.exports = router;
