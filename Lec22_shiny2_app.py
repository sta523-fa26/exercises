import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats
from faicons import icon_svg
from shiny import App, reactive, render, ui

dist_colors = {"prior": "#dc3545", "likelihood": "#198754", "posterior": "#0d6efd"}

stat_icons = {
    "Mean": "bullseye",
    "Median": "arrows-left-right",
    "95% CI": "arrows-left-right-to-line",
}

app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.accordion(
            ui.accordion_panel(
                "Data",
                ui.input_slider("x", "# of heads", min=0, max=100, value=7),
                ui.input_slider("n", "# of flips", min=0, max=100, value=10),
            ),
            ui.accordion_panel(
                "Prior",
                ui.input_numeric("a", "Prior # of heads", min=0, value=5),
                ui.input_numeric("b", "Prior # of tails", min=0, value=5),
            ),
        ),
        ui.input_action_button("run", "Run"),
    ),
    ui.navset_card_tab(
        ui.nav_panel(
            "Plot", 
            ui.output_plot("plot")
        ),
        ui.nav_panel(
            "Table",
            ui.div(
                ui.output_data_frame("table"),
                class_="d-flex justify-content-center",
            ),
        ),
        title="Distributions",
        full_screen=True,
    ),
    ui.card(
        ui.card_header(
            ui.output_text("summary_title"),
            ui.popover(
                icon_svg("gear"),
                ui.input_select(
                    "summary_dist", "Distribution:", choices=list(dist_colors)
                ),
                title="Settings",
            ),
            class_="d-flex justify-content-between align-items-center",
        ),
        ui.card_body(
            ui.output_ui("value_boxes"),
        ),
    ),
    title="Beta-Binomial Visualizer",
)


def server(input, output, session):
    @reactive.effect
    def _():
        ui.update_slider("x", max=input.n())

    @render.text
    def summary_title():
        return f"Summary Statistics for the {input.summary_dist()}"

    @reactive.calc
    @reactive.event(input.run, ignore_none=False)
    def d():
        x, n, a, b = input.x(), input.n(), input.a(), input.b()

        return (
            pd.DataFrame({"p": np.linspace(0, 1, 1001)})
            .assign(
                prior=lambda df: stats.beta.pdf(df.p, a, b),
                likelihood=lambda df: stats.beta.pdf(df.p, x + 1, n - x + 1),
                posterior=lambda df: stats.beta.pdf(df.p, a + x, b + n - x),
            )
            .melt(id_vars="p", var_name="distribution", value_name="density")
        )

    @render.plot
    def plot():
        ax = sns.lineplot(
            d(), x="p", y="density", hue="distribution", palette=dist_colors
        )
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

    @render.ui
    def value_boxes():
        dist = input.summary_dist()
        df = d()[d()["distribution"] == dist]
        cdf = df["density"].cumsum() / df["density"].sum()
        lo, med, hi = df["p"].iloc[np.searchsorted(cdf, [0.025, 0.5, 0.975])]

        summary = {
            "Mean": f"{np.average(df['p'], weights=df['density']):.3f}",
            "Median": f"{med:.3f}",
            "95% CI": f"{lo:.3f} - {hi:.3f}",
        }

        boxes = [
            ui.value_box(
                stat,
                value,
                showcase=icon_svg(stat_icons[stat]),
                showcase_layout="top right",
                theme=ui.value_box_theme(bg=dist_colors[dist], fg="white"),
            )
            for stat, value in summary.items()
        ]

        return ui.layout_column_wrap(*boxes, width="200px")


app = App(app_ui, server)
