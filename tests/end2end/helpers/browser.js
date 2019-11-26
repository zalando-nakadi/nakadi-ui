const webdriverio = require('webdriverio')
const chromedriver = require('chromedriver')
const fs = require('fs')

function getBrowser() {
  const PORT = 9515

  chromedriver.start([
    '--url-base=wd/hub',
    '--disable-extensions',
    '--whitelisted-ips',
    '--verbose',
    `--port=${PORT}`
  ])

  const inCI = process.env['CI']

  const args = inCI ?
      ['--headless', '--no-sandbox', '--whitelisted-ips', '--disable-extensions', '--single-process']
      : []

  const opts = {
    port: PORT,
    desiredCapabilities: {
      browserName: 'chrome',
      acceptSslCerts : true,
      chromeOptions: {
        args
      }
    }
  }

  const chromium = '/usr/bin/chromium-browser'
  if (fs.existsSync(chromium)) {
    console.log('chromium-browser found.')
    opts.desiredCapabilities.chromeOptions.binary = chromium
  } else {
    console.log('chromium-browser not found, using default chrome.')
  }

  return webdriverio.remote(opts).init()
}

module.exports = {
  getBrowser
}
