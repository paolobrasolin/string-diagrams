SHELL = /usr/bin/bash
PKG = string-diagrams

$(PKG).tar.gz: $(PKG).ins $(PKG).pdf README
	ctanify $^

$(PKG).pdf: $(PKG).dtx $(PKG).sty
	pdflatex $(PKG).dtx
	pdflatex $(PKG).dtx
	makeindex -s gglo.ist -o $(PKG).gls $(PKG).glo
	makeindex -s gind.ist -o $(PKG).ind $(PKG).idx
	pdflatex $(PKG).dtx
	pdflatex $(PKG).dtx

$(PKG).ins $(PKG).sty README: $(PKG).dtx
	tex $<
	mv README.tex README

watch:
	ls $(PKG).dtx | entr -c make $(PKG).pdf

clean:
	rm -f $(PKG).{aux,glo,gls,hd,idx,ilg,ind,log,out}
	
clobber: clean
	rm -f $(PKG).{ins,pdf,sty,tar.gz}
