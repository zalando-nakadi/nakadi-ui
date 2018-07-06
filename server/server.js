const App = require('./App');
const Config = require('./config');
const dotenv = require('dotenv');
const logger = require('./logger');
//read from .env file and set values of ENV variables if they wasn't set already.
dotenv.config();

//transform plain hash to config object
const config = Config(process.env);

App(config).listen(config.port, () => {
    logger.log("info", "Server listening", {
        port: config.port,
        baseUrl: config.baseUrl
    });
});

