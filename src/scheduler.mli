type t

type task = {
  id   : int;
  run  : unit -> unit;
  stop : unit -> unit
}

type start = unit -> unit

val create : unit -> t

val add : t -> task -> start

val run : t -> unit
