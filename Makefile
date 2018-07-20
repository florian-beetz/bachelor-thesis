NAME = thesis

FILES = $(NAME).yml $(NAME).md
TEMPLATE = template
FILTERS = -F "filters/pandoc-svg.py" -F pandoc-crossref -F pandoc-citeproc

all: $(NAME).pdf $(NAME).html

$(NAME).pdf: $(NAME).tex
	latexmk -interaction=nonstopmode -pdf $(NAME).tex

$(NAME).html: $(FILES) $(TEMPLATE).html5
	pandoc -o $@ --self-contained --highlight-style tango --template $(TEMPLATE).html5 --csl=lncs.csl $(FILTERS) $(FILES)

$(NAME).tex: $(FILES) $(TEMPLATE).tex
	pandoc -o $@ --biblatex --template $(TEMPLATE).tex $(FILTERS) $(FILES)

$(NAME)-eis.tex: $(FILES) eisvogel.latex
	pandoc -o $@ --biblatex --template eisvogel.latex $(FILTERS) eisvogel.yml $(FILES)

$(NAME)-eis.pdf: $(NAME)-eis.tex
	latexmk -interaction=nonstopmode -pdf $(NAME)-eis.tex

graphics:
	@for svg in `find images/*.svg`;	\
	do									\
		inkscape --export-pdf=$${svg%%.*}.pdf $$svg; \
		inkscape --export-png=$${svg%%.*}.png $$svg; \
	done;

clean:
	rm -f *.pdf 
	rm -f *.html
	latexmk -c *.tex
	rm -f $(NAME).tex
	rm -f $(NAME)-eis.tex
