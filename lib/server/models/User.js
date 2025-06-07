const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email:    { type: String, required: true, unique: true },
    password: { type: String, required: true },

    role: { type: String, enum: ['user', 'teacher', 'admin'], default: 'user' },

    birthDate: { type: String },
    city:      { type: String },
    phone:     { type: String },
    course:    { type: String },

    parentNames: {
        father: { type: String },
        mother: { type: String }
    },

    security: {
        passwordLastChanged: { type: Date, default: Date.now },
        loginHistory:        [Date],
        twoFactorCode:       { type: String },
        twoFactorExpires:    { type: Date },
        twoFactorEnabled:    { type: Boolean, default: false }
    },

    notifications: {
        emailEnabled: { type: Boolean, default: true },
        pushEnabled:  { type: Boolean, default: true },
        lastSent:     { type: Date, default: null }
    },

    progress: {
        type: Map,
        of: new mongoose.Schema({
            lessonsCompleted: [String],
            quizzesPassed:    [String],
            projectsSubmitted:[String],
            certificateIssued:{ type: Boolean, default: false }
        }, { _id: false })
    },

    resetCode:        { type: String },
    resetCodeExpires: { type: Date },

    answers: [
        {
            lessonId:        String,
            submittedAt:     Date,
            score:           Number,
            teacherFeedback: String,
            answers:         [mongoose.Schema.Types.Mixed], // массив ответов/данных
            projectLinks:    [String]
        }
    ],

    avatarUrl: { type: String },

    registrationDate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
