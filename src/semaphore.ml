open Ctypes
open Foreign

type t = unit ptr
let s : t typ = ptr void

let o_creat = 100

let sem_open =
  foreign "sem_open" ~check_errno:true
     (string @-> int @-> int @-> int @-> (returning s)) 

let grab name =
  try
    sem_open name o_creat 0o660 0 
  with Unix.Unix_error(Unix.ENOENT, "sem_open", "") ->
     sem_open name o_creat 0o660 0

let wait =
  foreign "sem_wait" ~check_errno:true
    (s @-> (returning void))

let post =
  foreign "sem_post" ~check_errno:true
    (s @-> (returning void))

let close =
  foreign "sem_close" ~check_errno:true
    (s @-> (returning void))
