const express = require('express');
const pool = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/ingredients — all ingredients for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT i.*, sl.location_type, sl.temperature_range,
              DATEDIFF(i.expiration_date, CURDATE()) AS days_until_expiry
       FROM ingredients i
       LEFT JOIN storage_locations sl ON i.location = sl.location
       WHERE i.user_id = ?
       ORDER BY i.expiration_date ASC`,
      [req.user.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error('Get ingredients error:', err);
    res.status(500).json({ error: 'Failed to fetch ingredients.' });
  }
});

// GET /api/ingredients/expiring — items expiring within 3 days
router.get('/expiring', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT i.*, DATEDIFF(i.expiration_date, CURDATE()) AS days_until_expiry
       FROM ingredients i
       WHERE i.user_id = ?
         AND i.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
         AND i.expiration_date >= CURDATE()
       ORDER BY i.expiration_date ASC`,
      [req.user.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error('Get expiring error:', err);
    res.status(500).json({ error: 'Failed to fetch expiring ingredients.' });
  }
});

// POST /api/ingredients — add ingredient
router.post('/', auth, async (req, res) => {
  try {
    const { name, quantity, unit, expiration_date, location, calories_per_unit } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Ingredient name is required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO ingredients (user_id, name, quantity, unit, expiration_date, location, calories_per_unit)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.user.userId, name, quantity || 0, unit || 'g', expiration_date || null, location || 'pantry', calories_per_unit || 0]
    );

    const [newItem] = await pool.query('SELECT * FROM ingredients WHERE ingredient_id = ?', [result.insertId]);
    res.status(201).json(newItem[0]);
  } catch (err) {
    console.error('Add ingredient error:', err);
    if (err.sqlState === '45000') {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to add ingredient.' });
  }
});

// PUT /api/ingredients/:id — update ingredient
router.put('/:id', auth, async (req, res) => {
  try {
    const { name, quantity, unit, expiration_date, location, calories_per_unit } = req.body;

    // Verify ownership
    const [existing] = await pool.query(
      'SELECT * FROM ingredients WHERE ingredient_id = ? AND user_id = ?',
      [req.params.id, req.user.userId]
    );
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Ingredient not found.' });
    }

    await pool.query(
      `UPDATE ingredients SET name = ?, quantity = ?, unit = ?, expiration_date = ?, location = ?, calories_per_unit = ?
       WHERE ingredient_id = ? AND user_id = ?`,
      [
        name || existing[0].name,
        quantity !== undefined ? quantity : existing[0].quantity,
        unit || existing[0].unit,
        expiration_date || existing[0].expiration_date,
        location || existing[0].location,
        calories_per_unit !== undefined ? calories_per_unit : existing[0].calories_per_unit,
        req.params.id,
        req.user.userId,
      ]
    );

    const [updated] = await pool.query('SELECT * FROM ingredients WHERE ingredient_id = ?', [req.params.id]);
    res.json(updated[0]);
  } catch (err) {
    console.error('Update ingredient error:', err);
    res.status(500).json({ error: 'Failed to update ingredient.' });
  }
});

// DELETE /api/ingredients/:id — delete ingredient
router.delete('/:id', auth, async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM ingredients WHERE ingredient_id = ? AND user_id = ?',
      [req.params.id, req.user.userId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Ingredient not found.' });
    }
    res.json({ message: 'Ingredient deleted.' });
  } catch (err) {
    console.error('Delete ingredient error:', err);
    res.status(500).json({ error: 'Failed to delete ingredient.' });
  }
});

module.exports = router;
