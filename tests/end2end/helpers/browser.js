const { remote } = require('webdriverio')

const getBrowser = async() => {
  const inCI = process.env['CI']

  const argsForCI = inCI ? {
    headless: true,
    maxInstances: 1,
    maxInstancesPerCapability: 1
  } : {}

  const opts = {
    ...argsForCI,
    logLevel: 'trace',
    waitforTimeout: 30000,
    waitforInterval: 100,
    capabilities: {
      browserName: 'chrome',
    }
  }
  const browser = await remote(opts)
  return browser
}

module.exports = {
  getBrowser
}
