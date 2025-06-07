const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const jwt = require("jsonwebtoken");
const nodemailer = require('nodemailer');
const multer = require('multer');
const path = require('path');

const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect('mongodb://localhost:27017/users', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'avatars/');
    },
    filename: function (req, file, cb) {
        // имя файла: userId + расширение
        const ext = path.extname(file.originalname);
        cb(null, req.userId + ext);
    }
});
const upload = multer({ storage: storage });
function authMiddleware(req, res, next) {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "beka_soska");
        req.userId = decoded.id;
        next();
    } catch {
        return res.status(401).json({ message: 'Invalid token' });
    }
}

// ======== СХЕМЫ ===========
const AdminNewsSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // теперь это строка, не ObjectId
    title: { type: String, required: true },
    description: { type: String, required: true },
    image: { type: String },
    tags: [{ type: String }], // массив тегов
    createdAt: { type: Date, default: Date.now }
});


const AdminNewsModel = mongoose.model('admin_news', AdminNewsSchema);

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
        twoFactorCode: { type: String },
        twoFactorExpires: { type: Date },
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
    ],
    avatarUrl: { type: String },


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

// Эндпойнт для загрузки аватарки

app.get('/check-answer', async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ answered: false });
    try {
        const decoded = jwt.verify(token, "beka_soska");
        const user = await UserModel.findById(decoded.id);
        if (!user) return res.status(404).json({ answered: false });
        const lessonId = req.query.lessonId;
        const already = user.answers.some(a => a.lessonId === lessonId);
        res.json({ answered: already });
    } catch (e) {
        res.status(500).json({ answered: false });
    }
});

app.post('/upload-avatar', authMiddleware, upload.single('avatar'), async (req, res) => {
    try {
        const user = await UserModel.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.avatarUrl = `http://192.168.10.3:5000/avatars/${req.file.filename}`;
        await user.save();

        res.json({ message: 'Avatar uploaded', avatarUrl: user.avatarUrl });
    } catch (error) {
        res.status(500).json({ message: 'Upload error', error: error.message });
    }
});

// Отдача статики
app.use('/avatars', express.static('avatars'));
app.post('/admin/news', async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "beka_soska");
        const user = await UserModel.findById(decoded.id);
        if (!user || user.role !== 'admin') {
            return res.status(403).json({ message: 'Access denied' });
        }

        // <--- вот так:
        const { _id, title, description, image, tags } = req.body;
        if (!_id || !title || !description) {
            return res.status(400).json({ message: 'Missing fields (_id, title, description required)' });
        }

        const news = new AdminNewsModel({ _id, title, description, image, tags });
        await news.save();

        res.status(201).json(news);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});


app.post('/news', async (req, res) => {
    try {
        const { _id, title, description, image, tags } = req.body;
        const newNews = await AdminNewsModel.create({
            _id, title, description, image, tags
        });
        res.status(201).json(newNews);
    } catch (error) {
        res.status(500).json({ message: 'Error creating news', error: error.message });
    }
});

// PUT /news/:id
app.put('/news/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, image, tags } = req.body;
        const updatedNews = await AdminNewsModel.findByIdAndUpdate(
            id,
            { title, description, image, tags },
            { new: true }
        );
        if (!updatedNews) {
            return res.status(404).json({ message: 'News not found' });
        }
        res.json(updatedNews);
    } catch (error) {
        res.status(500).json({ message: 'Error editing news', error: error.message });
    }
});
// DELETE /news/:id
app.delete('/news/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const deletedNews = await AdminNewsModel.findByIdAndDelete(id);
        if (!deletedNews) {
            return res.status(404).json({ message: 'News not found' });
        }
        res.json({ message: 'News deleted', id });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting news', error: error.message });
    }
});
// GET /news?tag=ai
app.get('/news', async (req, res) => {
    try {
        const { tag } = req.query;
        let query = {};
        if (tag) {
            // Поиск, если тег есть в массиве тегов (без учёта регистра)
            query.tags = { $elemMatch: { $regex: new RegExp(tag, 'i') } };
        }
        const news = await AdminNewsModel.find(query).sort({ createdAt: -1 });
        res.json(news);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching news', error: error.message });
    }
});



