BufferedStream = require "./buffered-stream"
dateFormat     = require "dateformat"
DropboxStream  = require "./dropbox-stream"
{EventEmitter} = require "events"
request        = require "request"

class module.exports extends EventEmitter
  constructor: (@client, @show) ->
    @index = 0
    @path  = "#{@show.name}/#{dateFormat "mm-dd-yyyy"}"

  getUrl: (cb) ->
    @client.makeUrl @path, {}, (err, res) ->
      return cb err if err?

      cb null, res.url

  start: ->
     suffix = if @index == 0 then "" else "-#{@index}"
     path = "#{@path}/archive#{suffix}.#{@show.format}"

     request        = request.get @show.url 
     bufferedStream = new BufferedStream (100 * 1024) # 100 ko
     dropboxStream  = new DropboxStream @client, path
     
     request.pipe bufferedStream
     bufferedStream.pipe dropboxStream

     dropboxStream.on "uploaded", =>
       @emit "uploaded", path

     dropboxStream.on "error", (@error) =>
       @emit "error", @error

     request.on "error", (@error) =>
       @emit "error", @error

     request.on "end", =>
        return unless @request == request

        @emit "failed", path
        @stop()
        @start()

     @request = request
     @emit "uploading", path 

  stop: ->
    @request.abort()
    @request = null
    @index++
