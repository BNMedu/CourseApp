// routes/adminRoutes.js

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const adminController = require('../controllers/adminController');

// PUT /api/admin/update-user
router.put(
    '/update-user',
    
    adminController.updateUser
);

module.exports = router;
