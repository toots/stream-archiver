open Config
open Lwt

let () =
  if Array.length Sys.argv <> 2 then
   begin
    Printf.printf "Usage: stream-archiver <id>\n";
    exit 1
   end;

  let id = Sys.argv.(1) in
  let show = List.find (fun show ->
    show.id = id) config.shows
  in

  Printf.printf "Archving %s..\n%!" show.name;

  let uploader = Uploader.create show in 

  let encoding_thread = return_unit >>= fun () ->
    Printf.printf "Starting upload..\n%!";
    Uploader.start uploader >>= fun () ->
      Uploader.url uploader >>= fun url ->
        Sendmail.send_mail show url;
        return_unit
  in

  let waiting_thread =
    Lwt_unix.sleep ((float show.duration) *. 60.) >>= fun () ->
      Printf.printf "Stopping upload..\n%!";
      Uploader.stop uploader
  in

  let main_thread = join [encoding_thread; waiting_thread] in

  Lwt_main.run main_thread
