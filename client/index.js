require('./assets/styles.css')
require('./js/aceEditor')

const express = require('./js/elmExpress')

express(window, router => {

  router.get('localStorage', (req, res) =>
      res.text(window.localStorage.getItem(req.params.get('key'))))

  router.post('localStorage', (req, res) =>
      res.ok(window.localStorage.setItem(req.params.get('key'), req.body)))

  // Redirect never resolves as it reload the whole page.
  // We use it instead of Elm load() because we need current URL
  // It is very tricky to get current URL in Elm an push it to all levels
  // where logoutIfExpired function used (any request basically)
  router.post('forceReLogin', (req, res) =>
      document.location.href = `${req.body}?returnTo=${encodeURIComponent(document.location.href)}`)

  router.post('copyToClipboard', (req, res) => {
    const el = document.createElement('textarea')
    el.value = req.body
    el.setAttribute('readonly', '')
    el.style.position = 'absolute'
    el.style.left = '-9999px'
    document.body.appendChild(el)
    el.select()
    document.execCommand('copy')
    document.body.removeChild(el)
    res.ok()
  })


  router.get('loadFileFromInput', (req, res) => {
    const id = req.params.get('id')
    const reader = new FileReader()
    reader.onload = e => res.text(e.target.result)

    const file = document.getElementById(id).files[0]
    if (file.size > 2000000) {
      return res.error('Selected file is too big. 2MB Max.')
    }
    reader.readAsText(file)
  })

  router.post('downloadAs', (req, res) => {
    const format = req.params.get('format')
    const filename = req.params.get('filename')
    const blob = new Blob([req.body], {type: format})

    if (window.navigator.msSaveOrOpenBlob) {
      window.navigator.msSaveBlob(blob, filename)
      return res.ok()
    }

    const elem = window.document.createElement('a')
    elem.href = window.URL.createObjectURL(blob)
    elem.download = filename
    document.body.appendChild(elem)
    elem.click()
    document.body.removeChild(elem)
    window.URL.revokeObjectURL(elem.href)
    return res.ok()
  })
})


const {Elm} = require('./Main.elm')
Elm.Main.init()
