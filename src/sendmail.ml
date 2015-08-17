open Config

let () =
  Nettls_gnutls.init ()

let send_mail config show url =
  let subject = config.smtp.subject show in 
  let body = config.smtp.body show url in
  let from_addr = config.smtp.from in
  let to_addrs = show.emails in

  let email =
    Netsendmail.compose ~from_addr ~to_addrs ~subject body 
  in

  let addr =
    `Socket(`Sock_inet_byname(Unix.SOCK_STREAM, config.smtp.host, config.smtp.port),
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
    ~user:config.smtp.user
    ~creds:[ "password", config.smtp.password, [] ]
    ~tls_required:true
    ~tls_config
    client;
  Netsmtp.sendmail client email
