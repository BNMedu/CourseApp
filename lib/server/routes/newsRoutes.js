const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const newsController = require('../controllers/newsController');
const auth = require('../middleware/auth');        // уже ставит req.userRole
const role = require('../middleware/role');

// Создать новость (только админ)
router.post('/', auth,newsController.createNews);
// Получить все новости (или по тегу)
router.get('/', role('admin'), newsController.getNews);
// Обновить новость (только админ)
router.put('/:id', auth, role('admin'), newsController.updateNews);
// Удалить новость (только админ)
router.delete('/:id', auth, role('admin'), newsController.deleteNews);

module.exports = router;
