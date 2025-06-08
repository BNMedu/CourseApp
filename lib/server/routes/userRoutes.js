const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');
// Поиск пользователя по email (только для админа/модера)
const User = require('../models/User');
const role = require('../middleware/role');        // новый middleware



// Получить профиль
router.get('/profile', auth, userController.getProfile);
// Обновить профиль (тот же профиль)
router.put('/profile', auth, userController.updateProfile);

// Сменить пароль
router.put('/change-password', auth, userController.changePassword);




router.get(
    '/account-by-email',
    auth,
    role('admin'),
    async (req, res) => {
        const { email } = req.query;
        if (!email) return res.status(400).json({ message: 'Email is required' });
        const user = await User.findOne({ email }).lean();
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json(user);
    }
);

module.exports = router;