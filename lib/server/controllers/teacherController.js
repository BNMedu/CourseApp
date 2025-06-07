const User = require('../models/User');

// Получить все ответы учеников для учителя/админа
exports.getAllAnswers = async (req, res) => {
    try {
        // Получаем всех пользователей, кроме админов и учителей
        const users = await User.find({ role: 'user' });
        // Собираем ответы с нужной информацией
        const answers = [];
        users.forEach(user => {
            (user.answers || []).forEach(ans => {
                answers.push({
                    email: user.email,
                    username: user.username,
                    lessonId: ans.lessonId,
                    score: ans.score,
                    answers: ans.answers,
                    teacherFeedback: ans.teacherFeedback || '',
                });
            });
        });
        // Можно добавить сортировку по дате
        answers.sort((a, b) => (b.submittedAt || 0) - (a.submittedAt || 0));
        res.json(answers);
    } catch (err) {
        res.status(500).json({ message: 'Ошибка получения ответов', error: err.message });
    }
};

// Принять ответ (teacherFeedback -> 'approved')
exports.approveAnswer = async (req, res) => {
    const { email, lessonId } = req.body;
    if (!email || !lessonId) {
        return res.status(400).json({ message: 'Не хватает email или lessonId' });
    }
    try {
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: 'Пользователь не найден' });

        const answer = user.answers.find(a => a.lessonId === lessonId);
        if (!answer) return res.status(404).json({ message: 'Ответ не найден' });

        answer.teacherFeedback = 'approved';
        await user.save();

        res.json({ message: 'Ответ принят (approved)' });
    } catch (err) {
        res.status(500).json({ message: 'Ошибка подтверждения', error: err.message });
    }
};
