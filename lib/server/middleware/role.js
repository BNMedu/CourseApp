// middleware/role.js
module.exports = function (requiredRole) {
    return function (req, res, next) {
        // req.userRole выставляется в auth middleware
        if (!req.userRole) {
            return res.status(401).json({ message: 'Not authorized (no role)' });
        }
        if (req.userRole !== requiredRole) {
            return res.status(403).json({ message: `No access (${requiredRole} only)` });
        }
        next();
    };
};
