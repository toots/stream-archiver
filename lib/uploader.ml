module D = Dropbox_lwt_unix
open Config
open Lwt

let ( let* ) = ( >>= )

type t = {
  thread : unit Lwt.t option Atomic.t;
  mutex : Lwt_mutex.t;
  uri : Uri.t;
  format : string;
  path : string;
  client : D.t;
}

let create config show =
  let now = ODate.Unix.now () in
  let formatted_date =
    match ODate.Unix.To.generate_printer "%m-%d-%Y" with
      | None -> assert false
      | Some printer -> ODate.Unix.To.string printer now
  in

  let client = D.session config.dropbox_token in
  let uri = Uri.of_string show.url in
  let path = Printf.sprintf "/%s/%s" show.name formatted_date in
  let format = show.format in
  let mutex = Lwt_mutex.create () in
  let thread = Atomic.make None in
  { thread; mutex; uri; format; path; client }

let stream_upload client path bs =
  let upload_chunk chunk (ofs, id) =
    let* { D.ofs; id; _ } = D.chunked_upload ?ofs ?id client (`String chunk) in
    return (Some ofs, Some id)
  in
  let on_done = function
    | _, None -> return ()
    | _, Some id ->
        Printf.printf "Finishing upload of %s\n%!" path;
        let* _ = D.commit_chunked_upload client id path in
        return ()
  in
  let upload_thread () =
    let* cursor =
      Lwt_stream.fold_s upload_chunk bs.Buffered_stream.stream (None, None)
    in
    on_done cursor
  in
  catch upload_thread (function Canceled -> return () | exn -> fail exn)

let start t =
  let* () = Lwt_mutex.lock t.mutex in
  let path = Printf.sprintf "%s/archive.%s" t.path t.format in
  Printf.printf "Uploading %s\n%!" path;
  let headers = Cohttp.Header.init_with "User-Agent" Cohttp.Header.user_agent in
  let th =
    let* _, body = Cohttp_lwt_unix.Client.get ~headers t.uri in
    let stream =
      Buffered_stream.create (200 * 1024) (Cohttp_lwt.Body.to_stream body)
    in
    stream_upload t.client path stream
  in
  Atomic.set t.thread (Some th);
  Lwt_mutex.unlock t.mutex;
  th

let stop t =
  let* () = Lwt_mutex.lock t.mutex in
  ignore (Option.map cancel (Atomic.get t.thread));
  Lwt_mutex.unlock t.mutex;
  return ()

let url t =
  let* (res : D.shared_link option) =
    D.shares t.client ~short_url:true t.path
  in
  return (Option.get res).D.url
