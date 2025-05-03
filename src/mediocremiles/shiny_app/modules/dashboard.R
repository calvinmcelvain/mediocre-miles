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
      div("Total Strava Activities", style = "font-family: monospace;"),
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
      div("Total Distance", style = "font-family: monospace;"),
      icon = icon("road"),
      color = "red")
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
      sprintf("%.1f miles", total_miles),
      div("Total Distance", style = "font-family: monospace;"),
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
      div("Total Time", style = "font-family: monospace;"),
      icon = icon("clock"),
      color = "purple")
  })
  
  output$ytd_activities <- renderValueBox({
    data <- activity_data() %>%
      filter(year == year(Sys.Date()))
    
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
      div("YTD Total Strava Activities", style = "font-family: monospace;"),
      icon = icon("running"),
      color = "yellow")
  })
  
  output$ytd_distance_km <- renderValueBox({
    data <- activity_data() %>%
      filter(year == year(Sys.Date()))
    
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
      div("YTD Total Distance", style = "font-family: monospace;"),
      icon = icon("road"),
      color = "maroon")
  })
  
  output$ytd_distance_miles <- renderValueBox({
    data <- activity_data() %>%
      filter(year == year(Sys.Date()))
    
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
      sprintf("%.1f miles", total_miles),
      div("YTD Total Distance", style = "font-family: monospace;"),
      icon = icon("road"),
      color = "lime")
  })
  
  output$ytd_time <- renderValueBox({
    data <- activity_data() %>%
      filter(year == year(Sys.Date()))
    
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
      div("YTD Total Time", style = "font-family: monospace;"),
      icon = icon("clock"),
      color = "fuchsia")
  })
  
  output$recent_activities_table <- renderDT({
    data <- activity_data()
    if (nrow(data) > 0) {
      generate_recent_activities_table(data, colors.wsj)
    } else {
      data.frame()
    }
  })
}