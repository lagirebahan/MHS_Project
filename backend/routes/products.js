const express = require('express');
const router = express.Router();
const db = require('../db');
const path = require('path');
const fs = require('fs');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const multer = require('multer');

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

const baseUrl = `http://${process.env.HOST || 'localhost'}:${process.env.PORT || 3001}`;

router.get('/', verifyToken, (req, res) => {
    db.query('SELECT * FROM products', (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        res.status(200).json(results);
    });
});
 
//admin actions
router.post('/', verifyToken, verifyAdmin, upload.single('image'), (req, res) => {
    const { product_name, type, description, stock, price } = req.body;
    if (!req.file || !product_name || !type || !stock || !price)
        return res.status(400).json({ message: '400 Invalid Input' });
 
    const imageUrl = `${baseUrl}/uploads/${req.file.filename}`;
    const sql = "INSERT INTO products (product_name, type, description, stock, image, price) VALUES (?, ?, ?, ?, ?, ?)";
    db.query(sql, [product_name, type, description, stock, imageUrl, price], (err) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        res.status(201).json({ message: '201 Created: Equipment added!' });
    });
});
 
router.patch('/:product_id', verifyToken, verifyAdmin, upload.single('image'), (req, res) => {
    const { product_id } = req.params;
    const { product_name, type, description, stock, price } = req.body;
 
    if (!product_name || !type || !stock || !price)
        return res.status(400).json({ message: '400 Invalid Input' });
 
    if (req.file) {
        db.query('SELECT image FROM products WHERE product_id = ?', [product_id], (err, results) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            if (results.length === 0) return res.status(404).json({ message: '404 Not Found' });
 
            const oldUrl = results[0].image;
            if (oldUrl) {
                const oldFilename = oldUrl.split('/uploads/')[1];
                const oldPath = path.join(__dirname, '..', 'uploads', oldFilename);
                if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
            }
 
            const imageUrl = `${baseUrl}/uploads/${req.file.filename}`;
            const sql = "UPDATE products SET product_name=?, type=?, description=?, stock=?, image=?, price=? WHERE product_id=?";
            db.query(sql, [product_name, type, description, stock, imageUrl, price, product_id], (err) => {
                if (err) return res.status(500).json({ message: '500 Server Error' });
                res.status(200).json({ message: 'Product updated!' });
            });
        });
    } else {
        const sql = "UPDATE products SET product_name=?, type=?, description=?, stock=?, price=? WHERE product_id=?";
        db.query(sql, [product_name, type, description, stock, price, product_id], (err) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            res.status(200).json({ message: 'Product updated!' });
        });
    }
});
 
router.delete('/:product_id', verifyToken, verifyAdmin, (req, res) => {
    const { product_id } = req.params;
 
    db.query('SELECT image FROM products WHERE product_id = ?', [product_id], (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        if (results.length === 0) return res.status(404).json({ message: '404 Not Found' });
 
        const oldUrl = results[0].image;
        if (oldUrl) {
            const oldFilename = oldUrl.split('/uploads/')[1];
            const oldPath = path.join(__dirname, '..', 'uploads', oldFilename);
            if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
        }
 
        db.query('DELETE FROM products WHERE product_id = ?', [product_id], (err) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            res.status(200).json({ message: 'Product deleted!' });
        });
    });
});

module.exports = router;