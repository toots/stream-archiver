open Lwt

let rec sleep t =
  let cur = Unix.gettimeofday () in
  try
    ignore(Unix.select [] [] [] t)
  with Unix.Unix_error (Unix.EINTR,_,_) ->
    let ncur = Unix.gettimeofday () in
    sleep (t -. (ncur -. cur))

let () =
  match Unix.fork () with
    | 0 ->
        let th = Thread.create (fun () ->
          sleep 2.;
          Printf.printf "Master here. Posting on semaphore..\n%!";
          let s = Semaphore.grab "/stream-archiver-12345" in
          Semaphore.post s) ()
        in
        Thread.join th
    | _ ->
        let waiter, starter = Lwt.wait () in
        let run () =
          Lwt_main.run (waiter >>= fun () ->
            Printf.printf "Executing task..\n%!";
            let uri =
              Uri.of_string "http://129.81.156.83:8000/listen"
            in
            Cohttp_lwt_unix.Client.get uri >>= fun (_, body) ->
              let stream = Cohttp_lwt_body.to_stream body in 
              Lwt_stream.iter (fun s ->
                Printf.printf "Got body string of size: %d\n%!" (String.length s)) 
                stream);
          Printf.printf "Done reading!\n%!"
        in
        let th =
          Thread.create run ()
        in
        Printf.printf "Slave here. Waiting on semaphore..\n%!";
        let s = Semaphore.grab "/stream-archiver-12345" in
        Semaphore.wait s;
        Printf.printf "Starting task..\n%!";
        Lwt.wakeup starter ();
        Printf.printf "Sleeping for 4 sec..\n%!";
        sleep 4.;
        Printf.printf "Canceling task..\n%!";
        Thread.join th
