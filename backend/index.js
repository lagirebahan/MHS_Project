require('dotenv').config();

const express = require('express');
const multer = require('multer');
const mysql = require('mysql2');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const nodemailer = require('nodemailer');

const app = express();
const port = process.env.PORT||3001;
const host = process.env.HOST||'localhost';
const baseUrl = `http://${host}:${port}`;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname,'uploads'))); 

// ---DATABASE---
//koneksi database
const db = mysql.createConnection({
    host:'localhost',
    user:'root',
    password:'',
    database:'wuwa',
});

db.connect((err)=>{
    if(err) throw err;
    console.log('Database connected!');
});

// ---nodemailer---
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.MAIL_USER,   // your gmail
    pass: process.env.MAIL_PASS,   // gmail app password (not your real password)
  },
});

// ---multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({storage: storage});

// ---middleawre---
const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if(!token) return res.status(401).json({message:'401 Unauthorized'});
    db.query('SELECT * FROM users WHERE token = ?', [token], (err, results) => {
        if(err||results.length===0) return res.status(401).json({message:'401 Unauthorized'});
        req.user = results[0];
        next();
    });
};

const verifyAdmin = (req, res, next) => {
    if(req.user.role !== 'admin') return res.status(403).json({message:'403 Forbidden'});
    next();
};

//---auth---
//endpoint register
app.post('/api/register', (req, res) => {
    const {user_name, email, password} = req.body;
    if(!user_name || !email || !password) return res.status(400).json({message:'400 Bad Request'});

    db.query('SELECT * FROM users WHERE email =?',[email],(err, results)=>{
        if(err) return res.status(500).json({message:'500 Server Error'});

        if(results.length > 0){
            if(results[0].auth_provider === 'google'){
                return res.status(400).json({message:'This email is linked to a Google account. Please sign in with Google.'});
            }
            return res.status(400).json({message:'Email already exists.'});
        }

        const token = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const verifyToken = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const sql = "INSERT INTO users (user_name, email, password, auth_provider, token, is_verified, verify_token) VALUES (?,?,?,'local',?,0,?)";
        db.query(sql,[user_name, email, password, token, verifyToken], (err) => {
            if(err) return res.status(500).json({message: "500 Server Error"});

            const verifyUrl = `${baseUrl}/api/verify-email?token=${verifyToken}`;
            transporter.sendMail({
                from: process.env.MAIL_USER,
                to: email,
                subject: 'Verify your email',
                html: `<p>Hi ${user_name},</p>
                       <p>Click below to verify your account:</p>
                       <a href="${verifyUrl}" style="background:#00e5ff;padding:10px 20px;color:#000;text-decoration:none;border-radius:6px;">Verify Email</a>
                       <p>If you did not create this account, ignore this email.</p>`,
            });
            res.status(201).json({message:"User Successfully Registered! Please check your email to verify."});
        });
    });
});

//endpoint verify email
app.get('/api/verify-email', (req, res) => {
    const { token } = req.query;
    if (!token) return res.status(400).send('Invalid link.');
 
    db.query('SELECT * FROM users WHERE verify_token = ?', [token], (err, results) => {
        if (err || results.length === 0)
            return res.status(400).send('Invalid or expired link.');
 
        db.query('UPDATE users SET is_verified = 1, verify_token = NULL WHERE verify_token = ?', [token], (err) => {
            if (err) return res.status(500).send('Server error.');
            res.send('<h2 style="font-family:sans-serif">Email verified! You can now sign in.</h2>');
        });
    });
});

//endpoint login
app.post('/api/login', (req, res) => {
    const {email, password} = req.body;
    const sql = "SELECT * FROM users WHERE email = ? AND password = ?";
    db.query(sql,[email, password], (err, results) => {
        if(err) return res.status(500).json({message: "500 Server Error"});
        if (results.length === 0) return res.status(401).json({ message: '401 Unauthorized' });
 
        if (results[0].is_verified === 0)
            return res.status(403).json({ message: 'Please verify your email before signing in.' });
 
        res.status(200).json({
            message: 'Login berhasil!',
            token: results[0].token,
            role: results[0].role,
            user_name: results[0].user_name,
            email: results[0].email,
        });
    });
});

