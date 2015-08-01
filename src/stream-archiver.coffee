CronJob     = require("cron").CronJob
dateFormat  = require "dateformat"
Dropbox     = require "dropbox"
path        = require "path"
fs          = require "fs"
nodemailer  = require "nodemailer"
Uploader    = require "./uploader"

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

getDropboxClient = (cb) ->
  client = new Dropbox.Client
    key:     config.dropbox.key
    secret:  config.dropbox.secret
    sandbox: false
    token:   config.dropbox.token

  client.authenticate (err, client) ->
    return cb err if err?

    cb null, client

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

  uploader = null

  onStart = ->
    console.log "Starting recording #{show.name}"

    getDropboxClient (err, client) ->
      if err?
        console.log "Error while getting dropbox client:"
        return console.dir err

      uploader = new Uploader client, show

      uploader.on "uploading", (path) ->
        console.log "Started uploading #{path}"

      uploader.on "failed", (path) ->
        console.log "Error while archiving #{path}, retrying.."

      uploader.on "uploaded", (path) ->
        console.log "Finished uploading #{path}"

      uploader.on "error", (error) ->
        console.log "uploader error:"
        console.dir error

      uploader.start()

  onStop = ->
    return unless uploader?

    console.log "Done recording #{show.name}"

    uploader.on "uploaded", ->
      uploader.getUrl (err, url) ->
        if err?
          console.log "Error while getting dropbox url:"
          return console.dir err

        console.log "Sending email for #{show.name}"
        sendEmail show, url, (err) ->
          console.dir err if err?

    uploader.stop()

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
