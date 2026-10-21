import matplotlib.pyplot as plt
import pandas as pd

games = pd.read_csv("data/clean.csv")
by_year = games.groupby("year").size()

fig, ax = plt.subplots(figsize=(7, 4))
by_year.plot(ax=ax, kind="bar")
ax.set_xlabel("Season")
ax.set_ylabel("Number of games (excluding ties)")
ax.set_title("NFL games by season")
fig.tight_layout()
fig.savefig("figs/counts.png", dpi=150)
