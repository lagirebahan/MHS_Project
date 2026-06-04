const express = require('express');
const router = express.Router();
const db = require('../db');
const bcrypt = require('bcrypt');
const baseUrl = `http://${process.env.HOST || 'localhost'}:${process.env.PORT || 3001}`;
const jwt = require('jsonwebtoken')

const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
    },
});

router.post('/register', async (req, res) => {
    const {user_name, email, password} = req.body;
    if(!user_name || !email || !password) return res.status(400).json({message:'400 Bad Request'});

    const hashedPassword = await bcrypt.hash(password, 10);

    db.query('SELECT * FROM users WHERE email =?',[email],(err, results)=>{
        if(err) return res.status(500).json({message:'500 Server Error'});

        if(results.length > 0){
            if(results[0].auth_provider === 'google'){
                return res.status(400).json({message:'This email is linked to a Google account. Please sign in with Google.'});
            }
            return res.status(400).json({message:'Email already exists.'});
        }

            // const token = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const verifyToken = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const sql = "INSERT INTO users (user_name, email, password, auth_provider, is_verified, verify_token) VALUES (?,?,?,'local',0,?)";
        db.query(sql,[user_name, email, hashedPassword, verifyToken], (err) => {
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

router.get('/verify-email', (req, res) => {
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

router.post('/login', (req, res) => {
    console.log('LOGIN ROUTE HIT');
    const {email, password} = req.body;
    const sql = "SELECT * FROM users WHERE email = ?";

    db.query(sql,[email], async (err, results) => {
        if(err) return res.status(500).json({message: "500 Server Error"});
        if (results.length === 0) return res.status(401).json({ message: '401 Unauthorized' });
 
        const user = results[0];
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({
                message: 'Invalid credentials'
            });
        }

        const token = jwt.sign(
            {
                user_id: user.user_id,
                role: user.role,
                email: user.email
            },
            process.env.JWT_SECRET,
            {
                expiresIn: '7d'
            }
        );

        if (user.is_verified === 0)
            return res.status(403).json({ message: 'Please verify your email before signing in.' });
 
        res.status(200).json({
            message: 'Login berhasil!',
            token,
            role: user.role,
            user_name: user.user_name,
            email: user.email,
        });
    });
});

router.post('/google-login', (req, res) => {
    const { email, name } = req.body;
    if (!email) return res.status(400).json({ message: '400 Bad Request' });
 
    db.query('SELECT * FROM users WHERE email = ?', [email], (err, results) => {
        if (err) return res.status(500).json({ message: '500 Server Error' });
 
        if (results.length > 0) {
            const user = results[0];

            const jwttoken = jwt.sign(
                {
                    user_id: user.user_id,
                    role: user.role,
                    email: user.email
                },
                process.env.JWT_SECRET,
                {
                    expiresIn: '7d'
                }
            );
            return res.status(200).json({
                message: 'Login berhasil!',
                token: jwttoken,
                role: user.role,
                user_name: user.user_name,
                email: user.email,
            });
        }
 
        
        const sql = "INSERT INTO users (user_name, email, auth_provider, role, is_verified) VALUES (?, ?, 'google', 'user', 1)";
        db.query(sql, [name, email], (err, result) => {
            if (err) return res.status(500).json({ message: '500 Server Error' });
            const jwttoken = jwt.sign(
                {
                    user_id: result.insertId,
                    role:'user',
                    email:email
                }, process.env.JWT_SECRET,{
                    expiresIn:'7d'
                }
            )
            res.status(200).json({ message: 'Login berhasil!', token: jwttoken, role: 'user', user_name: name , email:email});
        });
    });
});

module.exports = router;