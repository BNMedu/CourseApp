const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const newsController = require('../controllers/newsController');
const auth = require('../middleware/auth');        // уже ставит req.userRole

// Создать новость (только админ)
router.post('/', auth,newsController.createNews);
// Получить все новости (или по тегу)
router.get('/',  newsController.getNews);
// Обновить новость (только админ)
router.put('/:id', auth,  newsController.updateNews);
// Удалить новость (только админ)
router.delete('/:id', auth,  newsController.deleteNews);

module.exports = router;
