library(shiny)
library(bslib)

library(tidyverse)

ui = page_sidebar(
  title = "My Beta-Binomial App",
  sidebar = sidebar(
    h4("Data:"),
    sliderInput("x", "# of heads", min=0, max=100, value=7),
    sliderInput("n", "# of flips", min=0, max=100, value=10),
    h4("Pror:"),
    numericInput("a", "Prior # of heads:", min=0, value=2),
    numericInput("b", "Prior # of tails:", min=0, value=2)
  ),
  plotOutput("plot"),
  tableOutput("table")
)

server = function(input, output, session) {

  observe({
    updateSliderInput(session, "x", max = input$n)
  })

  d = reactive({
    req(input$a)

    shiny::validate(
      shiny::need(input$a > 0, "a should be positive"),
      shiny::need(input$b > 0, "b should be positive")
    )

    tibble(
      p = seq(0,1,length.out=1001)
    ) |>
      mutate(
        prior = dbeta(x = p, shape1 = input$a, shape2 = input$b),
        likelihood = dbinom(x = input$x, size = input$n, prob = p) / 
                     (choose(input$n, input$x) * beta(input$x+1, input$n-input$x+1)),
        posterior = dbeta(x = p, shape1 = input$x + input$a, shape2 = input$n - input$x + input$b)
      ) |>
      pivot_longer(
        cols = -p, names_to = "distribution", values_to = "density"
      )
  })

  output$plot = renderPlot({
      ggplot(
        d(), aes(x=p, y=density, color=distribution) 
      ) +
        geom_line() +
        geom_ribbon(aes(ymax=density, fill=distribution), ymin=0, alpha=0.5)
  })


  output$table = renderTable({
    d() |>
      group_by(distribution) |>
      summarize(
        mean = sum(p*density) / n(),
        median = p[(cumsum(density/n()) >= 0.5)][1],
        q025 = p[(cumsum(density/n()) >= 0.025)][1],
        q975 = p[(cumsum(density/n()) >= 0.975)][1]
      )
  })
}

shinyApp(ui, server)
