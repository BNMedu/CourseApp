const AdminNews = require('../models/AdminNews');
const User = require('../models/User');

// Создать новость (только админ)
exports.createNews = async (req, res) => {
    try {


        const { _id, title, description, image, tags } = req.body;
        const news = new AdminNews({ _id, title, description, image, tags });
        await news.save();
        res.status(201).json(news);
    } catch (err) {
        res.status(500).json({ message: 'Create news error', error: err.message });
    }
};

// Обновить новость (только админ)
exports.updateNews = async (req, res) => {
    try {


        const { id } = req.params;
        const { title, description, image, tags } = req.body;
        const updated = await AdminNews.findByIdAndUpdate(
            id, { title, description, image, tags }, { new: true }
        );
        if (!updated) return res.status(404).json({ message: 'News not found' });
        res.json(updated);
    } catch (err) {
        res.status(500).json({ message: 'Update news error', error: err.message });
    }
};

// Удалить новость (только админ)
exports.deleteNews = async (req, res) => {
    try {


        const { id } = req.params;
        const deleted = await AdminNews.findByIdAndDelete(id);
        if (!deleted) return res.status(404).json({ message: 'News not found' });
        res.json({ message: 'News deleted', id });
    } catch (err) {
        res.status(500).json({ message: 'Delete news error', error: err.message });
    }
};
// Получить все новости, опционально по тегу
exports.getNews = async (req, res) => {
    try {
        const { tag } = req.query;
        let query = {};
        if (tag) {
            query.tags = { $elemMatch: { $regex: new RegExp(tag, 'i') } };
        }
        const news = await AdminNews.find(query).sort({ createdAt: -1 });
        res.json(news);
    } catch (err) {
        res.status(500).json({ message: 'Fetch news error', error: err.message });
    }
};