BufferedStream = require "./buffered-stream"
CronJob        = require("cron").CronJob
dateFormat     = require "dateformat"
Dropbox        = require "dropbox"
DropboxStream  = require "./dropbox-stream"
path           = require "path"
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

config = JSON.parse fs.readFileSync(path.join(__dirname, "..", "config.json"))

startSaveStream = (show, cb) ->
  client = new Dropbox.Client
    key:     config.dropbox.key
    secret:  config.dropbox.secret
    sandbox: false
    token:   config.dropbox.token

  client.authenticate (err, client) ->
    return cb err if err?

    req    = null
    done   = false
    error  = null

    basePath = "#{show.name}/#{dateFormat "mm-dd-yyyy"}"

    onDone = (cb) ->
      return cb error if error?

      req?.abort?()
      done = true

      client.makeUrl basePath, {}, (err, res) ->
        return cb err if err?

        cb null, res.url

    upload = (index) ->
      suffix = if index == 0 then "" else "-#{index}"
      path = "#{basePath}/archive#{suffix}.#{show.format}"

      console.log "Start uploading #{path}"

      req            = request.get show.url
      bufferedStream = new BufferedStream (100 * 1024) # 100 ko
      dropboxStream  = new DropboxStream client, path

      req.pipe bufferedStream
      bufferedStream.pipe dropboxStream

      dropboxStream.on "error", (err) ->
        error = err

      dropboxStream.on "uploaded", ->
        return if error?

        console.log "Finished uploading #{path}"

        return upload (index+1) unless done

    upload 0

    cb null, onDone

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

  onDone = null

  onStart = ->
    console.log "Starting recording #{show.name}"

    startSaveStream show, (err, _onDone) ->
      return console.dir err if err?

      onDone = _onDone

  onStop = ->
    console.log "Done recording #{show.name}"

    onDone? (err, url) ->
      return console.dir err if err?

      console.log "Sending email for #{show.name}"
      sendEmail show, url, (err) ->
        console.dir err if err?

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
