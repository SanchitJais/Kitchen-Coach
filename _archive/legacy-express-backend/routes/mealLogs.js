const express = require('express');
const pool = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/meal-logs — user's meal history
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT ml.log_id, ml.consumed_date, ml.rating, ml.notes,
              r.recipe_id, r.name AS recipe_name, r.difficulty_level, r.prep_time
       FROM meal_logs ml
       LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
       WHERE ml.user_id = ?
       ORDER BY ml.consumed_date DESC`,
      [req.user.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error('Get meal logs error:', err);
    res.status(500).json({ error: 'Failed to fetch meal logs.' });
  }
});

// POST /api/meal-logs — log a meal
router.post('/', auth, async (req, res) => {
  try {
    const { recipe_id, consumed_date, rating, notes } = req.body;

    if (!recipe_id || !consumed_date) {
      return res.status(400).json({ error: 'Recipe and date are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO meal_logs (user_id, recipe_id, consumed_date, rating, notes)
       VALUES (?, ?, ?, ?, ?)`,
      [req.user.userId, recipe_id, consumed_date, rating || null, notes || null]
    );

    const [newLog] = await pool.query(
      `SELECT ml.*, r.name AS recipe_name
       FROM meal_logs ml
       LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
       WHERE ml.log_id = ?`,
      [result.insertId]
    );

    res.status(201).json(newLog[0]);
  } catch (err) {
    console.error('Log meal error:', err);
    res.status(500).json({ error: 'Failed to log meal.' });
  }
});

// DELETE /api/meal-logs/:id — delete a meal log
router.delete('/:id', auth, async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM meal_logs WHERE log_id = ? AND user_id = ?',
      [req.params.id, req.user.userId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Meal log not found.' });
    }
    res.json({ message: 'Meal log deleted.' });
  } catch (err) {
    console.error('Delete meal log error:', err);
    res.status(500).json({ error: 'Failed to delete meal log.' });
  }
});

// GET /api/meal-logs/stats — meal statistics for dashboard
router.get('/stats', auth, async (req, res) => {
  try {
    const [stats] = await pool.query(
      `SELECT COUNT(*) AS total_meals,
              ROUND(AVG(rating), 1) AS avg_rating,
              COUNT(DISTINCT recipe_id) AS unique_recipes
       FROM meal_logs
       WHERE user_id = ?`,
      [req.user.userId]
    );

    const [recent] = await pool.query(
      `SELECT ml.consumed_date, ml.rating, r.name AS recipe_name
       FROM meal_logs ml
       LEFT JOIN recipes r ON ml.recipe_id = r.recipe_id
       WHERE ml.user_id = ?
       ORDER BY ml.consumed_date DESC
       LIMIT 5`,
      [req.user.userId]
    );

    res.json({ ...stats[0], recent_meals: recent });
  } catch (err) {
    console.error('Meal stats error:', err);
    res.status(500).json({ error: 'Failed to fetch meal stats.' });
  }
});

module.exports = router;
