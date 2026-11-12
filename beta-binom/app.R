library(tidyverse)
library(shiny)
library(bslib)


ui = page_sidebar(
  #theme = bs_theme(preset = "brite"),
  title = "Beta-Binomial Visualizer",
  sidebar = sidebar(
    h4("Data:"),
    sliderInput("x", "# of heads", min=0, max=100, value=7),
    sliderInput("n", "# of flips", min=0, max=100, value=10),
    h4("Prior:"),
    numericInput("a", "Prior # of head", min=0, value=5),
    numericInput("b", "Prior # of tails", min=0, value=5),
    actionButton("go", "Go")
  ),
  card(
    card_header("Distributions"),
    card_body(
      plotOutput("plot")
    ),
    full_screen = TRUE
  ),
  card(
    card_header(
      textOutput("summary_title"),
      popover(
        bsicons::bs_icon("gear"),
        title = "Settings",
        selectInput(
          "summary_dist", "Distributions:",
          choices = c("prior", "likelihood", "posterior")
        )
      ),
      class = "d-flex justify-content-between align-items-center"
    ),
    card_body(
      uiOutput("value_boxes")
    )
  )
)


server = function(input, output, session) {
  bs_themer()
  
  observe({
    updateSliderInput(session, "x", max = input$n)
  }) 

  d = reactive({
    tibble(
      p = seq(0, 1, length.out = 1001)
    ) |>
    mutate(
      prior = dbeta(p, input$a, input$b),
      likelihood = dbinom(input$x, size = input$n, prob = p) |>
      (\(x) {x / (sum(x) / (n() - 1))})(),
      posterior = dbeta(p, input$a + input$x, input$b + input$n - input$x)
    ) |>
    pivot_longer(
      cols = -p,
      names_to = "distribution",
      values_to = "density"
    ) |>
    mutate(
      distribution = forcats::as_factor(distribution)
    )
  }) |>
    bindEvent(
      input$go,
      ignoreNULL = FALSE
    )

  output$plot = renderPlot({
    ggplot(
      d(),
      aes(x=p, y=density, color=distribution)
    ) +
      geom_line(linewidth=1.5) +
      geom_ribbon(aes(ymax=density, fill=distribution), ymin=0, alpha=0.5)
  })

  output$value_boxes = renderUI({
    #print( d() |> pull(distribution) )
    
    stat_icons = list(
      Mean = bsicons::bs_icon("bullseye"),
      Median = bsicons::bs_icon("symmetry-vertical"),
      `95% CI` = bsicons::bs_icon("distribute-horizontal")
    )

    dist_colors = c(
      prior = "danger",
      likelihood = "success",
      posterior = "primary"
    )


    stats = d() |>
      filter(
        distribution %in% input$summary_dist
      ) |>
      summarize(
        Mean = (sum(p * density) / sum(density)) |> format(nsmall = 3, digits=3),
        Median = p[(cumsum(density) / sum(density) >= 0.5)][1] |> format(nsmall = 3, digits=3),
        `CI 95%`= c(
          p[(cumsum(density) / sum(density) >= 0.025)][1],
          p[(cumsum(density) / sum(density) >= 0.975)][1]
        ) |>
          format(nsmall = 3, digits=3) |>
          paste(collapse = " - ")
      )
    
    boxes = imap(
      stats,
      ~ value_box(
        title = .y,
        value = .x,
        showcase = stat_icons[[.y]],
        theme = dist_colors[input$summary_dist]
      )
    ) |>
      unname()
    layout_column_wrap(!!!boxes, width="200px")
  })

  output$summary_title = renderText({
    input$summary_dist |> stringr::str_to_title()
  })
}


shinyApp(ui = ui, server = server)
