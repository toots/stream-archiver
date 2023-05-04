type t = { stream : string Lwt_stream.t; cancel : unit -> string option }

val create : int -> string Lwt_stream.t -> t
