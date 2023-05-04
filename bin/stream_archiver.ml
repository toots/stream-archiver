open Stream_archiver
open Config

let read filename =
  let ch = open_in_bin filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

let () =
  if Array.length Sys.argv <> 3 then begin
    Printf.printf "Usage: stream-archiver <config> <id>\n";
    exit 1
  end;

  let config = Config.parse (read Sys.argv.(1)) in

  let id = Sys.argv.(2) in
  let show = List.find (fun show -> show.id = id) config.shows in

  Printf.printf "Archiving %s..\n%!" show.name;

  let main_thread = Stream_archiver.Runner.exec config show in

  Lwt_main.run main_thread
