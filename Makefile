# * Tools and Flags

INCLUDES=
OCAMLFLAGS=$(INCLUDES) -custom -w +44-40
OCAMLOPTFLAGS=$(INCLUDES)

OCAMLC=ocamlc $(OCAMLFLAGS)
OCAMLOPT=ocamlopt $(OCAMLOPTFLAGS)
OCAMLDEP=ocamldep $(INCLUDES)
OCAMLDOC=ocamldoc.opt $(INCLUDES) -w +44-40 -ppx ./import

METAQUOT=$(shell ocamlfind query ppx_tools)/ppx_metaquot

DOC=gh-pages/doc

# * Compiling and linking

define build_deps =
$(OCAMLDEP) $(foreach ns,$(NS),-map $(ns)) $< > $@
endef

define occ=
$(OCAMLC) -c $< -ppx ./import
endef

define occ_reify=
$(occ) -ppx ./reify
endef

define link=
$(OCAMLC) -o $@  $^
endef

define occ_ppx=
ocamlc -c -I +compiler-libs -ppx $(METAQUOT) $<
endef

define link_ppx=
ocamlc -o $@ -I +compiler-libs ocamlcommon.cma $^
endef


# * Source files
# NS: list of namespaces (ml)
# NSI: list of namespace interfaces (mli)
# ML: list of modules except namespaces
# MLI: list of module interfaces except namespaces
# MAIN_ML: list of main modules (for testing the library)
# MAIN_MLI: list of main module interfaces

# Namespaces are modules containing module aliases.

# For each source file, its dependencies are generated by
# ocamldep and stored in a file of the same name with
# extension .ml.dep or .mli.dep.

# NOTE: The order ml files matters and should be the same as
# linking order of the corresponding cmos.  All the
# namespaces are linked before the ml files.

NS=generic_util.ml generic_core.ml generic_view.ml generic_fun.ml
NSI=

ML=\
generic_util_fun.ml\
generic_util_app.ml\
generic_util_monoid.ml\
generic_util_functor.ml\
generic_util_applicative.ml\
generic_util_monad.ml\
generic_util_hash.ml\
generic_util_iter.ml\
generic_util_list.ml\
generic_util_misc.ml\
generic_util_exn.ml\
generic_util_obj.ml\
generic_util_obj_inspect.ml\
generic_util_sum.ml\
generic_util_option.ml\
generic_core_ty.ml\
generic_core_product.ml\
generic_core_desc.ml\
generic_core_ty_desc.ml\
generic_core_patterns.ml\
generic_core_extensible.ml\
generic_core_consumer.ml\
generic_core_desc_fun.ml\
generic_core_antiunify.ml\
generic_core_repr.ml\
generic_core_equal.ml\
generic_view_spine.ml\
generic_view_sumprod.ml\
generic_view_conlist.ml\
generic_fun_uniplate.ml\
generic_fun_multiplate.ml\
generic_fun_deepfix.ml\
generic_fun_marshal.ml\
generic_fun_equal.ml\
generic_fun_show.ml\
generic.ml

MLI=\
generic_util_obj.mli\
generic_util_obj_inspect.mli\
generic_util_app.mli\
generic_util_fun.mli\
generic_util_iter.mli\
generic_util_sum.mli\
generic_util_monad.mli\
generic_core_antiunify.mli\
generic_core_extensible.mli\
generic_core_consumer.mli\
generic_core_patterns.mli\
generic_core_product.mli\
generic_core_ty_desc.mli\
generic_core_ty.mli\
generic_core_desc_fun.mli\
generic_core_desc.mli\
generic_core_repr.mli\
generic_core_equal.mli\
generic_view_spine.mli\
generic_view_sumprod.mli\
generic_view_conlist.mli\
generic_fun_marshal.mli\
generic_fun_uniplate.mli\
generic_fun_multiplate.mli\
generic_fun_equal.mli\
generic_fun_show.mli\

# OTHER is the list of independent files from the library (ppx, tests)
OTHER_ML=\
reify.ml\
import.ml\
generic_test_marshal.ml\
generic_test_multiplate.ml\
generic_test_gadt.ml\
generic_test_show\

# interfaces for the independent files
OTHER_MLI=

# * Rules
.PHONY: lib tests doc ppx clean
#.SECONDARY: $(ML:.ml=.cmo) $(OTHER_ML:.ml=.cmo)

