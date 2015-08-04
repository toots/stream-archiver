open Ctypes
open Foreign

type t = unit ptr
let s : t typ = ptr void

let o_creat = 0x0200

let sem_open =
  foreign "sem_open" ~check_errno:true
     (string @-> int @-> (returning s)) 

let grab name =
  sem_open name o_creat

let wait =
  foreign "sem_wait" ~check_errno:true
    (s @-> (returning void))

let post =
  foreign "sem_post" ~check_errno:true
    (s @-> (returning void))

let close =
  foreign "sem_close" ~check_errno:true
    (s @-> (returning void))
