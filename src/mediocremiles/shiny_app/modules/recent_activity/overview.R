#
# src/mediocremiles/shiny_app/modules/recent_activity/overview.R - Overview of recent activities.
#


recent_activity_overview_module <- function(input, output, session, activity_data, data_manager) {
  recent_stats <- reactive({
    data <- activity_data()
    req(nrow(data) > 0)

    recent_cutoff <- Sys.Date() - 30
    
    recent_data <- data %>%
      filter(as.Date(start_date) >= recent_cutoff)
    
    if (nrow(recent_data) > 0) {
      activities_count <- length(unique(recent_data$id))
      
      total_distance_miles <- recent_data %>% 
        group_by(id) %>% 
        summarize(distance = first(distance_miles), .groups = "drop") %>% 
        pull(distance) %>% 
        sum(na.rm = T)
      
      total_time_seconds <- recent_data %>% 
        group_by(id) %>% 
        summarize(time = first(total_moving_time_seconds), .groups = "drop") %>% 
        pull(time) %>% 
        sum(na.rm = T)
      
      total_elevation_feet <- recent_data %>% 
        group_by(id) %>% 
        summarize(elevation = first(elevation_gain_feet), .groups = "drop") %>% 
        pull(elevation) %>% 
        sum(na.rm = T)
      
      hours <- floor(total_time_seconds / 3600)
      minutes <- floor((total_time_seconds - hours * 3600) / 60)
      time_str <- sprintf("%d:%02d", hours, minutes)
      
      return(list(
        count = activities_count,
        distance = sprintf("%.1f mi", total_distance_miles),
        time = time_str,
        elevation = sprintf("%.0f ft", total_elevation_feet)
      ))
    } else {
      return(list(
        count = 0,
        distance = "0.0 mi",
        time = "0:00",
        elevation = "0 ft"
      ))
    }
  })
  
  output$total_recent_activities <- renderValueBox({
    valueBox(
      recent_stats()$count, 
      "Recent Activities (30 days)",
      icon = icon("running"),
      color = "orange")
  })
  
  output$recent_distance <- renderValueBox({
    valueBox(
      recent_stats()$distance,
      "Total Distance",
      icon = icon("road"),
      color = "green")
  })
  
  output$recent_time <- renderValueBox({
    valueBox(
      recent_stats()$time,
      "Total Time",
      icon = icon("clock"),
      color = "purple")
  })
  
  output$recent_elevation <- renderValueBox({
    valueBox(
      recent_stats()$elevation,
      "Total Elevation",
      icon = icon("mountain"),
      color = "blue")
  })
  
  output$recent_weekly_summary <- renderPlotly({
    data <- activity_data()
    req(nrow(data) > 0)
    
    recent_cutoff <- Sys.Date() - 84
    
    recent_data <- data %>%
      filter(as.Date(start_date) >= recent_cutoff)
    
    if (nrow(recent_data) > 0) {
      weekly_data <- recent_data %>%
        mutate(week = floor_date(as.Date(start_date), "week")) %>%
        group_by(week, activity_type) %>%
        summarize(
          distance = sum(distance_miles, na.rm = T),
          time = sum(total_moving_time_seconds, na.rm = T) / 3600,
          count = n(),
          .groups = "drop"
        )
      
      p <- ggplot(weekly_data, aes(x = week, y = distance, fill = activity_type)) +
        geom_bar(stat = "identity") +
        labs(x = NULL, y = "Distance (miles)", title = "Weekly Activity Summary") +
        theme_minimal() +
        scale_fill_brewer(palette = "Set2") +
        scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      ggplotly(p)
    } else {
      plot_ly() %>%
        add_annotations(
          text = "No recent activity data available",
          showarrow = F
        )
    }
  })

  output$recent_activities_table <- renderDT({
    data <- activity_data()
    req(nrow(data) > 0)
    
    recent_activities <- data %>%
      group_by(id) %>%
      slice(1) %>%
      ungroup() %>%
      arrange(desc(start_date)) %>%
      head(20) %>%
      select(
        Date = date,
        Name = name,
        Type = activity_type,
        Distance = distance_miles,
        `Duration (min)` = moving_time_minutes,
        `Avg Pace` = average_speed_mph,
        `Avg HR` = average_heartrate
      )
    
    recent_activities <- recent_activities %>%
      mutate(`Avg Pace` = 60 / `Avg Pace`) %>%
      mutate(`Avg Pace` = ifelse(is.infinite(`Avg Pace`), NA, 
                                sprintf("%d:%02d", floor(`Avg Pace`), 
                                       round((`Avg Pace` - floor(`Avg Pace`)) * 60))))
    
    recent_activities <- recent_activities %>%
      mutate(
        Distance = round(Distance, 1),
        `Duration (min)` = round(`Duration (min)`, 0),
        `Avg HR` = round(`Avg HR`, 0)
      )
    
    datatable(
      recent_activities,
      options = list(
        pageLength = 10,
        dom = 'ftip',
        scrollX = T
      ),
      rownames = F
    )
  })
}