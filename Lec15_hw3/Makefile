hw3.html: hw3.qmd data/dennys.csv data/lq.csv
	uv run quarto render hw3.qmd

data/dennys.csv: parse_dennys.R data/dennys/*.html
	Rscript parse_dennys.R

data/lq.csv: parse_lq.py data/lq/*.html
	uv run python parse_lq.py

data/dennys/*.html: get_dennys.R
	Rscript get_dennys.R
	touch data/dennys/*.html

data/lq/*.html: get_lq.py
	uv run python get_lq.py
	touch data/lq/*.html

clean:
	rm -f hw3.html
	rm -rf data/

.PHONY: clean
