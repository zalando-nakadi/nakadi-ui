const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const FaviconsWebpackPlugin = require('favicons-webpack-plugin');

module.exports = {

    entry: [
        './client/index.js'
    ],
    output: {
        path: path.join(__dirname, 'dist'),
        filename: 'bundle-[hash].js'
    },
    resolve: {
        extensions: ["", ".elm", ".js"]
    },
    plugins: [
        new ExtractTextPlugin('styles-[hash].css'),
        new webpack.optimize.OccurenceOrderPlugin(),
        new FaviconsWebpackPlugin('./client/assets/logo.svg'),
        new CopyWebpackPlugin([{
            context: './client/assets/static/',
            from: '',
            to: '',
            dot: true
        }]),
        new HtmlWebpackPlugin({
            title: 'Nakadi UI'
        })
    ],
    module: {
        noParse: /\.elm$/,
        loaders: [{
            test: /\.js$/,
            exclude: [/node_modules/],
            loader: 'babel-loader',
            options: {
                presets: ['@babel/preset-env']
            }
        }, {
            test: /\.json(\?.*)?$/,
            loader: "json-loader"
        }, {
            test: /\.css$/,
            loader: ExtractTextPlugin.extract('style-loader',
                'css-loader')
        }, {
            test: /\.(png|jpg|gif|svg|ttf|otf|eot|svg|woff2?)(\?.*)?$/,
            loader: "url-loader?limit=100000"
        }, {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            loader: 'elm-hot-loader!elm-webpack-loader?warn=true&pathToMake=node_modules/.bin/elm-make'
        }]
    }
};
