import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
from shiny import App, reactive, render, ui

app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.h4("Data:"),
        ui.input_slider("x", "# of heads", min=0, max=100, value=7),
        ui.input_slider("n", "# of flips", min=0, max=100, value=10),
        ui.h4("Prior:"),
        ui.input_numeric("a", "Prior # of heads", min=0, value=5),
        ui.input_numeric("b", "Prior # of tails", min=0, value=5),
    ),
    title="Beta-Binomial Visualizer",
)


def server(input, output, session):
    ...


app = App(app_ui, server)
