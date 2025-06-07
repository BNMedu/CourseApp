const nodemailer = require('nodemailer');
const config = require('../config');

// Настраиваем transporter
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: config.email.user,
        pass: config.email.pass
    },
    socketTimeout: 10000 // 10 секунд на отправку
});

// Функция отправки кода для сброса пароля
async function sendResetCode(to, username, code) {
    await transporter.sendMail({
        from: '"BNM EDU Support" <noreply@bnm.edu>',
        to,
        subject: 'Your BNM EDU Reset Code',
        text:
`Hello ${username},

Your password reset code is: ${code}
This code is valid for 10 minutes.

If you did not request a reset, ignore this message.

- BNM EDU Support`
    });
}

// Функция отправки 2FA-кода
async function send2faCode(to, username, code) {
    await transporter.sendMail({
        from: '"BNM EDU Security" <noreply@bnm.edu>',
        to,
        subject: 'Your BNM EDU 2FA Code',
        text:
`Hello ${username},

Your 2FA login code is: ${code}
It is valid for 10 minutes.

If this wasn't you, ignore this message.`
    });
}

module.exports = {
    sendResetCode,
    send2faCode
};
