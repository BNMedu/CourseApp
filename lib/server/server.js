const app = require('./app');
const config = require('./config');

const PORT = process.env.PORT || config.port;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server started on http://0.0.0.0:${PORT}`);
});
