type t = { stream : string Lwt_stream.t; cancel : unit -> string option }

let create length str =
  let buf = Buffer.create length in
  let fin = ref false in
  let cancel () =
    match (!fin, Buffer.length buf) with
      | true, _ | false, 0 -> None
      | false, _ ->
          fin := true;
          Some (Buffer.contents buf)
  in
  let map chunk =
    Buffer.add_string buf chunk;
    if Buffer.length buf < length then None
    else begin
      let chunk = Buffer.contents buf in
      Buffer.clear buf;
      Some chunk
    end
  in
  let mapped = Lwt_stream.filter_map map str in
  let flush = Lwt_stream.from_direct cancel in
  { stream = Lwt_stream.append mapped flush; cancel }
