SHELL := /usr/bin/env bash
PKG = string-diagrams

VERSION = UNRELEASED
TIMESTAMP = $(shell date +"%s")

INTERPOLATIONS  = s@<DATE>@$(shell date --date @$(TIMESTAMP) +"%Y/%m/%d")@g;
INTERPOLATIONS += s/<VERSION>/$(VERSION)/g;

$(PKG).tar.gz: $(PKG).ins $(PKG).pdf README.md
	ctanify --no-tds $^

# NOTE: this command reproducibly builds the PDF (see https://flyx.org/nix-flakes-latex/ and https://texdoc.org/serve/pdftex-a.pdf/0)
$(PKG).pdf $(PKG).dep: $(PKG).dtx $(PKG).sty
	SOURCE_DATE_EPOCH=$(TIMESTAMP) \
	FORCE_SOURCE_DATE=1 \
	latexmk -pdf -gg \
		-interaction=nonstopmode \
		-usepretex='\pdftrailerid{}\relax' \
		$<

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
