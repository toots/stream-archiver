type t

val create : Config.config -> Config.show -> t

val start : t -> unit Lwt.t

val stop : t -> unit Lwt.t

val url : t -> string Lwt.t
