const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/auth');

router.post('/', verifyToken, (req, res) => {
    const { order_ids, name, phone, address } = req.body;

    if (!order_ids || !Array.isArray(order_ids) || order_ids.length === 0)
        return res.status(400).json({ message: '400 Bad Request: no items' });
    if (!name || !phone || !address)
        return res.status(400).json({ message: '400 Bad Request: missing delivery info' });

    const userId = req.user.user_id;
    const placeholders = order_ids.map(() => '?').join(',');

    db.beginTransaction(err => {
        if (err) return res.status(500).json({ message: '500 Server Error' });

        const rollback = (msg) => db.rollback(() => res.status(500).json({ message: msg }));

        db.query(
            `SELECT o.order_id, o.product_id, o.quantity, p.product_name, p.price, p.stock
             FROM orders o
             JOIN products p ON o.product_id = p.product_id
             WHERE o.order_id IN (${placeholders}) AND o.user_id = ?`,
            [...order_ids, userId],
            (err, items) => {
                if (err) return rollback('500 Server Error');
                if (items.length === 0)
                    return db.rollback(() =>
                        res.status(404).json({ message: '404 Not Found: no matching cart items' })
                    );

                for (const item of items) {
                    if (item.quantity > item.stock) {
                        return db.rollback(() =>
                            res.status(400).json({
                                message: `Insufficient stock for "${item.product_name}". Available: ${item.stock}`,
                            })
                        );
                    }
                }

                const totalPrice = items.reduce(
                    (sum, i) => sum + parseFloat(i.price) * i.quantity, 0
                ).toFixed(2);

                db.query(
                    'INSERT INTO transactions (user_id, recipient_name, phone, address, total_price) VALUES (?, ?, ?, ?, ?)',
                    [userId, name, phone, address, totalPrice],
                    (err, result) => {
                        if (err) return rollback('500 Server Error');

                        const transactionId = result.insertId;

                        const itemValues = items.map(i => [
                            transactionId,
                            i.product_id,
                            i.product_name,
                            i.quantity,
                            parseFloat(i.price),
                        ]);
                        db.query(
                            'INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, price) VALUES ?',
                            [itemValues],
                            (err) => {
                                if (err) return rollback('500 Server Error');

                                const stockCases = items
                                    .map(() => 'WHEN product_id = ? THEN stock - ?')
                                    .join(' ');
                                const stockParams = items.flatMap(i => [i.product_id, i.quantity]);
                                const productIds = items.map(i => i.product_id);
                                const productPlaceholders = productIds.map(() => '?').join(',');

                                db.query(
                                    `UPDATE products
                                     SET stock = CASE ${stockCases} END
                                     WHERE product_id IN (${productPlaceholders})`,
                                    [...stockParams, ...productIds],
                                    (err) => {
                                        if (err) return rollback('500 Server Error');

                                        db.query(
                                            `DELETE FROM orders WHERE order_id IN (${placeholders}) AND user_id = ?`,
                                            [...order_ids, userId],
                                            (err) => {
                                                if (err) return rollback('500 Server Error');

                                                db.commit(err => {
                                                    if (err) return rollback('500 Server Error');
                                                    res.status(200).json({
                                                        message: 'Order placed successfully!',
                                                        transaction_id: transactionId,
                                                    });
                                                });
                                            }
                                        );
                                    }
                                );
                            }
                        );
                    }
                );
            }
        );
    });
});

module.exports = router;