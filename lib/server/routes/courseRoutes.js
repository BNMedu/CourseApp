const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const auth = require('../middleware/auth');

// Добавить курс (например, только админ/учитель — можно добавить ещё auth+роль)
router.post('/', auth, courseController.addCourse);
// Получить курс по ID (lesson)
router.get('/:lesson', auth, courseController.getCourse);
// Прогресс пользователя
router.get('/progress/me', auth, courseController.getProgress);
// Отправить ответ на тест/практику
router.post('/submit-answer', auth, courseController.submitAnswer);
router.get('/check-answer', auth, courseController.checkAnswer);


module.exports = router;
