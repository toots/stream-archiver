.PHONY: all install-deps clean

# Config
PACKAGES := ctypes ctypes-foreign lwt cohttp smtp # dropbox
SUBDIRS := src
OCAMLFIND := ocamlfind
OCAMLOPT := $(OCAMLFIND) ocamlopt
OCAMLDEP := $(OCAMLFIND) ocamldep
OCAMLFLAGS := -g -thread -package ctypes -package ctypes.foreign -package lwt -package duppy -package cohttp -package smtp -package dropbox.lwt $(SUBDIRS:%=-I %)
x := cmx
i := cmi
V := @

SOURCES := src/config.mli src/config.ml \
           src/semaphore.mli src/semaphore.ml \
           src/dropbox_uploader.mli src/dropbox_uploader.ml \
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
