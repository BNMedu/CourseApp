const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const jwt = require("jsonwebtoken");
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect('mongodb://localhost:27017/users', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

// ======== СХЕМЫ ===========
const UserSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, default: 'user' },
    birthDate: { type: String },
    city: { type: String },
    phone: { type: String },
    course: { type: String },
    parentNames: {
        father: { type: String },
        mother: { type: String }
    },
    security: {
        passwordLastChanged: { type: Date, default: Date.now },
        loginHistory: [String],
        twoFactorEnabled: { type: Boolean, default: false }
    },
    notifications: {
        emailEnabled: { type: Boolean, default: true },
        pushEnabled: { type: Boolean, default: true },
        lastSent: { type: Date, default: null }
    },
    progress: {
        type: Map,
        of: new mongoose.Schema({
            lessonsCompleted: [String],
            quizzesPassed: [String],
            projectsSubmitted: [String],
            certificateIssued: { type: Boolean, default: false }
        })
    },
    resetCode: { type: String },
    resetCodeExpires: { type: Date },

    answers: [
        {
            lessonId: String,
            submittedAt: Date,
            score: Number,
            teacherFeedback: String
        }
    ]
});

const CourseSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
    courseTitle: { type: String, required: true },
    videoUrl: { type: String, required: true },
    questions: [
        {
            questionText: { type: String, required: true },
            options: { type: [String], required: true },
            correctAnswerIndex: { type: Number, required: true }
        }
    ],
    targetAge: { type: String, required: true },
    category: { type: String, required: true }
});

const UserModel = mongoose.model('users', UserSchema);
const CourseModel = mongoose.model('courses', CourseSchema);

// ========= ЭНДПОИНТЫ =========

app.get('/', (req, res) => res.send('Server is running...'));

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'teachers.capedu@gmail.com',
        pass: 'qunv gfjy eots nxhh' // лучше использовать OAuth или пароль приложения
    }
});
app.get('/progress', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "secret_key");
        const user = await UserModel.findById(decoded.id);

        if (!user) return res.status(404).json({ message: 'User not found' });

        const userCourseKey = (user.course || 'web').toLowerCase();
        const availableKeys = Array.from(user.progress?.keys() || []);
        const matchedKey = availableKeys.find(k => k.toLowerCase() === userCourseKey) || 'web';

        const progressData = user.progress.get(matchedKey);

        if (!progressData || !Array.isArray(progressData.lessonsCompleted)) {
            return res.json({
                progress: {
                    [matchedKey]: {
                        lessonsCompleted: []
                    }
                },
                analytics: {
                    totalLessons: 50,
                    completedLessonsCount: 0
                }
            });
        }

        const completedLessons = [...new Set(progressData.lessonsCompleted)];

        res.json({
            progress: {
                [matchedKey]: {
                    lessonsCompleted: completedLessons
                }
            },
            analytics: {
                totalLessons: 50,
                completedLessonsCount: completedLessons.length
            }
        });

    } catch (error) {
        console.error("Progress error:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});





app.post('/forgot-password', async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    try {
        const user = await UserModel.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Генерация кода
        const code = Math.floor(100000 + Math.random() * 900000).toString();

        // Сохранить код
        user.resetCode = code;
        user.resetCodeExpires = Date.now() + 10 * 60 * 1000; // 10 минут
        await user.save();

        // Отправка письма
        await transporter.sendMail({
            from: '"BNM EDU Support" <noreply@bnm.edu>',
            to: email,
            subject: 'Your BNM EDU Reset Code',
            text: `Hello ${user.username},\n\nYour password reset code is: ${code}\n\nThis code is valid for 10 minutes.\n\nIf you did not request a reset, ignore this message.\n\n- BNM EDU Support`,
        });

        res.json({ message: 'Reset code sent to email' });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// ✅ Эндпойнт для сброса пароля по коду
app.post('/reset-password', async (req, res) => {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
        return res.status(400).json({ message: 'Missing fields' });
    }

    try {
        const user = await UserModel.findOne({ email });
        if (!user || user.resetCode !== code) {
            return res.status(400).json({ message: 'Invalid code or user' });
        }

        if (Date.now() > user.resetCodeExpires) {
            return res.status(400).json({ message: 'Reset code expired' });
        }

        const hashed = await bcrypt.hash(newPassword, 10);
        user.password = hashed;
        user.resetCode = undefined;
        user.resetCodeExpires = undefined;
        user.security.passwordLastChanged = new Date();
        await user.save();

        res.json({ message: 'Password reset successfully' });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});


// Получение аккаунта
app.get('/account', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "secret_key");
        const user = await UserModel.findById(decoded.id).select('-password');
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.json(user);
    } catch (error) {
        res.status(401).json({ message: 'Invalid token' });
    }
});

// Обновление только разрешённых полей
app.put('/account/update', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "secret_key");

        const allowedFields = ['username', 'birthDate', 'city', 'phone'];
        const updateData = {};
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        }

        const updatedUser = await UserModel.findByIdAndUpdate(decoded.id, updateData, { new: true });
        res.json({ message: 'User updated successfully', user: updatedUser });
    } catch (error) {
        res.status(500).json({ message: 'Error updating user', error: error.message });
    }
});

// Проверка админа
app.get("/check-admin/:userId", async (req, res) => {
    try {
        const user = await UserModel.findById(req.params.userId);
        if (!user) return res.status(404).json({ error: "User not found" });

        res.json({ isAdmin: user.role === "admin" });
    } catch (error) {
        res.status(500).json({ error: "Server error" });
    }
});

