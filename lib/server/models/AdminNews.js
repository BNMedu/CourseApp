const mongoose = require('mongoose');

const AdminNewsSchema = new mongoose.Schema({
    _id:         { type: String, required: true }, // Строка (например, 'news_1')
    title:       { type: String, required: true },
    description: { type: String, required: true },
    image:       { type: String },       // URL картинки (необязательно)
    tags:        [{ type: String }],     // Массив тегов
    createdAt:   { type: Date, default: Date.now }
});

module.exports = mongoose.model('AdminNews', AdminNewsSchema);