app.get('/', (req, res) => res.send('Server is running...'));

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'teachers.capedu@gmail.com',
        pass: 'qunv gfjy eots nxhh', // Используйте пароль приложения!
    },
    socketTimeout: 10000, // ⏱️ максимум 10 сек на попытку отправки
});
app.get('/progress', async (req, res) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, "beka_soska");
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
        const decoded = jwt.verify(token, "beka_soska");
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
        const decoded = jwt.verify(token, "beka_soska");

        const user = await UserModel.findById(decoded.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const allowedFields = ['username', 'birthDate', 'city', 'phone'];
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                user[field] = req.body[field];
            }
        }

        // Обработка двухфакторки
        if (req.body.twoFactorEnabled !== undefined) {
            user.security.twoFactorEnabled = req.body.twoFactorEnabled;
            user.security.twoFactorCode = undefined;
            user.security.twoFactorExpires = undefined;
        }

        await user.save();

        res.json({ message: 'User updated successfully', user });
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
        const decoded = jwt.verify(token, "beka_soska");
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
        const decoded = jwt.verify(token, "beka_soska");
        const user = await UserModel.findById(decoded.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const { lessonId, score, answers, projectLinks } = req.body;
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

        if (!progress.lessonsCompleted.includes(lessonId)) {
            progress.lessonsCompleted.push(lessonId);
        }

        const quizKey = `${lessonId}_quiz`;
        if (!progress.quizzesPassed.includes(quizKey)) {
            progress.quizzesPassed.push(quizKey);
        }

        // --- Projects Submitted ---
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
            const decoded = jwt.verify(token, "beka_soska");
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

        if (user.security.twoFactorEnabled) {
            return res.json({
                twoFactorRequired: true,
                email: user.email
            });
        }

        // Только если 2FA не включена — выдать токен
        const token = jwt.sign({ id: user._id, role: user.role }, "beka_soska", { expiresIn: "1h" });

        res.json({
            token,
            role: user.role
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
        const decoded = jwt.verify(token, "beka_soska");
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
app.post('/send-2fa-code', async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    try {
        const user = await UserModel.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Безопасно инициализируем security, если его нет
        if (!user.security) user.security = {};

        if (!user.security.twoFactorEnabled) {
            return res.status(400).json({ message: '2FA is not enabled for this user' });
        }

        // Если код уже активен — не пересылать
        if (
            user.security.twoFactorCode &&
            user.security.twoFactorExpires &&
            Date.now() < user.security.twoFactorExpires
        ) {
            return res.status(429).json({ message: 'A code was already sent. Please wait.' });
        }

        const code = Math.floor(100000 + Math.random() * 900000).toString();
        user.security.twoFactorCode = code;
        user.security.twoFactorExpires = Date.now() + 10 * 60 * 1000; // 10 минут

        user.markModified('security');
        await user.save();

        // Ответ клиенту сразу
        res.json({ message: '2FA code is being sent to your email.' });

        // Отправка письма — асинхронно
        transporter.sendMail({
            from: '"BNM EDU Security" <noreply@bnm.edu>',
            to: email,
            subject: 'Your BNM EDU 2FA Code',
            text: `Hello ${user.username},\n\nYour 2FA login code is: ${code}\n\nIt is valid for 10 minutes.\n\nIf this wasn't you, ignore this message.`,
        }).then(() => {
            console.log(`✅ 2FA code sent to ${email}: ${code}`);
        }).catch(err => {
            console.error(`❌ Failed to send 2FA email to ${email}:`, err.message);
        });

    } catch (err) {
        console.error("Error in /send-2fa-code:", err.message);
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});
app.post('/verify-2fa-code', async (req, res) => {
    const { email, code } = req.body;

    if (!email || !code) {
        return res.status(400).json({ message: 'Missing fields' });
    }

    try {
        const user = await UserModel.findOne({ email });

        if (!user || !user.security?.twoFactorEnabled) {
            return res.status(404).json({ message: 'User not found or 2FA not enabled' });
        }

        if (!user.security.twoFactorCode || !user.security.twoFactorExpires) {
            return res.status(400).json({ message: '2FA code not set' });
        }

        const isExpired = new Date(user.security.twoFactorExpires).getTime() < Date.now();
        const isWrongCode = user.security.twoFactorCode !== code;

        if (isExpired) {
            return res.status(400).json({ message: 'Code expired' });
        }

        if (isWrongCode) {
            return res.status(400).json({ message: 'Invalid code' });
        }

        // Очистка кода после успешной верификации
        user.security.twoFactorCode = undefined;
        user.security.twoFactorExpires = undefined;
        user.markModified('security');
        await user.save();

        const token = jwt.sign(
            { id: user._id, role: user.role },
            'beka_soska',
            { expiresIn: '1h' }
        );

        res.json({ message: '2FA verified', token, role: user.role });

    } catch (error) {
        console.error("2FA verification error:", error.message);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});
app.get('/account-by-email', async (req, res) => {
    const email = req.query.email;
    if (!email) return res.status(400).json({ message: 'Email required' });

    const user = await UserModel.findOne({ email }).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json(user);
});
app.put('/admin/update-user', async (req, res) => {
    const { email, newEmail } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    const user = await UserModel.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Если передан новый email, проверяем что он свободен
    if (newEmail && newEmail !== email) {
        const emailExists = await UserModel.findOne({ email: newEmail });
        if (emailExists) {
            return res.status(400).json({ message: 'New email is already in use' });
        }
        user.email = newEmail;
    }

    // Обновляем любые поля, которые есть в req.body
    const allowedFields = [
        'username', 'birthDate', 'city', 'phone', 'course', 'role', 'parentNames'
    ];
    for (const field of allowedFields) {
        if (req.body[field] !== undefined) {
            user[field] = req.body[field];
        }
    }

    // 2FA (через security)
    if (req.body.twoFactorEnabled !== undefined) {
        user.security.twoFactorEnabled = req.body.twoFactorEnabled;
        user.security.twoFactorCode = undefined;
        user.security.twoFactorExpires = undefined;
        user.markModified('security');
    }

    await user.save();
    res.json({ message: 'User updated' });
});



app.listen(5000, '0.0.0.0', () => console.log('Server started on http://0.0.0.0:5000'));

