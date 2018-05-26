NAME = thesis

FILES = $(NAME).yml $(NAME).md
TEMPLATE = template.tex

all: clean $(NAME).pdf

$(NAME).pdf: $(NAME).tex
	latexmk -interaction=nonstopmode -pdf $(NAME).tex

$(NAME).html:
	pandoc -o $@ --filter=pandoc-citeproc $(FILES)

$(NAME).tex: $(FILES) $(TEMPLATE)
	pandoc -o $@ --biblatex -M cref=true --template $(TEMPLATE) -F pandoc-crossref -F pandoc-citeproc $(FILES)


clean:
	rm -f *.pdf 
	latexmk -c *.tex
	rm -f $(NAME).tex
