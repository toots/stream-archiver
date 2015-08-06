module D = Dropbox_lwt_unix

open Config
open Lwt

type t = {
  mutable thread : unit Lwt.t option;
  mutable index : int;
  mutex : Lwt_mutex.t;
  uri : Uri.t;
  format : string;
  path : string;
  client : D.t
}

let create show =
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
  {thread; index = 0; mutex; uri; format; path; client}

let stream_upload client path bs =
  let chunked_upload_id = ref None in
  let upload_chunk chunk () =
    let id, ofs =
      match !chunked_upload_id with
        | None -> None, None
        | Some {D.id; ofs} -> (Some id), (Some ofs)
    in
    D.chunked_upload client ?id ?ofs (`String chunk) >>= fun (chunked_upload) ->
      chunked_upload_id := Some chunked_upload;
      return_unit
  in
  let on_done canceled =
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
        Lwt_stream.iter_s (fun chunk -> upload_chunk chunk ())
          (Lwt_stream.of_list to_send)
       end
     else return_unit
    in
    Printf.printf "Finishing upload of %s\n%!" path;
    flush >>= fun () ->
      match !chunked_upload_id with
        | None -> fail Lwt_stream.Empty
        | Some {D.id} ->
            D.commit_chunked_upload client id path >>= fun _ ->
              return canceled
  in
  let upload_thread () =
    Lwt_stream.fold_s upload_chunk bs.Buffered_stream.stream () >>= fun () ->
      on_done false
  in
  catch upload_thread (function
    | Canceled -> on_done true
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
    Printf.printf "Uploading %s\n%!" path;
    let th = Cohttp_lwt_unix.Client.get t.uri >>= fun (_, body) ->
      let stream =
        Buffered_stream.create (200 * 1024)
          (Cohttp_lwt_body.to_stream body)
      in
      stream_upload t.client path stream >>= fun canceled ->
        if canceled then
         begin
          Printf.printf "Done uploading %s\n%!" path;
          return_unit
         end
        else
          Lwt_mutex.lock t.mutex >>= fun () ->
            t.index <- t.index + 1;
            Printf.printf "%s upload interrupted..\n%!" path;
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
