(lang dune 3.7)
(version 0.2.0)
(generate_opam_files true)
(executables_implicit_empty_intf true)

(package
  (name stream-archiver)
  (depends
    tls-lwt
    ez_subst
    cohttp
    dropbox_lwt_unix
    odate
    conf-gnutls
    ocamlnet))
