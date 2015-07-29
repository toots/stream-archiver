{exec} = require "child_process"
path   = require "path"

task "build", "Compile coffee scripts into plain Javascript files", ->
  onError = (err, stdout, stderr) ->
    console.error "Error :"
    console.dir   err
    console.log stdout
    console.error stderr

  exec "coffee -c -o build src/*.coffee", (err, stdout, stderr) ->
    return onError err, stdout, stderr if err?

    exec "sed -e 's$@@APP_DIR@@$#{path.join __dirname, "build"}$' < init/stream-archiver.in > build/stream-archiver", (err, stdout, stderr) ->
      return onError err, stdout, stderr if err?    

      console.log "Done!"
