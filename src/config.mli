type show = {
  id: string;
  name: string;
  emails: (string * string) list;
  duration: int; (* in mimutes *)
  url: string;
  format: string
}

(* Only supports TLS-enabled
 * SMTP servers for now. *)
type smtp_config = {
  host : string;
  port : int;
  user : string;
  password : string;
  from : string * string;
  subject : show -> string;
  body : show -> string -> string
}

type config = {
  dropbox_token : string;
  smtp : smtp_config;
  log : string -> unit
}
