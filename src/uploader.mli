type t

val create : Config.t -> string -> t

val start : t -> unit Lwt.t

val stop : t -> unit Lwt.t
