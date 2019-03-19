const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const FaviconsWebpackPlugin = require('favicons-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  mode: 'production',
  entry: [
    './client/index.js'
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'bundle-[hash].js'
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].css',
      chunkFilename: '[id].css'
    }),
    new FaviconsWebpackPlugin('./client/assets/logo.svg'),
    new CopyWebpackPlugin([{
      context: './client/assets/static/',
      from: '**/*',
      dot: true
    }]),
    new HtmlWebpackPlugin({
      title: 'Nakadi UI'
    })
  ],
  module: {
    noParse: [/\.elm$/],
    rules: [{
      test: /\.js$/,
      exclude: [/node_modules/],
      loader: 'babel-loader',
      options: {
        presets: ['@babel/preset-env']
      }
    }, {
      test: /\.json(\?.*)?$/,
      loader: 'json-loader'
    }, {

      test: /\.css$/,
      use: [MiniCssExtractPlugin.loader, 'css-loader']
    }, {
      test: /\.(png|jpg|gif|svg|ttf|otf|eot|svg|woff2?)(\?.*)?$/,
      loader: 'url-loader?limit=100000'
    }, {
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: [
        {
          loader: 'elm-webpack-loader',
          options: {
            cwd: __dirname
          }
        }
      ]
    }]
  }
}
