type t = unit Duppy.scheduler

type task = {
  id   : int;
  run  : unit -> unit;
  stop : unit -> unit
}

let create = Duppy.create

let add scheduler task =

