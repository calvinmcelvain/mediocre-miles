#
# Activities module.
#



activitiesModuleUI <- function(id) {
  ns <- NS(id)
  
  tabItem(tabName = "activities",
          fluidRow(
            box(
              title = "Activity Distribution",
              status = "info",
              solidHeader = T,
              collapsible = T,
              width = 6,
              plotOutput("activity_distribution") %>% withSpinner()
            ),
            box(
              title = "Activity Details",
              status = "info",
              solidHeader = T,
              collapsible = T,
              width = 6,
              plotOutput("activity_details") %>% withSpinner()
            )
          ),
          fluidRow(
            box(
              title = "Activity Pace vs. Distance",
              status = "info",
              collapsible = T,
              width = 6,
              plotOutput("pace_vs_distance") %>% withSpinner()
            ),
            box(
              title = "Activity Heart Rate vs. Pace",
              status = "info",
              solidHeader = T,
              collapsible = T,
              width = 6,
              plotOutput("hr_vs_pace") %>% withSpinner()
            )
          )
  )
}



activitiesModule <- function(id, activity_data, theme.base, colors.wsj) {
  moduleServer(id, function(input, output, session) {
    
    output$activity_distribution <- renderPlot({
      data <- activity_data()
      generate_activity_distribution_plot(data, theme.base)
    })
    
    output$activity_details <- renderPlot({
      data <- activity_data()
      generate_activity_details_plot(data, theme.base)
    })
    
    output$pace_vs_distance <- renderPlot({
      data <- activity_data()
      
      pace_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        mutate(pace_min_km = 60 / average_speed_kmh)
      
      ggplot(pace_data, aes(x = distance_km, y = pace_min_km)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(method = "loess", se = T, color = "#3498db") +
        labs(x = "Distance (km)", y = "Pace (min/km)", title = "Pace vs. Distance") +
        theme_minimal() +
        scale_y_continuous(labels = function(x) sprintf("%.1f", x))
    })
    
    output$hr_vs_pace <- renderPlot({
      data <- activity_data()
      
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
    })
  })
}



