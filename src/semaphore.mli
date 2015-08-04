type t

val grab  : string -> t
val wait  : t -> unit
val post  : t -> unit
val close : t -> unit
