NAME = thesis

FILES = $(NAME).yml $(NAME).md
FILTERS = -F "filters/abbrevs.py" -F "filters/pandoc-svg.py" -F pandoc-crossref -F pandoc-citeproc

all: $(NAME).pdf

$(NAME).pdf: $(NAME).tex
	latexmk -interaction=nonstopmode -pdf $(NAME).tex

$(NAME).tex: $(FILES)
	pandoc -o $@ --biblatex --template template.latex $(FILTERS) $(FILES)

graphics:
	@for svg in `find images/*.svg`;	\
	do									\
		inkscape --export-pdf=$${svg%%.*}.pdf $$svg; \
		inkscape --export-png=$${svg%%.*}.png $$svg; \
	done;

clean:
	rm -f *.pdf 
	latexmk -c *.tex
	rm -f $(NAME).tex
