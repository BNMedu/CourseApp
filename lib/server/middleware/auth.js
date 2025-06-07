const jwt = require('jsonwebtoken');
const config = require('../config');

// Для защищённых роутов — userId будет лежать в req.userId
module.exports = function (req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ message: 'Unauthorized: No token provided' });
    }

    const token = authHeader.split(' ')[1]; // Bearer <token>
    if (!token) {
        return res.status(401).json({ message: 'Unauthorized: Token not found' });
    }

    try {
        const decoded = jwt.verify(token, config.jwtSecret);
        req.userId = decoded.id;
        req.userRole = decoded.role; // если вдруг понадобится
        next();
    } catch (err) {
        return res.status(401).json({ message: 'Unauthorized: Invalid token' });
    }
};
