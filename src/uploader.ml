module D = Dropbox_lwt_unix

open Config
open Lwt

type t = {
  mutable thread : unit Lwt.t option;
  mutable index : int;
  mutex : Lwt_mutex.t;
  uri : Uri.t;
  config : config;
  format : string;
  path : string;
  client : D.t
}

let create config show =
  let now =
    ODate.Unix.now ()
  in
  let formatted_date =
    match ODate.Unix.To.generate_printer "%m-%d-%Y" with
      | None -> assert false
      | Some printer -> ODate.Unix.To.string printer now
  in

  let client = D.session config.dropbox_token in
  let uri = Uri.of_string show.url in
  let path =
    Printf.sprintf "%s/%s" show.name formatted_date
  in
  let format = show.format in
  let mutex = Lwt_mutex.create () in
  let thread = None in
  {thread; index = 0; config; mutex; uri; format; path; client}

let stream_upload config client path bs =
  let ofs = ref 0 in
  let upload_chunk id chunk () =
    let offset = !ofs in
    D.upload_session_append client ~offset id (`String chunk) >>= fun () ->
      ofs := !ofs+(String.length chunk);
      return_unit
  in
  let on_done id canceled =
    let flush =
      if canceled then
       begin
        let rem = bs.Buffered_stream.cancel () in
        let tail =
          Lwt_stream.get_available bs.Buffered_stream.stream
        in
        let to_send =
          match rem with
            | Some chunk -> tail @ [chunk]
            | None -> tail
        in
        Lwt_stream.iter_s (fun chunk -> upload_chunk id chunk ())
          (Lwt_stream.of_list to_send)
       end
     else return_unit
    in
    config.log
      (Printf.sprintf "Finishing upload of %s\n" path);
    flush >>= fun () ->
      let offset = !ofs in
      D.finish_upload_session client ~offset ~path id >>= fun _ ->
        return canceled
  in
  D.start_upload_session client >>= fun session_id ->
    let upload_thread () =
      Lwt_stream.fold_s (upload_chunk session_id) bs.Buffered_stream.stream () >>= fun () ->
      on_done session_id false
    in
    catch upload_thread (function
      | Canceled -> on_done session_id true
      | exn -> fail exn)

let start t =
  (* Expectation: t.mutex is locked. *)
  let rec run () =
    let suffix = if t.index = 0 then "" else
      Printf.sprintf "-%d" t.index
    in
    let path =
      Printf.sprintf "%s/archive%s.%s" t.path suffix t.format
    in
    t.config.log
      (Printf.sprintf "Uploading %s\n" path);
    let headers =
      Cohttp.Header.init_with "User-Agent" Cohttp.Header.user_agent
    in
    let th = Cohttp_lwt_unix.Client.get ~headers t.uri >>= fun (_, body) ->
      let stream =
        Buffered_stream.create (200 * 1024)
          (Cohttp_lwt_body.to_stream body)
      in
      stream_upload t.config t.client path stream >>= fun canceled ->
        if canceled then
         begin
          t.config.log
            (Printf.sprintf "Done uploading %s\n" path);
          return_unit
         end
        else
          Lwt_mutex.lock t.mutex >>= fun () ->
            t.index <- t.index + 1;
            t.config.log
              (Printf.sprintf "%s upload interrupted..\n" path);
            run ()
    in
    t.thread <- Some th;
    Lwt_mutex.unlock t.mutex;
    th
  in
  Lwt_mutex.lock t.mutex >>= run

let stop t =
  Lwt_mutex.lock t.mutex >>= fun () ->
   begin
    match t.thread with
      | Some th -> cancel th
      | None -> ()
   end;
   Lwt_mutex.unlock t.mutex;
   return_unit

let url t =
  D.shares t.client t.path >>= function
    | Some {D.url} -> return url
    | None -> fail (Failure "failed to get dropbox url..")
