const bcrypt = require('bcryptjs');

// Захэшировать пароль
async function hashPassword(password) {
    return await bcrypt.hash(password, 10);
}

// Сравнить пароль с хэшем
async function comparePassword(password, hash) {
    return await bcrypt.compare(password, hash);
}

module.exports = {
    hashPassword,
    comparePassword
};
