const User = require('../models/User');

// Получить все ответы учеников для учителя/админа
exports.getAllAnswers = async (req, res) => {
    try {
        // Берём всех пользователей с ролью "user"
        const users = await User.find({ role: 'user' });
        const answers = [];

        for (const user of users) {
            // Собираем их прогресс в plain-object
            let progressObj = {};
            if (user.progress instanceof Map) {
                for (const [courseKey, data] of user.progress) {
                    progressObj[courseKey] = data;
                }
            } else if (user.progress) {
                // если progress уже обычный объект
                progressObj = { ...user.progress };
            }

            // Проходим по каждому answer и пушим нужные поля
            const userAnswers = user.answers || [];
            for (const ans of userAnswers) {
                answers.push({
                    email: user.email,
                    username: user.username,
                    lessonId: ans.lessonId,
                    score: ans.score,
                    answers: ans.answers,
                    projectLinks: ans.projectLinks || [],
                    teacherFeedback: ans.teacherFeedback || '',
                    progress: progressObj,
                    submittedAt: ans.submittedAt,
                });
            }
        }

        // Сортируем по дате сабмита (новые первыми)
        answers.sort((a, b) => (b.submittedAt || 0) - (a.submittedAt || 0));

        res.json(answers);
    } catch (err) {
        res.status(500).json({
            message: 'Ошибка получения ответов',
            error: err.message
        });
    }
};

// Принять ответ (устанавливает teacherFeedback = 'approved')
exports.approveAnswer = async (req, res) => {
    const { email, lessonId } = req.body;
    if (!email || !lessonId) {
        return res.status(400).json({ message: 'Не хватает email или lessonId' });
    }

    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }

        const answer = user.answers.find(a => a.lessonId === lessonId);
        if (!answer) {
            return res.status(404).json({ message: 'Ответ не найден' });
        }

        answer.teacherFeedback = 'approved';
        await user.save();

        res.json({ message: 'Ответ принят (approved)' });
    } catch (err) {
        res.status(500).json({
            message: 'Ошибка подтверждения',
            error: err.message
        });
    }
};
