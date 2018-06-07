NAME = thesis

FILES = $(NAME).yml $(NAME).md
TEMPLATE = template
FILTERS = -F "filters/pandoc-svg.py" -F pandoc-crossref -F pandoc-citeproc

all: clean $(NAME).pdf $(NAME).html

$(NAME).pdf: $(NAME).tex
	latexmk -interaction=nonstopmode -pdf $(NAME).tex

$(NAME).html: $(FILES) $(TEMPLATE).html5
	pandoc -o $@ --template $(TEMPLATE).html5 --csl=lncs.csl $(FILTERS) $(FILES)

$(NAME).tex: $(FILES) $(TEMPLATE).tex
	pandoc -o $@ --biblatex --template $(TEMPLATE).tex $(FILTERS) $(FILES)

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
