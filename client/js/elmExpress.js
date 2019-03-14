class ElmExpress {

  static create(window, routes) {

    const app = new ElmExpress()
    routes(app)

    const OriginalXMLHttpRequest = window.XMLHttpRequest
    window.XMLHttpRequest = function () {
      const xhr = new OriginalXMLHttpRequest()
      const originalOpen = xhr.open
      xhr.open = function (method, url, async) {
        if (!url.startsWith('elm:')) {
          return originalOpen.apply(xhr, arguments)
        }

        ['status', 'statusText', 'responseText', 'response', 'setRequestHeader']
            .forEach(prop =>
                Object.defineProperty(xhr, prop, {writable: true}))


        //who cares about request headers here? :)
        xhr.setRequestHeader = () => {
        }

        xhr.send = body => app.run(xhr, method, url, body)

      }
      return xhr
    }
  }

  constructor() {
    this.handlers = {}
  }

  use(method, funcName, func) {
    this.handlers[this.toKey(method, funcName)] = func
  }

  toKey(method, funcName) {
    return `${method.toLocaleLowerCase()}:${funcName}`
  }

  get(funcName, func) {
    this.use('get', funcName, func)
  }

  put(funcName, func) {
    this.use('put', funcName, func)
  }

  post(funcName, func) {
    this.use('post', funcName, func)
  }

  patch(funcName, func) {
    this.use('patch', funcName, func)
  }

  delete(funcName, func) {
    this.use('delete', funcName, func)
  }

  run(xhr, method, url, body) {
    return this.route(method, url, body)
        .then(([code, responseText]) => {
          console.log('ElmExpress response:', code, responseText)
          xhr.status = code
          xhr.statusText = `code:${code}`
          xhr.response = xhr.responseText = responseText || ''
          xhr.dispatchEvent(new Event('load'))
        })
  }

  route(method, url, body) {
    const parsed = new URL(url)
    return new Promise(resolve => {

      const key = this.toKey(method, parsed.pathname)
      const handler = this.handlers[key]
      if (!handler) {
        return resolve([404, `Unknown function: ${method} ${parsed.pathname}`])
      }

      const json = tryJsonParse(body)

      const params = parsed.searchParams

      const req = {params, body, json, method, url}

      const res = new Response(resolve)

      try {
        console.log('ElmExpress request:', req, res)
        handler(req, res)
      } catch (e) {
        return resolve([500, `Internal JS error: ${e.toString()}`])
      }

    })
  }

}

function tryJsonParse(body) {
  if (!body) {
    return
  }

  try {
    return JSON.parse(body)
  } catch (e) {
    console.log('it is not a json', body)
  }
}

class Response {
  constructor(resolve) {
    this.resolve = resolve
  }

  text(res) {
    this.resolve([200, res])
  }

  ok() {
    this.resolve([200, '"OK"'])
  }

  json(res) {
    this.resolve([200, JSON.stringify(res)])
  }

  error(e = 'Internal error.') {
    this.resolve([500, `${e.toString()}`])
  }
}

module.exports = ElmExpress.create
