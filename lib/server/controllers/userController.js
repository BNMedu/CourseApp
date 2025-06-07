const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config');

// Получить профиль
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId).select('-password');
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json(user);
    } catch (err) {
        res.status(500).json({ message: 'Profile error', error: err.message });
    }
};

// Обновить профиль
exports.updateProfile = async (req, res) => {
    try {
        const allowedFields = ['username', 'birthDate', 'city', 'phone'];
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                user[field] = req.body[field];
            }
        }
        // 2FA включение/выключение
        if (req.body.twoFactorEnabled !== undefined) {
            user.security.twoFactorEnabled = req.body.twoFactorEnabled;
            user.security.twoFactorCode = undefined;
            user.security.twoFactorExpires = undefined;
        }
        await user.save();
        res.json({ message: 'User updated successfully', user });
    } catch (err) {
        res.status(500).json({ message: 'Update error', error: err.message });
    }
};

// Смена пароля
exports.changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Missing fields' });
    }
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });
        const match = await bcrypt.compare(currentPassword, user.password);
        if (!match) return res.status(400).json({ message: 'Current password is incorrect' });

        const hash = await bcrypt.hash(newPassword, 10);
        user.password = hash;
        user.security.passwordLastChanged = new Date();
        await user.save();
        res.json({ message: 'Password changed successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Change password error', error: err.message });
    }
};
