const mongoose = require('mongoose');

const QuestionSchema = new mongoose.Schema({
    questionText:       { type: String, required: true },
    options:            { type: [String], required: true },
    correctAnswerIndex: { type: Number, required: true }
}, { _id: false });

const CourseSchema = new mongoose.Schema({
    _id:         { type: String, required: true },
    title:       { type: String, required: true },
    description: { type: String, required: true },
    courseTitle: { type: String, required: true },
    videoUrl:    { type: String, required: true },
    questions:   { type: [QuestionSchema], required: true },
    targetAge:   { type: String, required: true },
    category:    { type: String, required: true }
});

module.exports = mongoose.model('Course', CourseSchema);
