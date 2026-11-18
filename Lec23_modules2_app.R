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

prior_inputs = function(id) {
  card_body(
    id = paste0("prior_", id),
    class = "prior",
    numericInput(
      paste0("a_", id), paste("Prior", id, "heads"),
      min = 0, value = rpois(1, 3) + 1
    ),
    numericInput(
      paste0("b_", id), paste("Prior", id, "tails"),
      min = 0, value = rpois(1, 3) + 1
    ),
    actionButton(
      paste0("remove_", id), NULL, icon = icon("xmark"),
      class = "btn-sm btn-outline-danger"
    )
  )
}

ui = page_fillable(
  title = "Beta-Binomial Prior Comparison",
  tags$head(includeCSS("Lec23_app.css")),
  layout_columns(
    col_widths = c(3, 9),
    div(
      class = "controls overflow-auto px-1 pb-1",
      card(
        card_header("Data", class = "text-bg-secondary"),
        sliderInput("x", "# of heads", min = 0, max = 100, value = 7),
        sliderInput("n", "# of flips", min = 0, max = 100, value = 10)
      ),
      card(
        card_header("Priors", class = "text-bg-secondary"),
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
      card_header("Distributions", class = "text-bg-secondary"),
      plotOutput("plot")
    )
  )
)

server = function(input, output, session) {
  observe({
    updateSliderInput(session, "x", max = input$n)
  }) |>
    bindEvent(input$n)

  ids = reactiveVal(integer())

  observe({
    id = input$add

    insertUI("#priors", where = "beforeEnd", ui = prior_inputs(id))
    ids(c(ids(), id))

    observe({
      removeUI(paste0("#prior_", id))
      ids(setdiff(ids(), id))
    }) |>
      bindEvent(input[[paste0("remove_", id)]], once = TRUE)
  }) |>
    bindEvent(input$add)

  d = reactive({
    map(
      ids(),
      \(id) {
        a = input[[paste0("a_", id)]]
        b = input[[paste0("b_", id)]]
        req(a, b)

        beta_binom(paste("Prior", id), a, b, input$x, input$n)
      }
    ) |>
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
