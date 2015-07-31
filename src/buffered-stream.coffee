{Transform} = require "stream"

class module.exports extends Transform
  constructor: (@size) ->
    @chunks = []
    @length = 0

    super decodeStrings: true

  _flushOne: ->
    return unless @size <= @length

    tmp = []
    len = 0

    while tmp < @size
      buf = @chunks.shift()
      tmp.push buf
      len += buf.length

    buf = Buffer.concat tmp

    @push buf.slice 0, @size
    @chunks.unshift buf.slice(@size)
    @length -= @size

  _flush: (cb) ->
    tmp = []
    len = 0

    while @size < @length
      @_flushOne()

    @push Buffer.concat(@chunks)

    @chunks = []
    @length = 0

    cb()

  _transform: (chunk, encoding, cb) ->
    @chunks.push chunk
    @length += chunk.length

    while @size < @length
      @_flushOne()

    cb()
