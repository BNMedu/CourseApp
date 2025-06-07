const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const uploadController = require('../controllers/uploadController');
const auth = require('../middleware/auth');

// Настройка хранилища для multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'avatars/'),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, req.userId + ext);
    }
});
const upload = multer({ storage });

// Загрузка аватарки (авторизация нужна)
router.post('/avatar', auth, upload.single('avatar'), uploadController.uploadAvatar);

module.exports = router;
