// controllers/courseController.js

const mongoose = require('mongoose');
const Course = require('../models/Course');
const User = require('../models/User');


// Добавить новый курс
exports.addCourse = async (req, res) => {
    try {
        const course = new Course(req.body);
        await course.save();
        res.status(201).json({ message: 'Course added successfully' });
    } catch (err) {
        console.error('Add course error:', err);
        res.status(500).json({ message: 'Add course error', error: err.message });
    }
};


// Получить курс по ID (lesson)
exports.getCourse = async (req, res) => {
    try {
        const lessonId = req.params.lesson;
        const isObjectId = mongoose.Types.ObjectId.isValid(lessonId);

        const course = await Course.findOne({
            $or: [
                ...(isObjectId ? [{ _id: lessonId }] : []),
                { videoId: lessonId }
            ]
        });

        if (!course) {
            return res.status(404).json({ message: 'Lesson not found' });
        }

        // Выбираем 5 случайных вопросов
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
        console.error('Get course error:', err);
        res.status(500).json({ message: 'Get course error', error: err.message });
    }
};


// Прогресс пользователя по курсу
exports.getProgress = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const courseKey = (user.course || 'web').toLowerCase();

        // user.progress хранится как Map в Mongoose
        const progressMap = user.progress || new Map();
        const progressData = progressMap.get(courseKey) || { lessonsCompleted: [] };
        const completed = Array.from(new Set(progressData.lessonsCompleted));

        res.json({
            progress: {
                [courseKey]: { lessonsCompleted: completed }
            },
            analytics: {
                totalLessons: 50,
                completedLessonsCount: completed.length
            }
        });
    } catch (err) {
        console.error('Progress error:', err);
        res.status(500).json({ message: 'Progress error', error: err.message });
    }
};


// Принять ответ пользователя (quiz)
exports.submitAnswer = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const { lessonId, score, answers, projectLinks } = req.body;
        if (!lessonId || score === undefined || !Array.isArray(answers)) {
            return res.status(400).json({ message: 'Missing fields' });
        }

        // Уже сдан?
        if (user.answers.some(a => a.lessonId === lessonId)) {
            return res.status(409).json({ message: 'Lesson already completed' });
        }

        // Сохраняем ответы
        user.answers.push({
            lessonId,
            submittedAt: new Date(),
            score,
            teacherFeedback: '',
            answers,
            projectLinks
        });

        // Ключ курса, например 'web'
        const courseKey = lessonId.split('_')[0];

        // Работаем с Map
        if (!user.progress) {
            user.progress = new Map();
        }
        if (!user.progress.has(courseKey)) {
            user.progress.set(courseKey, {
                lessonsCompleted: [],
                quizzesPassed: [],
                projectsSubmitted: [],
                certificateIssued: false
            });
        }

        const progress = user.progress.get(courseKey);

        // Добавляем урок
        if (!progress.lessonsCompleted.includes(lessonId)) {
            progress.lessonsCompleted.push(lessonId);
        }

        // Отметка викторины
        const quizKey = `${lessonId}_quiz`;
        if (!progress.quizzesPassed.includes(quizKey)) {
            progress.quizzesPassed.push(quizKey);
        }

        // Ссылки на проекты
        if (Array.isArray(projectLinks) && projectLinks.length > 0) {
            projectLinks.forEach(url => {
                if (!progress.projectsSubmitted.includes(url)) {
                    progress.projectsSubmitted.push(url);
                }
            });
        }

        // Обязательно отметить изменённым
        user.markModified('progress');
        await user.save();

        res.json({ message: 'Answer saved successfully' });
    } catch (err) {
        console.error('Submit answer error:', err);
        res.status(500).json({ message: 'Submit answer error', error: err.message });
    }
};


// Проверка, сдан ли урок
exports.checkAnswer = async (req, res) => {
    try {
        const { lessonId } = req.query;
        const user = await User.findById(req.userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        const answered = user.answers.some(a => a.lessonId === lessonId);
        res.json({ answered });
    } catch (err) {
        console.error('Check answer error:', err);
        res.status(500).json({ message: 'Check answer error', error: err.message });
    }
};
