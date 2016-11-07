open Archiver_config
open Stream_archiver.Config
open Lwt

let () =
  if Array.length Sys.argv <> 2 then
   begin
    Printf.printf "Usage: stream-archiver <id>\n";
    exit 1
   end;

  let id = Sys.argv.(1) in
  let show = List.find (fun show ->
    show.id = id) shows
  in

  Printf.printf "Archiving %s..\n%!" show.name;

  let main_thread =
    Stream_archiver.Runner.exec config show
  in

  Lwt_main.run main_thread
