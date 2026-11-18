from pathlib import Path

import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats
from shiny import App, module, reactive, render, req, ui

n_sim = 501

dist_colors = {"prior": "#dc3545", "likelihood": "#198754", "posterior": "#0d6efd"}


def beta_binom(label, a, b, x, n):
    return (
        pd.DataFrame({"label": label, "p": np.linspace(0, 1, n_sim)})
        .assign(
            prior=lambda df: stats.beta.pdf(df.p, a, b),
            likelihood=lambda df: stats.beta.pdf(df.p, x + 1, n - x + 1),
            posterior=lambda df: stats.beta.pdf(df.p, a + x, b + n - x),
        )
        .melt(id_vars=["label", "p"], var_name="distribution", value_name="density")
    )


@module.ui
def prior_ui(label):
    return ui.card_body(
        ui.input_numeric("a", f"{label} heads", min=0, value=np.random.poisson(3) + 1),
        ui.input_numeric("b", f"{label} tails", min=0, value=np.random.poisson(3) + 1),
        ui.input_action_button("remove", "✕", class_="btn-sm btn-outline-danger"),
        id=module.resolve_id("body"),
        class_="prior",
    )


@module.server
def prior_server(input, output, session, label, x, n):
    removed = reactive.value(False)

    @reactive.effect
    @reactive.event(input.remove)
    def _():
        ui.remove_ui(f"#{session.ns('body')}")
        removed.set(True)

    @reactive.calc
    def d():
        if removed():
            return None
        req(input.a(), input.b())

        return beta_binom(label, input.a(), input.b(), x(), n())

    return d


app_ui = ui.page_fillable(
    ui.include_css(Path(__file__).parent / "Lec23_app.css"),
    ui.layout_columns(
        ui.div(
            ui.card(
                ui.card_header("Data", class_="text-bg-secondary"),
                ui.input_slider("x", "# of heads", min=0, max=100, value=7),
                ui.input_slider("n", "# of flips", min=0, max=100, value=10),
            ),
            ui.card(
                ui.card_header("Priors", class_="text-bg-secondary"),
                ui.div(id="priors"),
                ui.card_footer(
                    ui.input_action_button(
                        "add", "+ Add prior", class_="btn-primary w-100"
                    )
                ),
            ),
            class_="controls overflow-auto px-1 pb-1",
        ),
        ui.card(
            ui.card_header("Distributions", class_="text-bg-secondary"),
            ui.output_plot("plot"),
        ),
        col_widths=(3, 9),
    ),
    title="Beta-Binomial Prior Comparison",
)


def server(input, output, session):
    @reactive.effect
    def _():
        ui.update_slider("x", max=input.n())

    priors = reactive.value([])

    @reactive.effect
    @reactive.event(input.add)
    def _():
        id = f"prior_{input.add()}"
        label = f"Prior {input.add()}"

        ui.insert_ui(prior_ui(id, label), selector="#priors", where="beforeEnd")
        prior = prior_server(id, label, x=input.x, n=input.n)
        priors.set([*priors(), prior])

    @reactive.calc
    def d():
        dfs = [prior() for prior in priors()]
        req(any(df is not None for df in dfs))

        return pd.concat(dfs)

    @render.plot
    def plot():
        g = sns.relplot(
            d(), x="p", y="density", hue="distribution", row="label",
            kind="line", palette=dist_colors,
        )
        for ax in g.axes.flat:
            for line in ax.lines:
                ax.fill_between(*line.get_data(), color=line.get_color(), alpha=0.3)

        return g.figure


app = App(app_ui, server)
