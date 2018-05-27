NAME = thesis

FILES = $(NAME).yml $(NAME).md
TEMPLATE = template
FILTERS = -F pandoc-crossref -F pandoc-citeproc

all: clean $(NAME).pdf $(NAME).html

$(NAME).pdf: $(NAME).tex
	latexmk -interaction=nonstopmode -pdf $(NAME).tex

$(NAME).html: $(FILES) $(TEMPLATE).html5
	pandoc -o $@ --template $(TEMPLATE).html5 --csl=lncs.csl $(FILTERS) $(FILES)

$(NAME).tex: $(FILES) $(TEMPLATE).tex
	pandoc -o $@ --biblatex --template $(TEMPLATE).tex $(FILTERS) $(FILES)


clean:
	rm -f *.pdf 
	rm -f *.html
	latexmk -c *.tex
	rm -f $(NAME).tex
