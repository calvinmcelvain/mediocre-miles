#
# src/mediocremiles/shiny_app/modules/recent_activity/details.R - Recent activity details.
#



activity_details_module <- function(input, output, session, activity_data) {
  observe({
    data <- activity_data()
    req(nrow(data) > 0)
    
    activities <- data %>%
      group_by(id) %>%
      slice(1) %>%
      ungroup() %>%
      arrange(desc(start_date)) %>%
      mutate(activity_label = paste0(format(date, "%Y-%m-%d"), ": ", name))
    
    updateSelectInput(session, "selected_activity",
                     choices = setNames(activities$id, activities$activity_label),
                     selected = activities$id[1])
  })
  
  selected_activity_data <- reactive({
    req(input$selected_activity)
    
    data <- activity_data()
    req(nrow(data) > 0)
    
    activity <- data %>%
      filter(id == input$selected_activity)
    
    if (nrow(activity) > 0) {
      return(activity)
    } else {
      return(NULL)
    }
  })

  output$activity_date <- renderValueBox({
    activity <- selected_activity_data()
    req(activity)
    
    date_str <- format(activity$date[1], "%b %d, %Y")
    
    valueBox(
      date_str,
      "Activity Date",
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  output$activity_distance <- renderValueBox({
    activity <- selected_activity_data()
    req(activity)
    
    dist_str <- sprintf("%.2f mi", activity$distance_miles[1])
    
    valueBox(
      dist_str,
      "Distance",
      icon = icon("road"),
      color = "green"
    )
  })
  
  output$activity_time <- renderValueBox({
    activity <- selected_activity_data()
    req(activity)
    
    seconds <- activity$total_moving_time_seconds[1]
    hours <- floor(seconds / 3600)
    minutes <- floor((seconds - hours * 3600) / 60)
    seconds <- seconds - hours * 3600 - minutes * 60
    
    if (hours > 0) {
      time_str <- sprintf("%d:%02d:%02d", hours, minutes, seconds)
    } else {
      time_str <- sprintf("%d:%02d", minutes, seconds)
    }
    
    valueBox(
      time_str,
      "Moving Time",
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$activity_pace <- renderValueBox({
    activity <- selected_activity_data()
    req(activity)
    
    if (!is.null(activity$average_speed_mph) && !is.na(activity$average_speed_mph[1]) && activity$average_speed_mph[1] > 0) {
      pace_min_mile <- 60 / activity$average_speed_mph[1]
      pace_minutes <- floor(pace_min_mile)
      pace_seconds <- round((pace_min_mile - pace_minutes) * 60)
      pace_str <- sprintf("%d:%02d /mi", pace_minutes, pace_seconds)
    } else {
      pace_str <- "N/A"
    }
    
    valueBox(
      pace_str,
      "Average Pace",
      icon = icon("tachometer-alt"),
      color = "orange"
    )
  })
  
  output$activity_pace_chart <- renderPlot({
    activity <- selected_activity_data()
    req(activity)
    
    if ("splits_standard" %in% names(activity) && !is.null(activity$splits_standard[[1]])) {
      splits_data <- activity$splits_standard[[1]]
      
      if (length(splits_data) > 0) {
        splits_df <- data.frame(
          mile = seq_along(splits_data),
          pace = sapply(splits_data, function(s) 60 / s$average_speed)
        )
        
        # Plot
        ggplot(splits_df, aes(x = mile, y = pace)) +
          geom_bar(stat = "identity", fill = "#2c3e50") +
          geom_line(color = "#e74c3c", size = 1) +
          geom_point(color = "#e74c3c", size = 3) +
          labs(x = "Mile", y = "Pace (min/mile)", title = "Pace by Mile") +
          scale_y_continuous(labels = function(y) sprintf("%d:%02d", floor(y), round((y - floor(y)) * 60))) +
          theme_minimal()
      } else {
        ggplot() +
          annotate("text", x = 0.5, y = 0.5, label = "No pace data available for this activity") +
          theme_void()
      }
    } else {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "No pace data available for this activity") +
        theme_void()
    }
  })
  
  output$activity_hr_chart <- renderPlot({
    activity <- selected_activity_data()
    req(activity)
    
    if ("average_heartrate" %in% names(activity) && !is.na(activity$average_heartrate[1])) {
      
      hr_data <- data.frame(
        metric = c("Average HR", "Max HR"),
        value = c(activity$average_heartrate[1], activity$max_heartrate[1])
      )
      
      ggplot(hr_data, aes(x = metric, y = value, fill = metric)) +
        geom_bar(stat = "identity") +
        geom_text(aes(label = round(value, 0)), vjust = -0.5) +
        labs(x = NULL, y = "Heart Rate (bpm)", title = "Heart Rate Summary") +
        theme_minimal() +
        scale_fill_manual(values = c("Average HR" = "#3498db", "Max HR" = "#e74c3c")) +
        theme(legend.position = "none")
    } else {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "No heart rate data available for this activity") +
        theme_void()
    }
  })
  
  output$activity_elevation <- renderPlot({
    activity <- selected_activity_data()
    req(activity)
    
    if ("total_elevation_gain_meters" %in% names(activity) && !is.na(activity$total_elevation_gain_meters[1])) {
      elev_gain_ft <- activity$elevation_gain_feet[1]
      
      ggplot() +
        annotate("text", x = 0.5, y = 0.6, 
                label = sprintf("Total Elevation Gain: %.0f ft", elev_gain_ft),
                size = 6) +
        annotate("text", x = 0.5, y = 0.4, 
                label = "Detailed elevation profile not available",
                size = 4, color = "gray50") +
        theme_void() +
        xlim(0, 1) + ylim(0, 1)
    } else {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "No elevation data available for this activity") +
        theme_void()
    }
  })
}