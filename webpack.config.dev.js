const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const FaviconsWebpackPlugin = require('favicons-webpack-plugin');

module.exports = {
    devtool: 'inline-source-map',
    entry: [
        'webpack-hot-middleware/client',
        './client/index.js'
    ],
    output: {
        path: path.join(__dirname, 'dist'),
        filename: 'bundle-[hash].js',
        publicPath: ''
    },
    resolve: {
        extensions: ["", ".elm", ".js"]
    },
    plugins: [
        new ExtractTextPlugin('styles-[hash].css'),
        new webpack.optimize.OccurenceOrderPlugin(),
        new webpack.HotModuleReplacementPlugin(),
        new FaviconsWebpackPlugin('./client/assets/logo.svg'),
        new CopyWebpackPlugin([{
            context: './client/assets/static/',
            from: '',
            to: '',
            dot: true
        }]),
        new HtmlWebpackPlugin({
            title: 'Nakadi UI',
            //tests fail if this is true
            cache: false
        })
    ],
    module: {
        noParse: /\.elm$/,
        loaders: [{
            test: /\.js$/,
            exclude: [/node_modules/],
            loader: 'babel-loader'
        }, {
            test: /\.json(\?.*)?$/,
            loader: "json-loader"
        }, {
            test: /\.css$/,
            loaders: ['style-loader?sourceMap',
                'css-loader?sourceMap'
            ]

        }, {
            test: /\.(png|jpg|gif|svg|ttf|otf|eot|svg|woff2?)(\?.*)?$/,
            loader: "url-loader?limit=100000"
        }, {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            loader: 'elm-hot-loader!elm-webpack-loader?verbose=true&warn=true&pathToMake=node_modules/.bin/elm-make'
        }]
    },
    devServer: {
        contentBase: './dist',
        historyApiFallback: false,
        hot: true,
        "module-bind": "css=style\!css"
    }
};

