open Config
open Lwt

let ( let* ) = ( >>= )

let exec config show =
  let uploader = Uploader.create config show in

  let encoding_thread =
    Printf.printf "Starting upload..\n%!";
    let* () = Uploader.start uploader in
    let* url = Uploader.url uploader in
    Sendmail.send_mail config show url;
    return ()
  in

  let waiting_thread =
    let* () = Lwt_unix.sleep (float show.duration *. 60.) in
    Printf.printf "Stopping upload..\n%!";
    Uploader.stop uploader
  in

  join [encoding_thread; waiting_thread]
