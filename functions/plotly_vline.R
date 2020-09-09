
## Source: https://stackoverflow.com/questions/34093169/horizontal-vertical-line-in-plotly

plotly_vline <- function(x = 0, color = "black", ...) {
  list(type = "line",
       y0 = 0, y1 = 1, yref = "paper",
       x0 = x, x1 = x,  
       line = list(color = color, ...))
}

plotly_hline <- function(y = 0, color = "black", ...) {
  list(type = "line", 
       x0 = 0, x1 = 1, xref = "paper", 
       y0 = y, y1 = y, 
       line = list(color = color, ...)
  )
}

if(FALSE){
  library(plotly)
  fig <- plot_ly(x = ~1:100, y = ~rnorm(100), 
                 color = I("black"), 
                 name = "my points",
                 type = "scatter",
                 mode="lines")
  fig <- layout(fig,
                title = "Some points that matter\n or don't matter\n but could matter",
                xaxis = list(title = "My x axis"),
                yaxis = list (title = "My y value"))
  fig %>% layout(shapes = plotly_vline(80, "red"))
  fig %>% layout(shapes = plotly_hline(-10, "black", widthh=0.5, dash="dot"))
  
}

