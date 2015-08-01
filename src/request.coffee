url        = require "url"
{Readable} = require "stream"

class module.exports extends Readable
  constructor: (@url) ->
    {protocol} = url.parse @url

    @request = require(protocol.slice(0, -1)).get @url, (@response) =>
      @response.on "data", (chunk) =>
        @response.pause() unless @push(chunk)

      @response.on "error", =>
        @emit "error"

      @response.on "end", =>
        @push null    

    @request.on "error", (err) =>
      @emit "error"

    super 

  abort: ->
    @request.abort()

  _read: ->
    @response?.resume()
