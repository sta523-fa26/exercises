library(tidyverse)
library(shiny)
library(bslib)

n_sim = 501

beta_binom = function(label, a, b, x, n) {
  tibble(
    label = label,
    p = seq(0, 1, length.out = n_sim),
    prior = dbeta(p, a, b),
    likelihood = dbinom(x, n, p) * (n + 1),
    posterior = dbeta(p, a + x, b + n - x)
  ) |>
    pivot_longer(
      prior:posterior,
      names_to = "distribution", values_to = "density",
      names_transform = fct_inorder
    )
}

prior_ui = function(id, label) {
  ns = NS(id)

  card_body(
    id = ns("body"),
    class = "prior",
    numericInput(ns("a"), paste(label, "heads"), min = 0, value = rpois(1, 3) + 1),
    numericInput(ns("b"), paste(label, "tails"), min = 0, value = rpois(1, 3) + 1),
    actionButton(
      ns("remove"), NULL, icon = icon("xmark"),
      class = "btn-sm btn-outline-danger"
    )
  )
}

prior_server = function(id, label, x, n) {
  moduleServer(id, function(input, output, session) {
    removed = reactiveVal(FALSE)

    observe({
      removeUI(paste0("#", session$ns("body")))
      removed(TRUE)
    }) |>
      bindEvent(input$remove, once = TRUE)

    reactive({
      if (removed()) return(NULL)
      req(input$a, input$b)

      beta_binom(label, input$a, input$b, x(), n())
    })
  })
}

ui = page_fillable(
  title = "Beta-Binomial Prior Comparison",
  tags$head(includeCSS("Lec23_app.css")),
  layout_columns(
    col_widths = c(3, 9),
    div(
      class = "controls overflow-auto px-1 pb-1",
      card(
        card_header("Data", class = "text-bg-primary"),
        sliderInput("x", "# of heads", min = 0, max = 100, value = 7),
        sliderInput("n", "# of flips", min = 0, max = 100, value = 10)
      ),
      card(
        card_header("Priors", class = "text-bg-primary"),
        div(id = "priors"),
        card_footer(
          actionButton(
            "add", "Add prior", icon = icon("plus"),
            class = "btn-primary w-100"
          )
        )
      )
    ),
    card(
      card_header("Distributions", class = "text-bg-primary"),
      plotOutput("plot")
    )
  )
)

server = function(input, output, session) {
  observe({
    updateSliderInput(session, "x", max = input$n)
  }) |>
    bindEvent(input$n)

  priors = reactiveVal(list())

  observe({
    id = paste0("prior_", input$add)
    label = paste("Prior", input$add)

    insertUI("#priors", where = "beforeEnd", ui = prior_ui(id, label))
    prior = prior_server(id, label, x = reactive(input$x), n = reactive(input$n))
    priors(c(priors(), prior))
  }) |>
    bindEvent(input$add)

  d = reactive({
    map(priors(), \(prior) prior()) |>
      list_rbind()
  })

  output$plot = renderPlot({
    req(nrow(d()) > 0)

    ggplot(d(), aes(x = p, y = density, color = distribution)) +
      geom_line(linewidth = 1.5) +
      geom_ribbon(aes(ymax = density, fill = distribution), ymin = 0, alpha = 0.5) +
      facet_wrap(vars(label), ncol = 1) +
      labs(color = NULL, fill = NULL)
  })
}

shinyApp(ui = ui, server = server)
