http = require('http')

srv = http.createServer((req, resp) ->
  console.log req.url
  h = req.headers
  h.host = 'localhost:2375'
  console.log 'client headers', h
  req2 = http.request({
    host: 'localhost'
    port: 2375
    path: req.url
    method: req.method
    headers: h
  }, (resp2) ->
    console.log 'headers',resp2.statusCode, resp2.headers
    resp.writeHead resp2.statusCode, resp2.headers
    resp2.on 'data', (d) ->
      console.log 'data from real docker', d.toString()
      resp.write d
    resp2.on 'error', (e) -> console.log 'err', e
    resp2.on 'end', ->
      resp.end()
  )
  req.on 'data', (d) ->
    req2.write d
  req.on 'end', ->
    req2.end()
).listen 3000, '127.0.0.1'

srv.on 'upgrade', (req, socket, head) ->
  console.log req.url
  h = req.headers
  h.host = 'localhost:2375'
  console.log 'want upgrade', h
  options =
    host: 'localhost'
    port: 2375
    path: req.url
    method: req.method
    headers: h

  socket.on 'data', (d) -> console.log 'socktdata', d.toString()
  req2 = http.request options


  req2.on 'upgrade', (res, socket2, upgradeHead) ->
    console.log 'got upgrade', res
    x = "HTTP/#{res.httpVersion} #{res.statusCode} #{res.statusMessage}\r\n"
    for name, value of res.headers
      x += "#{name}: #{value}\r\n"
    socket.write "#{x}r\n"
    socket2.pipe(socket).pipe(socket2)
    res.on 'data', (d) -> console.log 'upgradres data', d.toString()


  req.on 'data', (d) -> req2.write d
