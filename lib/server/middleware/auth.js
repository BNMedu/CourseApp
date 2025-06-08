const jwt = require('jsonwebtoken');
const config = require('../config');
const User = require('../models/User');

// Для защищённых роутов — userId будет лежать в req.userId, а вся инфа в req.user
module.exports = async function (req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({ message: 'No token' });
    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, config.jwtSecret);
        const user = await User.findById(decoded.id);
        if (!user) return res.status(401).json({ message: 'User not found' });
        req.user = { id: user._id, role: user.role, email: user.email };
        req.userId = user._id;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Invalid token' });
    }
};
