library(tidyverse)

read_csv("data/raw.csv", show_col_types = FALSE) |>
  filter(is.na(tie)) |>
  mutate(
    loser = if_else(winner == home_team, away_team, home_team),
    total = pts_win + pts_loss,
    margin = pts_win - pts_loss
  ) |>
  select(year, week, winner, loser, pts_win, pts_loss, total, margin) |>
  write_csv("data/clean.csv")
