const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

router.get('/', verifyToken, (req, res) => {
    const sql = `
        SELECT o.order_id, o.quantity, o.created_at,
               p.product_id, p.product_name, p.type, p.price, p.image, p.stock
        FROM orders o
        JOIN products p ON o.product_id = p.product_id
        WHERE o.user_id = ?
        ORDER BY o.created_at ASC
    `;
    db.query(sql, [req.user.user_id], (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        res.status(200).json(results);
    });
});
 
router.post('/', verifyToken, (req, res) => {
    const { product_id, quantity = 1 } = req.body;
    if (!product_id) return res.status(400).json({ message: '400 Bad Request' });
 
    db.query(
        'SELECT * FROM orders WHERE user_id = ? AND product_id = ?',
        [req.user.user_id, product_id],
        (err, results) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
 
            if (results.length > 0) {
                const newQty = results[0].quantity + quantity;
                db.query(
                    'UPDATE orders SET quantity = ? WHERE order_id = ?',
                    [newQty, results[0].order_id],
                    (err) => {
                        if (err) return res.status(500).json({ message: '500 Server Error' });
                        res.status(200).json({ message: 'Quantity updated', order_id: results[0].order_id });
                    }
                );
            } else {
                db.query(
                    'INSERT INTO orders (user_id, product_id, quantity) VALUES (?, ?, ?)',
                    [req.user.user_id, product_id, quantity],
                    (err, result) => {
                        if (err) return res.status(500).json({ message: '500 Server Error' });
                        res.status(201).json({ message: '201 Created', order_id: result.insertId });
                    }
                );
            }
        }
    );
});
 
router.patch('/:order_id', verifyToken, (req, res) => {
    const { quantity } = req.body;
    const { order_id } = req.params;
    if (!quantity || quantity < 1) return res.status(400).json({ message: '400 Bad Request' });
 
    db.query(
        'UPDATE orders SET quantity = ? WHERE order_id = ? AND user_id = ?',
        [quantity, order_id, req.user.user_id],
        (err, result) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            if (result.affectedRows === 0) return res.status(404).json({ message: '404 Not Found' });
            res.status(200).json({ message: 'Quantity updated' });
        }
    );
});
 
router.delete('/:order_id', verifyToken, (req, res) => {
    const { order_id } = req.params;
    db.query(
        'DELETE FROM orders WHERE order_id = ? AND user_id = ?',
        [order_id, req.user.user_id],
        (err, result) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            if (result.affectedRows === 0) return res.status(404).json({ message: '404 Not Found' });
            res.status(200).json({ message: 'Item removed' });
        }
    );
});

module.exports = router;