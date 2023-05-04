type email_address = { name : string; email : string }

type show = {
  id : string;
  name : string;
  send_to : email_address list;
  duration : int; (* in mimutes *)
  url : string;
  format : string;
}

(* Only supports TLS-enabled
 * SMTP servers for now. *)
type smtp_config = {
  host : string;
  port : int;
  user : string;
  password : string;
}

type t = {
  shows : show list;
  dropbox_token : string;
  smtp : smtp_config;
  from : email_address;
  subject : string;
  body : string;
}

val parse : string -> t
