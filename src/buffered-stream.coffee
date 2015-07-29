{Transform} = require "stream"

class module.exports extends Transform
  constructor: (opts = {}) ->
    @_chunks  = []
    @_curSize = 0
    @size     = opts.size

    super opts

  _flush: (cb) ->
    @push Buffer.concat(@_chunks)

    @_chunks  = []
    @_curSize = 0

    cb()

  _transform: (chunk, encoding, cb) ->
    @_chunks.push chunk
    @_curSize += chunk.length

    return cb() unless @size <= @_curSize

    @_flush cb
