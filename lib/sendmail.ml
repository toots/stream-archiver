open Config
open Ez_subst.V2

let () = Nettls_gnutls.init ()

let send_mail config show url =
  let subject =
    EZ_SUBST.string
      ~brace:(fun () -> function "show" -> show.name | x -> "${" ^ x ^ "}")
      ~ctxt:() config.subject
  in
  let body =
    EZ_SUBST.string
      ~brace:
        (fun () -> function
          | "show" -> show.name
          | "url" -> url
          | x -> "${" ^ x ^ "}")
      ~ctxt:() config.body
  in
  let from_addr = (config.from.name, config.from.email) in
  let to_addrs = List.map (fun { name; email } -> (name, email)) show.send_to in

  let email = Netsendmail.compose ~from_addr ~to_addrs ~subject body in

  let addr =
    `Socket
      ( `Sock_inet_byname (Unix.SOCK_STREAM, config.smtp.host, config.smtp.port),
        Uq_client.default_connect_options )
  in
  let client = new Netsmtp.connect addr 60.0 in
  let tls_config =
    Netsys_tls.create_x509_config ~peer_auth:`None
      (Netsys_crypto.current_tls ())
  in
  Netsmtp.authenticate ~host:"local.host.name"
    ~sasl_mechs:[(module Netmech_plain_sasl.PLAIN)]
    ~user:config.smtp.user
    ~creds:[("password", config.smtp.password, [])]
    ~tls_required:true ~tls_config client;
  Netsmtp.sendmail client email
