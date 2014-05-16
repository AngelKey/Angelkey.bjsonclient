
PORT = 4005
http = require 'http'
{request} = require '../../lib/main'
{prng} = require 'crypto'
url = require 'url'

#=======================================================================

server = null

handler = (req, res) ->
  bufs = []
  req.on 'data', (dat) ->
    bufs.push dat
  req.on 'end', () ->
    payload = Buffer.concat bufs
    res.writeHead 200, {}
    res.end req.headers['content-type']

start_server = (cb) ->
  server = http.createServer handler
  await server.listen PORT, defer err
  cb err

make_url = (path) ->
  return {
    hostname : "localhost"
    port : PORT
    pathname : path
    protocol : "http:"
  }

#=======================================================================

make_obj = () ->
  obj =
    id : prng(10)
    uid : prng(12)
    foos : [
      10,
      20,
      30,
      prng(40)
    ],
    uids : [
      [prng(3), prng(10),[prng(4), [prng(5)]]],
      prng(20)
    ]
    bars :
      pgp_fingerprint : prng(20)
      buxes : 
        x_id : prng(4)
        y_id : prng(3)
        dog : prng(6)
      dig : 10
      blah : prng(5)
  return obj

#=======================================================================

exports.init = (T,cb) ->
  await start_server defer err
  cb err

#=======================================================================

send_with_encoding = (T, enc, cb) ->
  opts = 
    url : make_url "/foo.json"
    arg :
      encoding : enc
      data : make_obj()
    method : "POST"
  await request opts, defer err, res, body
  T.no_error err
  if Buffer.isBuffer(body) then body = body.toString 'utf8'
  T.equal body, opts.headers['content-type'], "got the right content-type back"
  cb()

#=======================================================================

exports.send_json = (T,cb) -> send_with_encoding T, 'json', cb
exports.send_msgpack = (T,cb) -> send_with_encoding T, 'msgpack', cb
exports.send_msgpack_64 = (T,cb) -> send_with_encoding T, 'msgpack-64', cb

#=======================================================================

exports.send_error = (T,cb) ->
  opts =
    url : make_url "/whoops.json"
    arg :
      encoding : "bah"
      data : make_obj()
    method : "POST"
  await request opts, defer err, res, body
  T.assert err?, "error happened"
  cb()

#=======================================================================

exports.destroy = (T,cb) ->
  await server.close defer()
  cb null

#=======================================================================

