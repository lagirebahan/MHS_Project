const db = require('../db');

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

module.exports = {verifyAdmin, verifyToken};