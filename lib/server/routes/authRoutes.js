const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const newsController = require('../controllers/newsController');
const auth = require('../middleware/auth');        // уже ставит req.userRole
const role = require('../middleware/role'); 

// Регистрация и вход
router.post('/register', auth, role('admin'), authController.register);
router.post('/login', authController.login);

// 2FA
router.post('/send-2fa-code', authController.send2FACode);
router.post('/verify-2fa-code', authController.verify2FACode);

// Сброс пароля
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

module.exports = router;
