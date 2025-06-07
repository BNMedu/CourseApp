const User = require('../models/User');

exports.uploadAvatar = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.avatarUrl = `http://${req.headers.host}/avatars/${req.file.filename}`;
        await user.save();

        res.json({ message: 'Avatar uploaded', avatarUrl: user.avatarUrl });
    } catch (err) {
        res.status(500).json({ message: 'Upload avatar error', error: err.message });
    }
};
