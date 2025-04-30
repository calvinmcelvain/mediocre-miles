#
# src/mediocremiles/shiny_app/modules/trends.R - Trends tab logic & UI.
#



trends_module <- function(input, output, session, activity_data) {
  output$performance_trends <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    trend_data <- data %>% distinct(id, .keep_all = T) 
    
    if (input$trend_metric == "pace" && "average_speed_mph" %in% names(trend_data)) {
      trend_data$pace_min_mile <- 60 / trend_data$average_speed_mph
      filtered_trend_data <- trend_data %>% filter(activity_type == "Run")
      
      ggplot(filtered_trend_data, aes(x = date, y = pace_min_mile)) +
        geom_point(alpha = 0.7, color = colors.wsj[6]) +
        geom_smooth(method = "loess", color = colors.wsj[3], fill = colors.wsj[3]) +
        labs(x = NULL, y = "Pace (min/mile)") +
        theme.base +
        scale_y_continuous(labels = function(x) sprintf("%.1f", x)) +
        scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    } else if (input$trend_metric == "hr" && "average_heartrate" %in% names(trend_data)) {
      ggplot(trend_data, aes(x = date, y = average_heartrate)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
        scale_color_wsj() +
        scale_fill_wsj() +
        labs(x = NULL, y = "Heart Rate (bpm)", color = "Activity Type", fill = "Activity Type") +
        theme.base +
        scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    } else if (input$trend_metric == "distance" && "distance_miles" %in% names(trend_data)) {
      trend_data_filtered <- trend_data %>% filter(distance_miles > 1)
      ggplot(trend_data_filtered, aes(x = date, y = distance_miles)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
        scale_color_wsj() +
        scale_fill_wsj() +
        labs(x = NULL, y = "Distance (miles)", color = "Activity Type", fill = "Activity Type") +
        theme.base +
        scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Selected metric data not available") +
        theme_void()
    }
  })
  
  output$seasonal_patterns <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    generate_seasonal_patterns_plot(data, theme.base, colors.wsj)
  })
  
  output$yoy_comparison <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    generate_yoy_comparison_plot(data, theme.base)
  })
}