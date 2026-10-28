PY := uv run python
R  := Rscript

report.html: report.qmd data/clean.csv figs/scores.png figs/counts.png
	quarto render report.qmd

figs/scores.png: plot_scores.py data/clean.csv
	mkdir -p figs
	$(PY) plot_scores.py

figs/counts.png: plot_counts.py data/clean.csv
	mkdir -p figs
	$(PY) plot_counts.py

data/clean.csv: clean_data.R data/raw.csv
	mkdir -p data
	$(R) clean_data.R

data/raw.csv: get_data.py
	mkdir -p data
	$(PY) get_data.py

clean:
	rm -f data/raw.csv data/clean.csv figs/scores.png figs/counts.png report.html

.PHONY: all clean
