#
# Trends module.
#



trendsModuleUI <- function(id) {
  ns <- NS(id)
  
  tabItem(tabName = "trends",
          fluidRow(
            box(
              title = "Performance Trends",
              status = "success",
              solidHeader = T,
              width = 12,
              radioButtons(
                "trend_metric", "Metric:",
                choices = c("Average Pace" = "pace", 
                            "Average Heart Rate" = "hr", 
                            "Distance" = "distance"),
                selected = "pace",
                inline = T
              ),
              plotOutput("performance_trends") %>% withSpinner()
            )
          ),
          fluidRow(
            box(
              title = "Seasonal Patterns",
              status = "success",
              solidHeader = T,
              width = 6,
              plotOutput("seasonal_patterns") %>% withSpinner()
            ),
            box(
              title = "Year-over-Year Comparison",
              status = "success",
              solidHeader = T,
              width = 6,
              plotOutput("yoy_comparison") %>% withSpinner()
            )
          )
  )
}



trendsModule <- function(id, activity_data, theme.base, colors.wsj) {
  moduleServer(id, function(input, output, session) {
    output$performance_trends <- renderPlot({
      data <- activity_data()
      
      trend_data <- data %>% distinct(id, .keep_all = T) 
      
      if(input$trend_metric == "pace") {
        trend_data$pace_min_mile <- 60 / trend_data$average_speed_mph
        filtered_trend_data <- trend_data %>% filter(activity_type == "Run")
        
        ggplot(filtered_trend_data, aes(x = date, y = pace_min_mile)) +
          geom_point(aes(color = activity_type), alpha = 0.7, color = colors.wsj[6]) +
          geom_smooth(method = "loess", color = colors.wsj[3], fill = colors.wsj[3]) +
          labs(x = NULL, y = "Pace (min/mile)") +
          theme.base +
          scale_y_continuous(labels = function(x) sprintf("%.1f", x)) +
          scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else if(input$trend_metric == "hr") {
        ggplot(trend_data, aes(x = date, y = average_heartrate)) +
          geom_point(aes(color = activity_type), alpha = 0.7) +
          geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
          scale_color_wsj() +
          scale_fill_wsj() +
          labs(x = NULL, y = "Heart Rate (bpm)", color = "Activity Type", fill = "Activity Type") +
          theme.base +
          scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else if(input$trend_metric == "distance" && "distance_km" %in% names(trend_data)) {
        trend_data.2 <- trend_data %>% filter(distance_miles > 1)
        ggplot(trend_data.2, aes(x = date, y = distance_miles)) +
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
      generate_seasonal_patterns_plot(data, theme.base, colors.wsj)
    })
    
    output$yoy_comparison <- renderPlot({
      data <- activity_data()
      generate_yoy_comparison_plot(data, theme.base)
    })
  })
}

