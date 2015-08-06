open Config

let () =
  Nettls_gnutls.init ()

let create_message subject body =
  Netsendmail.compose ~from_addr:("Romain Beauxis", "romain.beauxis@gmail.com")
    ~to_addrs:[("Romain Beauxis", "romain.beauxis@gmail.com")] ~subject:subject "blabla"

let send_mail show url =
  let now =
    ODate.Unix.now ()
  in
  let formatted_date =
    match ODate.Unix.To.generate_printer "%B %E, %Y" with
      | None -> assert false
      | Some printer -> ODate.Unix.To.string printer now
  in

  let subject = 
    Printf.sprintf "%s for %s" show.name formatted_date
  in
  let body = Printf.sprintf
    "Hi!\n\
    \n\
    You can download the archive of %s for %s by clicking on this link:\n\
    %s\n\
    \n\
    Cheers,\n\
    Romi" show.name formatted_date url
  in
  let from_addr = ("Romain Beauxis", "romain.beauxis@gmail.com") in
  let to_addrs = show.emails in

  let email =
    Netsendmail.compose ~from_addr ~to_addrs ~subject body 
  in

  let addr =
    `Socket(`Sock_inet_byname(Unix.SOCK_STREAM, "smtp.gmail.com", 587),
            Uq_client.default_connect_options) in
  let client =
    new Netsmtp.connect addr 60.0
  in
  let tls_config =
    Netsys_tls.create_x509_config
       ~peer_auth:`None
       (Netsys_crypto.current_tls())
  in
  Netsmtp.authenticate
    ~host:"local.host.name"
    ~sasl_mechs:[ (module Netmech_plain_sasl.PLAIN) ]
    ~user:config.gmail_user
    ~creds:[ "password", config.gmail_password, [] ]
    ~tls_required:true
    ~tls_config
    client;
  Netsmtp.sendmail client email
