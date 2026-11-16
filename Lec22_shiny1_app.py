from shiny import App, reactive, render, ui
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats


app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.h4("Data:"),
        ui.input_slider("x", "# of heads", min=0, max=100, value=7),
        ui.input_slider("n", "# of flips", min=0, max=100, value=10),
        ui.h4("Prior:"),
        ui.input_numeric("a", "Prior # of heads", min=0, value=5),
        ui.input_numeric("b", "Prior # of tails", min=0, value=5),
        ui.tags.br(),
        ui.input_action_button("go","Go")
    ),
    ui.output_plot("plot"),
    ui.div(
        ui.output_data_frame("table"), 
        class_="d-flex justify-content-center"
    ),
    title="Beta-Binomial Visualizer",
)



def server(input, output, session):
    
    @reactive.effect
    def _():
        ui.update_slider("x", max=input.n())

    @reactive.calc
    @reactive.event(input.go, ignore_none=False)
    def d():
        x, n, a, b = input.x(), input.n(), input.a(), input.b()

        return (
            pd.DataFrame({"p": np.linspace(0, 1, 1001)})
            .assign(
                prior      = lambda df: stats.beta.pdf(df.p, a, b),
                likelihood = lambda df: stats.beta.pdf(df.p, x + 1, n - x + 1),
                posterior  = lambda df: stats.beta.pdf(df.p, a + x, b + n - x),
            )
            .melt(id_vars="p", var_name="distribution", value_name="density")
        )

    @render.plot
    def plot():
        ax = sns.lineplot(d(), x="p", y="density", hue="distribution")
        for line in ax.lines:
            ax.fill_between(*line.get_data(), color=line.get_color(), alpha=0.3)
        return ax

    @render.data_frame
    def table():
        return (
            d()
            .assign(
                cdf=lambda df: df.groupby("distribution")["density"].transform(
                    lambda s: s.cumsum() / s.sum()
                )
            )
            .set_index("p")
            .groupby("distribution", sort=False)
            .agg(
                mean=("density", lambda s: np.average(s.index, weights=s)),
                median=("cdf", lambda s: (s >= 0.5).idxmax()),
                lower=("cdf", lambda s: (s >= 0.025).idxmax()),
                upper=("cdf", lambda s: (s >= 0.975).idxmax()),
            )
            .round(3)
            .reset_index()
        )

app = App(app_ui, server)
