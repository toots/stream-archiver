.PHONY: all install-deps clean

# Config
PACKAGES := conf-gnutls ocamlnet lwt cohttp odate # dropbox
SUBDIRS := src
OCAMLFIND := ocamlfind
OCAMLOPT := $(OCAMLFIND) ocamlopt
OCAMLDEP := $(OCAMLFIND) ocamldep
OCAMLFLAGS := -g -package cohttp,dropbox.lwt,odate,netstring,netclient,nettls-gnutls $(SUBDIRS:%=-I %)
x := cmx
i := cmi
V := @

SOURCES := src/config.mli src/config.ml \
           src/buffered_stream.mli src/buffered_stream.ml \
           src/uploader.mli src/uploader.ml \
           src/sendmail.mli src/sendmail.ml \
           src/main.ml

all: stream-archiver

install-deps:
	opam install $(PACKAGES)

.depend: $(SOURCES) $(SOURCES)
	$(V)echo OCAMLDEP
	$(V)$(OCAMLDEP) $(SUBDIRS:%=-I %) $(^) > $(@)

%.$(i): %.mli
	$(V)echo OCAMLOPT -c $(<)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -c $(<)

%.$(x): %.ml
	$(V)echo OCAMLOPT -c $(<)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -c $(<)

stream-archiver: $(SOURCES:.ml=.$(x))
	$(V)echo OCAMLOPT -o $(@)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -linkpkg -o $(@) $(^)

clean:
	rm -f .depend stream-archiver
	find . -name '*.o' -exec rm \{\} \;
	find . -name '*.a' -exec rm \{\} \;
	find . -name '*.cm*' -exec rm \{\} \;

-include .depend
