
base = require 'request'
{make_esc} = require 'iced-error'
{athrow} = require('iced-utils').util
{encode,decode_json_obj,decode} = require 'keybase-bjson-core'

#===================================================================================================

# The `opts` are as in the base request class, with two new options:
#   - opts.arg.data = the argument to the API, as a JSON object w/ buffers
#   - opts.arg.encoding = the encoding, can be either 'json', the default,
#       'msgpack', or 'msgpack-64'
exports.request = request = (opts, cb) ->

  err = null
  decode = false
  esc = make_esc cb, "request"

  if (obj = opts.arg?.data)?
    decode = true
    enc = opts?.arg.encoding or 'json'

    [ct, inbody] = switch enc
      when 'json'       then [ 'application/json',         encode({obj, json : true }) ]
      when 'msgpack'    then [ 'application/x-msgpack',    encode({obj, msgpack : true, encoding : 'binary' })]
      when 'msgpack-64' then [ 'application/x-msgpack-64', encode({obj, msgpack : true, encoding : 'base64' })]
      else                   [ null, null ]

    if not inbody?
      err = new Error("Invalid encoding type: #{enc}")
      await athrow err, esc defer()
    else
      opts.encoding = null
      opts.headers or= {}
      opts.headers['content-type'] = ct
      opts.headers['accept'] = "application/json; application/x-msgpack; application/x-msgpack-64"
    opts.body = inbody

  await base opts, esc defer resp, body

  if not decode then # noop
  else if not (ct = resp.headers['content-type']?.split("; "))? then # noop
  else
    try
      body = switch ct[0]
        when "application/json"         then decode_json_obj body
        when "application/x-msgpack"    then decode { buf : body, msgpack : true }
        when "application/x-msgpack-64" then decode { buf : body, msgpack : true, encoding : 'base64' }
        else null
    catch e
      err = new Error "Error decoding output: #{e.message}"

  cb err, resp, body

#===================================================================================================

