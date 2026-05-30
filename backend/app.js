require('dotenv').config();

const express = require('express');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const nodemailer = require('nodemailer');

const app = express();
const port = process.env.PORT||3001;
const host = process.env.HOST||'localhost';
const baseUrl = `http://${host}:${port}`;

const authRouter = require('./routes/auth');
const productsRouter = require('./routes/products');
const profileRouter = require('./routes/profile');
const checkoutRouter = require('./routes/checkout');
const cartRouter = require('./routes/cart');

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname,'uploads'))); 

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({storage: storage});

app.set('upload', upload);
app.set('mailer', transporter);
app.set('baseUrl', baseUrl);

app.use('/api', authRouter);
app.use('/api/products', productsRouter);
app.use('/api/cart', cartRouter);
app.use('/api/checkout', checkoutRouter);
app.use('/api', profileRouter);
 
app.listen(port, () => console.log(`Backend API running at ${baseUrl}`));