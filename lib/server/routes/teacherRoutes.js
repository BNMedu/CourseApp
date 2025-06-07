const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');
const auth = require('../middleware/auth');

// Получить все ответы учеников
router.get('/answers', auth, teacherController.getAllAnswers);

// Принять ответ
router.post('/approve-answer', auth, teacherController.approveAnswer);

module.exports = router;
