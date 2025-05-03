#
# src/mediocremiles/shiny_app/modules/trends.R - Trends tab logic & UI.
#



trends_module <- function(input, output, session, activity_data) {
  output$pace_trend <- renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_pace_trend_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Pace trend data not available") +
        theme_void()
    }
  })
  
  output$hr_trend <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_hr_trend_plot(data, theme.base)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "HR trend data not available") +
        theme_void()
    }
  }))
  
  output$distance_trend <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_distance_trend_plot(data, theme.base)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Distance trend data not available") +
        theme_void()
    }
  }))
  
  output$seasonal_patterns <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_seasonal_patterns_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Not enough data for Seasonal Pattern plot") +
        theme_void()
    }
  }))
  
  output$yoy_comparison <- suppressWarnings(renderPlot({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_yoy_comparison_plot(data, theme.base)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Not enough data for YoY plot") +
        theme_void()
    }
  }))
}