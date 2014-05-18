
base = require 'request'
{make_esc} = require 'iced-error'
{athrow} = require('iced-utils').util
core = require 'keybase-bjson-core'
{mime_types} = core

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
    [err, ct, inbody] = core.to_content_type_and_body { encoding: opts?.arg.encoding, obj }
    await athrow err, esc defer() if err?
    opts.encoding = null
    opts.headers or= {}
    opts.headers['content-type'] = ct
    opts.headers['accept'] = core.accept.join(', ')
    opts.body = inbody

  await base opts, esc defer resp, body

  if not (ct = resp.headers['content-type']?.split("; "))? then # noop
  else [err,body] = core.from_content_type_and_body { content_type : ct[0], body }

  cb err, resp, body

#===================================================================================================

