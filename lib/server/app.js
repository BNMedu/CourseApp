const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const config = require('./config');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const courseRoutes = require('./routes/courseRoutes');
const newsRoutes = require('./routes/newsRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const errorHandler = require('./middleware/errorHandler');
const teacherRoutes = require('./routes/teacherRoutes');


const app = express();

// Подключение к MongoDB
mongoose.connect(config.mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

app.use(cors({
    origin: config.frontendUrl,
    credentials: true
}));
app.use(express.json());

// Папка для аватарок — public
app.use('/avatars', express.static('avatars'));

// Подключение роутов
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/news', newsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/teacher', teacherRoutes);


app.get('/', (req, res) => res.send('Server is running...'));

// Обработка ошибок (последний middleware)
app.use(errorHandler);

module.exports = app;
