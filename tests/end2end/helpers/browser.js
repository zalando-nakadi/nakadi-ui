const webdriverio = require('webdriverio')
const chromedriver = require('chromedriver')
const fs = require('fs')

function getBrowser() {
  const PORT = 9515

  chromedriver.start([
    '--url-base=wd/hub',
    `--port=${PORT}`
  ])

  const inCI = process.env['CI']

  const args = inCI ?
      ['--headless', '--no-sandbox', '--single-process']
      : []

  const opts = {
    port: PORT,
    path: '/wd/hub',
    capabilities: {
      browserName: 'chrome',
      // acceptSslCerts : true,
      // chromeOptions: {
        // args
      // }
    }
  }

  const chromium = '/usr/bin/chromium-browser'
  if (fs.existsSync(chromium)) {
    console.log('chromium-browser found.')
    // opts.capabilities.chromeOptions.binary = chromium
  } else {
    console.log('chromium-browser not found, using default chrome.')
  }

  return webdriverio.remote(opts)
}

module.exports = {
  getBrowser
}
