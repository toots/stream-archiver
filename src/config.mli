type show = {
  id: string;
  name: string;
  emails: (string * string) list;
  duration: int; (* in mimutes *)
  url: string;
  format: string
}

type t = {
  dropbox_token : string;
  gmail_user : string;
  gmail_password : string;
  shows: show list
}

val config : t