// Добавление курса
app.post('/course', async (req, res) => {
    try {
        const courseData = req.body;
        const course = new CourseModel(courseData);
        await course.save();
        res.status(200).send({ message: 'Course added successfully' });
    } catch (err) {
        res.status(500).send({ message: 'Error adding course', error: err });
    }
});

// Получение курса по ID
app.get('/course/:lesson', async (req, res) => {
    try {
        const lessonId = req.params.lesson;

        const course = await CourseModel.findOne({
            $or: [{ _id: lessonId }, { videoId: lessonId }]
        });

        if (!course) return res.status(404).json({ message: 'Lesson not found' });

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
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});
app.get('/teacher/answers', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "secret_key");
        const teacher = await UserModel.findById(decoded.id);

        if (!teacher || teacher.role !== 'teacher') {
            return res.status(403).json({ message: 'Access denied. Only teachers allowed.' });
        }

        const users = await UserModel.find({ "answers.0": { $exists: true } });

        const result = [];

        users.forEach(user => {
            user.answers.forEach(answer => {
                result.push({
                    username: user.username,
                    email: user.email,
                    lessonId: answer.lessonId,
                    submittedAt: answer.submittedAt,
                    score: answer.score,
                    teacherFeedback: answer.teacherFeedback || null,
                });
            });
        });

        res.json(result);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});


app.post('/submit-answer', async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "secret_key");
        const user = await UserModel.findById(decoded.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const { lessonId, score, answers } = req.body;
        if (!lessonId || score === undefined || !Array.isArray(answers)) {
            return res.status(400).json({ message: 'Missing fields' });
        }

        // Проверяем, есть ли уже такая запись в answers
        const alreadySubmitted = user.answers.some(ans => ans.lessonId === lessonId);
        if (alreadySubmitted) {
            return res.status(409).json({ message: 'Lesson already completed' });
        }

        const answerData = {
            lessonId,
            submittedAt: new Date(),
            score,
            teacherFeedback: '',
            answers
        };

        user.answers.push(answerData);

        const courseKey = lessonId.split('_')[0];

        if (!user.progress.has(courseKey)) {
            user.progress.set(courseKey, {
                lessonsCompleted: [],
                quizzesPassed: [],
                projectsSubmitted: [],
                certificateIssued: false
            });
        }

        const progress = user.progress.get(courseKey);

        // Добавляем только если ещё не проходил
        if (!progress.lessonsCompleted.includes(lessonId)) {
            progress.lessonsCompleted.push(lessonId);
        }

        const quizKey = `${lessonId}_quiz`;
        if (!progress.quizzesPassed.includes(quizKey)) {
            progress.quizzesPassed.push(quizKey);
        }

        await user.save();

        res.json({ message: 'Answer saved successfully' });

    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});


// Регистрация
app.post('/register', async (req, res) => {
    const {
        username,
        password,
        role = 'user',
        email,
        birthDate,
        city,
        phone,
        course,
        parentNames = {}
    } = req.body;

    if (!username || !password || !email) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    if (role === 'admin') {
        const token = req.headers.authorization?.split(" ")[1];
        if (!token) return res.status(403).json({ message: 'Admin authorization required' });

        try {
            const decoded = jwt.verify(token, "secret_key");
            const requester = await UserModel.findById(decoded.id);
            if (!requester || requester.role !== 'admin') {
                return res.status(403).json({ message: 'Only admins can create admin accounts' });
            }
        } catch (err) {
            return res.status(401).json({ message: 'Invalid token' });
        }
    } else if (!['user', 'teacher'].includes(role)) {
        return res.status(400).json({ message: 'Invalid role' });
    }

    try {
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new UserModel({
            username,
            email,
            password: hashedPassword,
            role,
            birthDate,
            city,
            phone,
            course,
            parentNames,
            registrationDate: new Date(),
            notifications: {
                emailEnabled: true,
                pushEnabled: true,
                lastSent: null
            },
            progress: new Map(),
            answers: [],
            security: {
                twoFactorEnabled: false,
                passwordLastChanged: new Date(),
                loginHistory: []
            }
        });

        await newUser.save();
        res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error registering user', error: error.message });
    }
});



// Логин
// ✅ Логин
app.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const user = await UserModel.findOne({ username });

        // Проверка: существует ли пользователь
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Проверка: верный ли пароль
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Incorrect password' });
        }

        // Обновление истории входов
        const now = new Date();
        user.security.loginHistory.push(now);

        await user.save();

        // Генерация токена
        const token = jwt.sign({ id: user._id, role: user.role }, "secret_key", { expiresIn: "1h" });

        res.json({
            token,
            role: user.role,
            security: user.security
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

async function generateHash() {
    const passwordToTest = 'teacher123';
    const hash = await bcrypt.hash(passwordToTest, 10);
    console.log('Хэш:', hash);
}

generateHash();

app.put('/account/change-password', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    const { currentPassword, newPassword } = req.body;

    if (!token) return res.status(401).json({ message: 'Unauthorized' });
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Missing fields' });
    }

    try {
        const decoded = jwt.verify(token, "secret_key");
        const user = await UserModel.findById(decoded.id);

        if (!user) return res.status(404).json({ message: 'User not found' });

        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Current password is incorrect' });
        }

        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        user.password = hashedNewPassword;
        user.security.passwordLastChanged = new Date();

        await user.save();

        res.json({ message: 'Password changed successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});


app.listen(5000, () => console.log('Server started on http://localhost:5000'));
