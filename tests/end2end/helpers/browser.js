const webdriverio = require('webdriverio')
const chromedriver = require('chromedriver')
const fs = require('fs')

function getBrowser() {
  const PORT = 9515


  chromedriver.start([
    '--url-base=wd/hub',
    `--port=${PORT}`
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
      binary: '',
      chromeOptions: {
        args
      }
    }
  }

  const chromium = '/usr/bin/chromium-browser'
  if (fs.existsSync(chromium)) {
    opts.desiredCapabilities.binary = chromium
  }

  return webdriverio.remote(opts).init()
}

module.exports = {
  getBrowser
}
