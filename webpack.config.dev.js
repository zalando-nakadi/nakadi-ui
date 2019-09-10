const path = require('path')
const webpack = require('webpack')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  mode: 'development',
  stats: "errors-only",
  devtool: "source-map",
  bail: true,
  watch: true,
  entry: [
    'webpack-hot-middleware/client?reload=true',
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
    new CopyWebpackPlugin([{
      context: './client/assets/static/',
      from: '**/*',
      // TODO This 'dot' option is not working. ¯\_(ツ)_/¯
      // static/.well-konwn/schema-discovery Is unreachable.
      dot: true
    }]),
    new HtmlWebpackPlugin({
      title: 'Nakadi UI',
      favicon: 'client/assets/favicon.png',
      //tests fail if this is true
      cache: false
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
        {loader: 'elm-hot-webpack-loader'},
        {
          loader: 'elm-webpack-loader',
          options: {
            cwd: __dirname,
            cache: false,
            forceWatch: true
          }
        }
      ]
    }]
  }
}

