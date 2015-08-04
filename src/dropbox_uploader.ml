module D = Dropbox_lwt_unix

open Lwt

let stream_upload t path stream =
  let chunked_upload_id = ref None in
  let upload_chunk chunk () =
    let id, ofs =
      match !chunked_upload_id with
        | None -> None, None
        | Some {D.id; ofs} -> (Some id), (Some ofs)
    in
    D.chunked_upload t ?id ?ofs (`String chunk) >>= fun (chunked_upload) ->
      chunked_upload_id := Some chunked_upload;
      Lwt.return ()
  in
  Lwt_stream.fold_s upload_chunk stream () >>= fun () ->
    match !chunked_upload_id with
      | None -> Lwt.fail Lwt_stream.Empty
      | Some {D.id} ->
          D.commit_chunked_upload t id path
