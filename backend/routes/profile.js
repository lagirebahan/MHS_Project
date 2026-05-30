const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');


router.get('/profile', verifyToken, (req, res) => {
  const userId = req.user.user_id;

  db.query(
    'SELECT user_id, user_name, email, role, created_at FROM users WHERE user_id = ?',
    [userId],
    (err, userResults) => {
      if (err) return res.status(500).json({ message: '500 Server Error' });
      if (userResults.length === 0) return res.status(404).json({ message: '404 Not Found' });

      const user = userResults[0];

      db.query(
        `SELECT t.transaction_id, t.total_price, t.status, t.created_at,
                ti.product_name, ti.quantity, ti.price
         FROM transactions t
         JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
         WHERE t.user_id = ?
         ORDER BY t.created_at DESC`,
        [userId],
        (err, txResults) => {
          if (err) return res.status(500).json({ message: '500 Server Error' });

          // Group items under their transaction
          const txMap = {};
          for (const row of txResults) {
            const id = row.transaction_id;
            if (!txMap[id]) {
              txMap[id] = {
                transaction_id: id,
                total_price: row.total_price,
                status: row.status,          // 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
                created_at: row.created_at,
                items: [],
              };
            }
            txMap[id].items.push({
              product_name: row.product_name,
              quantity: row.quantity,
              price: row.price,
            });
          }

          res.status(200).json({
            user_id: user.user_id,
            user_name: user.user_name,
            email: user.email,
            role: user.role,
            member_since: user.created_at,
            transactions: Object.values(txMap),
          });
        }
      );
    }
  );
});
 
//Profile page
router.get('/history', verifyToken, (req, res) => {
    const user_id  = req.user.user_id;
    
    const sql = `
        SELECT 
            t.transaction_id,
            t.total_price,
            t.created_at,
            GROUP_CONCAT(ti.product_name SEPARATOR '||') AS item_names,
            GROUP_CONCAT(ti.quantity SEPARATOR '||') AS item_quantities
        FROM transactions t
        LEFT JOIN transaction_items ti 
            ON t.transaction_id = ti.transaction_id
        WHERE t.user_id = ?
        GROUP BY t.transaction_id
        ORDER BY t.created_at DESC
    `;

    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json({ message: 'Database error' });
        res.json(results);
    });
});

module.exports = router;