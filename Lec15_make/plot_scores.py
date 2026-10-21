import matplotlib.pyplot as plt
import pandas as pd

games = pd.read_csv("data/clean.csv")
by_year = games.groupby("year")["total"].mean()

fig, ax = plt.subplots(figsize=(7, 4))
by_year.plot(ax=ax, marker="o")
ax.set_xlabel("Season")
ax.set_ylabel("Mean points per game")
ax.set_title("NFL scoring by season")
ax.set_xticks(by_year.index[::2])
fig.tight_layout()
fig.savefig("figs/scores.png", dpi=150)
