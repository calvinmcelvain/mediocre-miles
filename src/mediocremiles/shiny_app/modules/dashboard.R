#
# src/mediocremiles/shiny_app/modules/dashboard.R - Hold Dashboard logic & UI.
#



dashboard_module <- function(input, output, session, activity_data) {
  output$total_activities <- renderValueBox({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      if ("id" %in% names(data)) {
        count <- length(unique(data$id))
      } else {
        count <- nrow(data)
      }
    } else {
      count <- 0
    }
    
    valueBox(
      count, 
      "Total Strava Activities",
      icon = icon("running"),
      color = "orange")
  })
  
  output$total_distance_km <- renderValueBox({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      total_km <- data %>% 
        group_by(id) %>% 
        summarize(distance = first(distance_km), .groups = "drop") %>% 
        pull(distance) %>% 
        sum(na.rm = T)
    } else {
      total_km <- 0
    }
    
    valueBox(
      sprintf("%.1f km", total_km),
      "Total Distance",
      icon = icon("road"),
      color = "green")
  })
  
  output$total_distance_miles <- renderValueBox({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      total_miles <- data %>% 
        group_by(id) %>% 
        summarize(distance = first(distance_miles), .groups = "drop") %>% 
        pull(distance) %>% 
        sum(na.rm = T)
    } else {
      total_miles <- 0
    }
    
    valueBox(
      sprintf("%.1f mi", total_miles),
      "Total Distance",
      icon = icon("road"),
      color = "olive")
  })
  
  output$total_time <- renderValueBox({
    data <- activity_data()
    
    if (nrow(data) > 0) {
      total_seconds <- data %>% 
        group_by(id) %>% 
        summarize(time = first(total_moving_time_seconds), .groups = "drop") %>% 
        pull(time) %>% 
        sum(na.rm = T)
      
      hours <- floor(total_seconds / 3600)
      minutes <- floor((total_seconds - hours * 3600) / 60)
      time_str <- sprintf("%d:%02d", hours, minutes)
    } else {
      time_str <- "0:00"
    }
    
    valueBox(
      time_str,
      "Total Time",
      icon = icon("clock"),
      color = "purple")
  })
  
  output$weekly_summary_plot <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_weekly_summary_plot(activity_data(), theme.base, colors.wsj)
  })
  
  output$recent_activities_table <- renderDT({
    req(nrow(activity_data()) > 0)
    generate_recent_activities_table(activity_data())
  })
}