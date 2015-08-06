let () =
  Nettls_gnutls.init ()

let create_message subject body =
  Netsendmail.compose ~from_addr:("Romain Beauxis", "romain.beauxis@gmail.com")
    ~to_addrs:[("Romain Beauxis", "romain.beauxis@gmail.com")] ~subject:subject "blabla"

let send_mail {Config.gmail_user; gmail_password} _ =
  let subject = "bla" in
  let body = "blo" in
  let email = create_message subject body in

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
    ~user:gmail_user
    ~creds:[ "password", gmail_password, [] ]
    ~tls_required:true
    ~tls_config
    client;
  Netsmtp.sendmail client email
