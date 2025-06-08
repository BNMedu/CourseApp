// controllers/adminController.js

const User = require('../models/User');

exports.updateUser = async (req, res) => {
    try {
        const {
            email,
            newEmail,
            username,
            birthDate,
            city,
            phone,
            course,
            role,
            parentNames,
            twoFactorEnabled
        } = req.body;

        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }

        // Ищем пользователя по старому email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Если смена email
        if (newEmail && newEmail !== email) {
            const exists = await User.findOne({ email: newEmail });
            if (exists) {
                return res.status(400).json({ message: 'New email is already in use' });
            }
            user.email = newEmail;
        }

        // Обновляем остальные поля
        const allowed = { username, birthDate, city, phone, course, role, parentNames };
        Object.entries(allowed).forEach(([key, val]) => {
            if (val !== undefined) user[key] = val;
        });

        // Двухфакторка
        if (twoFactorEnabled !== undefined) {
            user.security.twoFactorEnabled = twoFactorEnabled;
            user.security.twoFactorCode = undefined;
            user.security.twoFactorExpires = undefined;
        }

        await user.save();
        res.json({ message: 'User updated successfully' });

    } catch (err) {
        console.error('Admin updateUser error:', err);
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};
