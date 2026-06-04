const db = require('../db');
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({message: 'Unauthorized'});
    
    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        req.user = decoded;

        next();
    } catch {
        return res.status(401).json({
            message: 'Invalid token'
        });
    }


    // if(!token) return res.status(401).json({message:'401 Unauthorized'});
    // db.query('SELECT * FROM users WHERE token = ?', [token], (err, results) => {
    //     if(err||results.length===0) return res.status(401).json({message:'401 Unauthorized'});
    //     req.user = results[0];
    //     next();
    // });
};

const verifyAdmin = (req, res, next) => {
    if(req.user.role !== 'admin') return res.status(403).json({message:'403 Forbidden'});
    next();
};

module.exports = {verifyAdmin, verifyToken};