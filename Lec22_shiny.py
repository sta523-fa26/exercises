from shiny import App, reactive, render, ui

app_ui = ui.page_sidebar(
    ui.sidebar(),
    title="Beta-Binomial Visualizer",
)


def server(input, output, session):
    ...


app = App(app_ui, server)
