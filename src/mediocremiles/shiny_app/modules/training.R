#
# src/mediocremiles/shiny_app/modules/training.R - Hold training tab logic & UI.
#



training_module <- function(input, output, session, activity_data, data_manager) {
  output$training_load_plot <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_training_load_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Training load data not available") +
        theme_void()
    }
  }))
  
  output$hr_zones_plot <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_hr_zones_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Heart rate zone data not available") +
        theme_void()
    }
  }))
  
  output$power_zones_plot <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_power_zones_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Power data not available") +
        theme_void()
    }
  }))
  
  output$radar_plot <- suppressWarnings(renderPlot({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_radar_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Efficiency Plot not available") +
        theme_void()
    }
  }))
  
  output$weekly_training_load <- suppressWarnings(renderPlotly({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      generate_training_summary_plot(data, theme.base, colors.wsj)
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Training not available") +
        theme_void()
    }
  }))
}