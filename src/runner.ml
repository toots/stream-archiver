open Config
open Lwt

let exec config show =
  let uploader = Uploader.create config show in

  let encoding_thread = return_unit >>= fun () ->
      config.log "Starting upload..\n";
      Uploader.start uploader >>= fun () ->
      Uploader.url uploader >>= fun url ->
        Sendmail.send_mail config show url;
        return_unit
  in

  let waiting_thread =
    Lwt_unix.sleep ((float show.duration) *. 60.) >>= fun () ->
      config.log "Stopping upload..\n";
      Uploader.stop uploader
  in

  join [encoding_thread; waiting_thread]
