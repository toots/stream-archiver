open Lwt

let () =
  let waiter, starter = Lwt.wait () in
  let uploader = Uploader.create Config.config "test" in 
  let encoding_thread = waiter >>= fun () ->
    Printf.printf "Executing task..\n%!";
    Uploader.start uploader
  in
  let waiting_thread =
    Printf.printf "Sleeping for 4 sec..\n%!";
    Lwt_unix.sleep 4. >>= fun () ->
      Printf.printf "Starting task..\n%!";
      Lwt.wakeup starter ();
      Printf.printf "Sleeping for 4 sec..\n%!";
      Lwt_unix.sleep 4. >>= fun () ->
        Printf.printf "Canceling task..\n%!";
        Uploader.stop uploader >>= Lwt.return
  in
  let main_thread = Lwt.join [encoding_thread; waiting_thread] in
  Lwt_main.run main_thread
