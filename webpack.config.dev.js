const path = require('path')
const webpack = require('webpack')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const FaviconsWebpackPlugin = require('favicons-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  mode: 'development',
  entry: [
    'webpack-hot-middleware/client',
    './client/index.js'
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'bundle-[hash].js',
    publicPath: '/'
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].css',
      chunkFilename: '[id].css'
    }),
    new webpack.HotModuleReplacementPlugin(),
    new FaviconsWebpackPlugin('./client/assets/logo.svg'),
    new CopyWebpackPlugin([{
      context: './client/assets/static/',
      from: '**/*',
      to: '/',
      //TODO This option is not working.
      // static/.well-konwn/schema-discovery Is unreachable.
      dot: true
    }], {logLevel: 'debug'}),
    new HtmlWebpackPlugin({
      title: 'Nakadi UI',
      //tests fail if this is true
      cache: false
    }),
    new webpack.HotModuleReplacementPlugin()
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
        {loader: 'elm-hot-webpack-loader'},
        {
          loader: 'elm-webpack-loader',
          options: {
            cwd: __dirname
          }
        }
      ]
    }]
  },
  devServer: {
    contentBase: './dist',
    historyApiFallback: false,
    hot: true,
    'module-bind': 'css=style\!css'
  }
}