// endpoint google login
app.post('/api/google-login', (req, res) => {
    const { email, name } = req.body;
    if (!email) return res.status(400).json({ message: '400 Bad Request' });
 
    db.query('SELECT * FROM users WHERE email = ?', [email], (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
 
        if (results.length > 0) {
            return res.status(200).json({
                message: 'Login berhasil!',
                token: results[0].token,
                role: results[0].role,
                user_name: results[0].user_name,
                email: results[0].email,
            });
        }
 
        const token = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const sql = "INSERT INTO users (user_name, email, auth_provider, token, role, is_verified) VALUES (?, ?, 'google', ?, 'user', 1)";
        db.query(sql, [name, email, token], (err) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            res.status(200).json({ message: 'Login berhasil!', token, role: 'user', user_name: name });
        });
    });
});

// ─── PRODUCT ENDPOINTS ────────────────────────────────────────────────────────
 
// GET all products
app.get('/api/products', verifyToken, (req, res) => {
    db.query('SELECT * FROM products', (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        res.status(200).json(results);
    });
});
 
// POST insert product (admin only)
app.post('/api/products', verifyToken, verifyAdmin, upload.single('image'), (req, res) => {
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
 
// PATCH update product (admin only)
app.patch('/api/products/:product_id', verifyToken, verifyAdmin, upload.single('image'), (req, res) => {
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
                const oldPath = path.join(__dirname, 'uploads', oldFilename);
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
 
// DELETE product (admin only)
app.delete('/api/products/:product_id', verifyToken, verifyAdmin, (req, res) => {
    const { product_id } = req.params;
 
    db.query('SELECT image FROM products WHERE product_id = ?', [product_id], (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
        if (results.length === 0) return res.status(404).json({ message: '404 Not Found' });
 
        const oldUrl = results[0].image;
        if (oldUrl) {
            const oldFilename = oldUrl.split('/uploads/')[1];
            const oldPath = path.join(__dirname, 'uploads', oldFilename);
            if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
        }
 
        db.query('DELETE FROM products WHERE product_id = ?', [product_id], (err) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            res.status(200).json({ message: 'Product deleted!' });
        });
    });
});
 
// ─── CART ENDPOINTS ───────────────────────────────────────────────────────────
 
// GET cart
app.get('/api/cart', verifyToken, (req, res) => {
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
 
// POST add to cart
app.post('/api/cart', verifyToken, (req, res) => {
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
 
// PATCH update cart quantity
app.patch('/api/cart/:order_id', verifyToken, (req, res) => {
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
 
// DELETE cart item
app.delete('/api/cart/:order_id', verifyToken, (req, res) => {
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

// ─── CHECKOUT ENDPOINT ────────────────────────────────────────────────────────

// POST /api/checkout
app.post('/api/checkout', verifyToken, (req, res) => {
    const { order_ids, name, phone, address } = req.body;

    // Validation
    if (!order_ids || !Array.isArray(order_ids) || order_ids.length === 0)
        return res.status(400).json({ message: '400 Bad Request: no items' });
    if (!name || !phone || !address)
        return res.status(400).json({ message: '400 Bad Request: missing delivery info' });

    const userId = req.user.user_id;
    const placeholders = order_ids.map(() => '?').join(',');

    // Start DB transaction
    db.beginTransaction(err => {
        if (err) return res.status(500).json({ message: '500 Server Error' });

        const rollback = (msg) => db.rollback(() => res.status(500).json({ message: msg }));

        // 1. Fetch cart items
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

                // 2. Check stock
                for (const item of items) {
                    if (item.quantity > item.stock) {
                        return db.rollback(() =>
                            res.status(400).json({
                                message: `Insufficient stock for "${item.product_name}". Available: ${item.stock}`,
                            })
                        );
                    }
                }

                // 3. Calculate total server-side (ignore client total_price)
                const totalPrice = items.reduce(
                    (sum, i) => sum + parseFloat(i.price) * i.quantity, 0
                ).toFixed(2);

                // 4. Insert transaction
                db.query(
                    'INSERT INTO transactions (user_id, recipient_name, phone, address, total_price) VALUES (?, ?, ?, ?, ?)',
                    [userId, name, phone, address, totalPrice],
                    (err, result) => {
                        if (err) return rollback('500 Server Error');

                        const transactionId = result.insertId;

                        // 5. Insert transaction_items
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

                                // 6. Decrement stock using a single query
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

                                        // 7. Delete from cart
                                        db.query(
                                            `DELETE FROM orders WHERE order_id IN (${placeholders}) AND user_id = ?`,
                                            [...order_ids, userId],
                                            (err) => {
                                                if (err) return rollback('500 Server Error');

                                                // 8. Commit
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


app.get('/api/profile', verifyToken, (req, res) => {
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
app.get('/api/history', verifyToken, (req, res) => {
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
// ─── START ────────────────────────────────────────────────────────────────────
 
app.listen(port, () => console.log(`Backend API running at ${baseUrl}`));