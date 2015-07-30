{Writable} = require "stream"

class module.exports extends Writable
  constructor: (@client, @path) ->
    super decodeStrings: true

    @on "finish", =>
      @client.resumableUploadFinish @path, @state, {}, (err) =>
        return @emit "error", err if err?

        @emit "uploaded"

  _write: (chunk, encoding, cb) ->
    @client.resumableUploadStep chunk, @state, (err, @state) =>
      cb err

  _writev: (chunks, cb) ->
    @_write Buffer.concat(el.chunk for el in chunks), cb
