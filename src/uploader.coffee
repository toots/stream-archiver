BufferedStream = require "./buffered-stream"
dateFormat     = require "dateformat"
DropboxStream  = require "./dropbox-stream"
{EventEmitter} = require "events"
MmapStream     = require "mmap-stream"
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
     mmapStream     = new MmapStream (10 * 1024 * 1024) # 10 Mo
     bufferedStream = new BufferedStream (1024 * 1024) # 1 Mo
     dropboxStream  = new DropboxStream @client, path
     
     request.pipe mmapStream
     mmapStream.pipe bufferedStream
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
