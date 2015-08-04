module D = Dropbox_lwt_unix

val stream_upload : D.t -> string -> string Lwt_stream.t -> D.metadata Lwt.t  
