BufferedStream = require "./buffered-stream"
CronJob        = require("cron").CronJob
dateFormat     = require "dateformat"
Dropbox        = require "dropbox"
fs             = require "fs"
nodemailer     = require "nodemailer"
request        = require "request"

# { 
#   "dropbox": { "key": "...", "secret": "...", "token": "..." },
#   "gmail": { "user": "..", "password": "..." },
#   "shows": [{
#     "name": "...",
#     "url": "...",
#     "format": "mp3",
#     "email": "foo@bar.com, gni@gno.com",
#     "timeZone": "America/Chicago",
#     "start":  "00 50 19 * * 1",
#     "stop":   "00 10 22 * * 1"
#   }, {
#     ... 
#   }],
# }

config = JSON.parse fs.readFileSync("config.json")

startSaveStream = (path, url, onDone, cb) ->
  client = new Dropbox.Client
    key:     config.dropbox.key
    secret:  config.dropbox.secret
    sandbox: false
    token:   config.dropbox.token

  client.authenticate (err, client) ->
    return cb err if err?

    console.log "Start uploading #{path}"
    req = request.get url

    bufferedStream = new BufferedStream
      size: 100 * 1024 # 100 ko

    req.pipe bufferedStream

    state = null
    bufferedStream.on "data", (chunk) ->
      bufferedStream.pause()

      client.resumableUploadStep chunk, state, (err, newState) ->
        if err?
          client = null
          req.abort()
          return onDone err

        state = newState
        bufferedStream.resume()

    bufferedStream.on "end", ->
      return unless client?

      client.resumableUploadFinish path, state, {}, (err) ->
        return onDone err if err? 

        console.log "Finished uploading #{path}!"

        client.makeUrl path, {}, (err, res) ->
          return onDone err if err?

          onDone null, res.url

    cb null, req

stopSaveStream = (req) ->
  req.abort()

emailTransporter = nodemailer.createTransport
  service: "Gmail"
  auth:
    user: config.gmail.user
    pass: config.gmail.password

sendEmail = (show, url, cb) ->
  dateStr = dateFormat "dddd, mmmm dS, yyyy"

  mailOptions =
    from: config.gmail.user
    to: show.email
    subject: "#{show.name} archive for #{dateStr}"
    text: """
Hi!

You can download the archive of #{show.name} for #{dateStr} by clicking on this link:
#{url}

Cheers,
Romi
          """

  emailTransporter.sendMail mailOptions, cb

archiveShow = (show) ->
  console.log "Registering cron job for #{show.name}"

  req = null

  onStart = ->
    console.log "Starting recording #{show.name}"
    remotePath = "#{show.name}/#{dateFormat "mm-dd-yyyy"}.#{show.format}"

    onDone = (err, url) ->
      return console.dir err if err?

      console.log "Sending email for #{show.name}"
      sendEmail show, url, (err) ->
        console.dir err if err?

    startSaveStream remotePath, show.url, onDone, (err, _req) ->
      return console.dir err if err?

      req = _req

  onStop = ->
    console.log "Done recording #{show.name}"
    req?.abort?()

  new CronJob
    cronTime: show.start
    onTick:   onStart 
    start:    true
    timeZone: show.timeZone

  new CronJob
    cronTime: show.stop
    onTick:   onStop
    start:    true
    timeZone: show.timeZone

archiveShow show for show in config.shows
