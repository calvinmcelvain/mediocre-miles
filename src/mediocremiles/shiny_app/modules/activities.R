#
# src/mediocremiles/shiny_app/modules/activities.R - Hold activities tab logic & UI.
#



activities_module <- function(input, output, session, activity_data) {
  output$activity_distribution <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_activity_distribution_plot(activity_data(), theme.base)
  })
  
  output$activity_details <- renderPlotly({
    req(nrow(activity_data()) > 0)
    generate_activity_details_plot(activity_data(), theme.base)
  })
  
  output$pace_vs_distance <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_activity_pace_plot(activity_data(), theme.base, colors.vir)
  })
  
  output$hr_vs_pace <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    if ("average_heartrate" %in% names(data) && 
        "average_speed_kmh" %in% names(data) && 
        "id" %in% names(data)) {
      hr_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.na(average_heartrate)) %>%
        mutate(pace_min_km = 60 / average_speed_kmh)
      
      ggplot(hr_data, aes(x = pace_min_km, y = average_heartrate)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(method = "lm", se = T, color = "#3498db") +
        labs(x = "Pace (min/km)", y = "Heart Rate (bpm)", title = "Heart Rate vs. Pace") +
        theme_minimal() +
        scale_x_continuous(labels = function(x) sprintf("%.1f", x))
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Heart rate data not available") +
        theme_void()
    }
  })
}