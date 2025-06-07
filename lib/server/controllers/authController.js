const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const User = require('../models/User');
const mailer = require('../utils/mailer');

// Регистрация пользователя
exports.register = async (req, res) => {
    const { username, email, password, role = 'user', ...other } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ message: 'Missing required fields' });
    }
    try {
        const exists = await User.findOne({ $or: [{ username }, { email }] });
        if (exists) return res.status(409).json({ message: 'User already exists' });

        const hash = await bcrypt.hash(password, 10);
        const user = new User({
            username, email, password: hash, role,
            ...other,
            registrationDate: new Date()
        });
        await user.save();
        res.status(201).json({ message: 'User registered successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Registration error', error: err.message });
    }
};

// Логин пользователя
exports.login = async (req, res) => {
    const { username, password } = req.body;
    try {
        const user = await User.findOne({ username });
        if (!user) return res.status(404).json({ message: 'User not found' });
        const match = await bcrypt.compare(password, user.password);
        if (!match) return res.status(400).json({ message: 'Incorrect password' });

        // 2FA check (если нужно)
        if (user.security?.twoFactorEnabled) {
            return res.json({ twoFactorRequired: true, email: user.email });
        }

        const token = jwt.sign({ id: user._id, role: user.role }, config.jwtSecret, { expiresIn: '1h' });
        res.json({ token, role: user.role });
    } catch (err) {
        res.status(500).json({ message: 'Login error', error: err.message });
    }
};

// Отправка кода на email для 2FA
exports.send2FACode = async (req, res) => {
    const { email } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });
        if (!user.security.twoFactorEnabled) return res.status(400).json({ message: '2FA is not enabled' });

        // Генерация и отправка кода
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        user.security.twoFactorCode = code;
        user.security.twoFactorExpires = new Date(Date.now() + 10 * 60 * 1000);
        await user.save();
        console.log('2FA expires at:', user.security.twoFactorExpires);
        await mailer.send2faCode(email, user.username, code);
        res.json({ message: '2FA code sent to email' });
    } catch (err) {
        res.status(500).json({ message: '2FA send error', error: err.message });
    }
};

// Проверка кода 2FA
exports.verify2FACode = async (req, res) => {
    const { email, code } = req.body;
    try {
        // Поиск пользователя по email
        const user = await User.findOne({ email });
        if (!user || !user.security?.twoFactorEnabled) {
            return res.status(404).json({ message: 'User not found or 2FA not enabled' });
        }
        if (!user.security.twoFactorCode || !user.security.twoFactorExpires) {
            return res.status(400).json({ message: '2FA code not set' });
        }
        // Проверка истечения срока действия кода
        if (Date.now() > user.security.twoFactorExpires.getTime()) {
            return res.status(400).json({ message: '2FA code expired' });
        }

        // Сравнение кода (приводим к строке для надёжности)
        if (String(user.security.twoFactorCode) !== String(code)) {
            return res.status(400).json({ message: 'Invalid 2FA code' });
        }
        // Очистка кода после успешной проверки
        user.security.twoFactorCode = undefined;
        user.security.twoFactorExpires = undefined;
        await user.save();

        // Генерация JWT токена
        const token = jwt.sign({ id: user._id, role: user.role }, config.jwtSecret, { expiresIn: '1h' });
        res.json({ message: '2FA verified', token, role: user.role });
    } catch (err) {
        console.error('2FA verify error:', err);
        res.status(500).json({ message: '2FA verify error', error: err.message });
    }
};


// Сброс пароля (отправка кода)
exports.forgotPassword = async (req, res) => {
    const { email } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        user.resetCode = code;
        user.resetCodeExpires = Date.now() + 10 * 60 * 1000;
        await user.save();

        await mailer.sendResetCode(email, user.username, code);
        res.json({ message: 'Reset code sent to email' });
    } catch (err) {
        res.status(500).json({ message: 'Reset code error', error: err.message });
    }
};

// Сброс пароля по коду
exports.resetPassword = async (req, res) => {
    const { email, code, newPassword } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user || user.resetCode !== code) {
            return res.status(400).json({ message: 'Invalid code or user' });
        }
        if (Date.now() > user.resetCodeExpires) {
            return res.status(400).json({ message: 'Reset code expired' });
        }
        const hash = await bcrypt.hash(newPassword, 10);
        user.password = hash;
        user.resetCode = undefined;
        user.resetCodeExpires = undefined;
        user.security.passwordLastChanged = new Date();
        await user.save();

        res.json({ message: 'Password reset successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Reset password error', error: err.message });
    }
};
