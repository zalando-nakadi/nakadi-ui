const webdriverio = require('webdriverio')
const chromedriver = require('chromedriver')

function getBrowser() {
  const PORT = 9515


  chromedriver.start([
    '--url-base=wd/hub',
    `--port=${PORT}`,
    //uncomment for debug '--verbose'
  ])

  const inCI = process.env['CI']

  const args = inCI ?
      ['--headless', '--no-sandbox', '--single-process']
      : []

  const opts = {
    port: PORT,
    desiredCapabilities: {
      browserName: 'chrome',
      chromeOptions: {
        args
      }
    }
  }
  return webdriverio.remote(opts).init()
}

module.exports = {
  getBrowser: getBrowser
}
