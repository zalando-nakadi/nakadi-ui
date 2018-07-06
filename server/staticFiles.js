const logger = require('./logger');
module.exports = function(productionMode) {

    if (productionMode) {
        let express = require('express');
        const options = {
            dotfiles: 'allow',
            etag: true,
            index: 'index.html',
            lastModified: true,
            maxAge: '1w'
        };

        return express.static('dist', options);
    }

    let webpack = require('webpack');
    let webpackDevMiddleware = require('webpack-dev-middleware');
    let webpackHotMiddleware = require('webpack-hot-middleware');
    let webpackConfig = require('../webpack.config.dev');

    const compiler = webpack(webpackConfig);
    const compilerOptions = {
        publicPath: webpackConfig.output.publicPath,
        noInfo: true
    };

    return [
        webpackDevMiddleware(compiler, compilerOptions),
        webpackHotMiddleware(compiler, {
            log: logger.log.bind(logger, "info")
        })
    ]
};
