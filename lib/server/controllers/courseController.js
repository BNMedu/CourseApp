const Course = require('../models/Course');
const User = require('../models/User');

// Добавить новый курс
exports.addCourse = async (req, res) => {
    try {
        const course = new Course(req.body);
        await course.save();
        res.status(201).json({ message: 'Course added successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Add course error', error: err.message });
    }
};

// Получить курс по ID
exports.getCourse = async (req, res) => {
    try {
        const course = await Course.findOne({ _id: req.params.lesson });
        if (!course) return res.status(404).json({ message: 'Lesson not found' });
        // 5 случайных вопросов
        const shuffled = course.questions.sort(() => 0.5 - Math.random());
        const selected = shuffled.slice(0, 5);

        res.json({
            _id: course._id,
            title: course.title,
            description: course.description,
            courseTitle: course.courseTitle,
            videoUrl: course.videoUrl,
            questions: selected
        });
    } catch (err) {
        res.status(500).json({ message: 'Get course error', error: err.message });
    }
};

// Прогресс пользователя по курсу
exports.getProgress = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });
        const courseKey = (user.course || 'web').toLowerCase();
        const keys = Object.keys(user.progress || {});
        const matchedKey = keys.find(k => k.toLowerCase() === courseKey) || 'web';
        const progressData = (user.progress || {})[matchedKey];
        if (!progressData || !Array.isArray(progressData.lessonsCompleted)) {
            return res.json({
                progress: {
                    [matchedKey]: { lessonsCompleted: [] }
                },
                analytics: { totalLessons: 50, completedLessonsCount: 0 }
            });
        }
        const completed = [...new Set(progressData.lessonsCompleted)];
        res.json({
            progress: { [matchedKey]: { lessonsCompleted: completed } },
            analytics: { totalLessons: 50, completedLessonsCount: completed.length }
        });
    } catch (err) {
        res.status(500).json({ message: 'Progress error', error: err.message });
    }
};

// Принять ответ пользователя (quiz)
exports.submitAnswer = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const { lessonId, score, answers, projectLinks } = req.body;
        if (!lessonId || score === undefined || !Array.isArray(answers)) {
            return res.status(400).json({ message: 'Missing fields' });
        }

        const already = user.answers.some(ans => ans.lessonId === lessonId);
        if (already) {
            return res.status(409).json({ message: 'Lesson already completed' });
        }

        user.answers.push({
            lessonId, submittedAt: new Date(), score, teacherFeedback: '', answers, projectLinks
        });

        const courseKey = lessonId.split('_')[0];

        // === Исправлено: работаем с объектом! ===
        if (!user.progress) user.progress = {};
        if (!user.progress[courseKey]) {
            user.progress[courseKey] = {
                lessonsCompleted: [],
                quizzesPassed: [],
                projectsSubmitted: [],
                certificateIssued: false
            };
        }
        const progress = user.progress[courseKey];

        if (!progress.lessonsCompleted.includes(lessonId)) {
            progress.lessonsCompleted.push(lessonId);
        }
        const quizKey = `${lessonId}_quiz`;
        if (!progress.quizzesPassed.includes(quizKey)) {
            progress.quizzesPassed.push(quizKey);
        }
        if (Array.isArray(projectLinks) && projectLinks.length > 0) {
            if (!progress.projectsSubmitted) progress.projectsSubmitted = [];
            for (const url of projectLinks) {
                if (!progress.projectsSubmitted.includes(url)) {
                    progress.projectsSubmitted.push(url);
                }
            }
        }
        await user.save();
        res.json({ message: 'Answer saved successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Submit answer error', error: err.message });
    }
};

exports.checkAnswer = async (req, res) => {
    const { lessonId } = req.query;
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    const answered = user.answers.some(ans => ans.lessonId === lessonId);
    res.json({ answered });
};