all: ppx lib tests doc
doc: $(DOC)/index.html import # doc/dep.dot
ppx: reify import
lib: ppx generic.cma
tests: ppx test_marshal test_show test_multiplate

# Library (bytecode)
generic.cma: generic_util_obj_stub.o $(NS:.ml=.cmo) $(ML:.ml=.cmo)
	$(OCAMLC) -custom -o $@ -a $^

# PPX

reify.cmo: reify.ml
	$(occ_ppx)
reify: generic.cma reify.cmo
	$(link_ppx)

import.cmo: import.ml
	$(occ_ppx)
import: import.cmo
	$(link_ppx)

# some times one wants to dump the source after a ppx expansion and check the results:
tmp.cmo: tmp.ml
	ocamlc -I +compiler-libs -c $<

# NOTE about the rule "$(DOC)/index.html":
# I added the library as a prerequisite
# because ocamldoc complained of ubound modules otherwise.
# Since it is not a source file, we remove it from the command line
# with "$(wordlist 2, $(words $^), $^)".

$(DOC)/index.html: lib $(NS) $(NSI) $(ML) $(MLI)
	mkdir -p $(DOC)
	cp style.css $(DOC)
	$(OCAMLDOC) -html -css-style style.css -t "Generic Programming Library" -intro intro.html -hide Generic_util,Generic_core -d $(DOC) $(wordlist 2, $(words $^), $^)

$(DOC)/dep.dot: lib $(NS) $(NSI) $(ML) $(MLI)
	mkdir -p $(DOC)
	$(OCAMLDOC) -dot -o $(DOC)/dep.dot $(wordlist 2, $(words $^), $^)

%.reify: %.ml ppx
	$(OCAMLC) -o $<.reify.cmo -ppx ./reify -c $< -dsource
%.import: %.ml import
	$(OCAMLC) -o $<.import.cmo -ppx ./import -c $< -dsource

generic_test_multiplate.cmo: generic_test_multiplate.ml ppx
	$(occ_reify)
test_multiplate: generic.cma generic_test_multiplate.cmo
	$(link)

generic_test_marshal.cmo: generic_test_marshal.ml ppx
	$(occ_reify)
test_marshal: generic.cma generic_test_marshal.cmo
	$(link)

generic_test_gadt.cmo: generic_test_gadt.ml ppx
	$(occ_reify)
test_gadt: generic.cma generic_test_gadt.cmo
	$(link)

generic_test_show.cmo: generic_test_show.ml ppx
	$(occ_reify)
test_show: generic.cma generic_test_show.cmo
	$(link)

# ** Build Dependencies
# IMPORTANT: source files names may not include the character ':'
# Using [sed] we add the dependency file itself as a target.
# sed -r 's:^([^:]*):\1$@ :g' > $@
# that's not necessary for ocaml in fact.

%.mli.dep: %.mli
	$(build_deps)

%.ml.dep: %.ml
	$(build_deps)

$(NS:.ml=.ml.dep): %.ml.dep: %.ml
	$(OCAMLDEP) -as-map $< > $@

%.cmo: %.ml import
	$(occ)

%.cmi: %.mli
	$(occ)

# Generate the mli to stdout
# (we don't want to erase the hand written one)
%.mli.auto: %.ml
	$(OCAMLC) -i -I +compiler-libs -ppx $(METAQUOT) -ppx ./import -ppx ./reify $<

# This is a static pattern see info: Make > Static Usage
$(NS:.ml=.cmo): %.cmo: %.ml
	$(OCAMLC) -no-alias-deps -w A-49 -c $<

$(NSI:.mli=.cmi): %.cmi: %.mli
	$(OCAMLC) -no-alias-deps -w A-49 -c $<

# ** C
# Using ocamlc for compiling C automatically deals with the location of ocaml headers
%.o: %.c
	$(occ)

# * Include Dependencies

-include $(ML:.ml=.ml.dep)
-include $(MLI:.mli=.mli.dep)
-include $(NS:.ml=.ml.dep)
-include $(NSI:.mli=.mli.dep)
-include $(OTHER_ML:.ml=.ml.dep)
-include $(OTHER_MLI:.mli=.mli.dep)

# * Clean up

clean:
	rm -f test_marshal reify
	rm -f *.cm[ioxa] *.dep *.o
