SHELL := /usr/bin/env bash
PKG = string-diagrams

VERSION = UNRELEASED
DATE = $(shell date +"%Y/%m/%d")

INTERPOLATIONS  = s@<DATE>@$(DATE)@g;
INTERPOLATIONS += s/<VERSION>/$(VERSION)/g;

$(PKG).tar.gz: $(PKG).ins $(PKG).pdf README.md
	ctanify --no-tds $^

$(PKG).pdf $(PKG).dep: $(PKG).dtx $(PKG).sty
	latexmk -pdf $<

$(PKG).sty: $(PKG).ins $(PKG).dtx
	tex $<

watch: $(PKG).dtx
	ls $^ | entr -c make $(PKG).pdf

clean:
	latexmk -c $(PKG).pdf

clobber: clean
	rm -f $(PKG).{pdf,sty,tar.gz}

interpolate:
	sed -i "$(INTERPOLATIONS)" $(PKG).ins
	sed -i "$(INTERPOLATIONS)" $(PKG).dtx

.github/texlive.packages: $(PKG).dep
	sh dev/dep_to_pkg.sh $< $@
	# TODO: it's pretty annoying we need to add/remove packages manually...
	sed -i '/^base$$/d' $@
	echo "ctanify tex pdftex latex-bin collection-fontsrecommended" | tr ' ' '\n' >> $@
