require('./assets/styles.css')
require('./assets/fontawesome-all.js')

function loadScript(src) {
  const head = document.getElementsByTagName('head')[0]
  const script = document.createElement('script')
  script.type = 'text/javascript'
  script.src = src
  head.appendChild(script)
}

loadScript('https://cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ace.js')
loadScript('https://cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ext-language_tools.js')


const ElmExpress = require('./ElmExpress')
ElmExpress.create(window, router => {

      router.get('localStorage', (req, res) =>
          res.text(window.localStorage.getItem(req.params.get('key'))))

      router.post('localStorage', (req, res) =>
          res.ok(window.localStorage.setItem(req.params.get('key'), req.body)))

      router.post('title', (req, res) =>
          res.ok(document.title = req.body))

      router.post('forceReLogin', (req, res) =>
          res.ok(document.location.href = `${req.body}?returnTo=${encodeURIComponent(document.location.href)}`))

      router.post('pushState', (req, res) =>
          res.ok(history.pushState({}, '', req.body)))

      router.post('replaceState', (req, res) =>
          res.ok(history.replaceState({}, '', req.body)))

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
          return res.error('Selected file is too big. 2mb max.')
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
    }
)


const Elm = require('./Main')
Elm.Main.fullscreen()
