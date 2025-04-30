#
# src/mediocremiles/shiny_app/modules/training.R - Hold training tab logic & UI.
#



training_module <- function(input, output, session, activity_data, data_manager) {
  output$training_load_plot <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    if (exists("generate_training_load_plot")) {
      generate_training_load_plot(data)
    } else {
      if ("distance_km" %in% names(data) && "total_moving_time_seconds" %in% names(data) && 
          "id" %in% names(data) && "start_date" %in% names(data)) {
        
        load_data <- data %>%
          group_by(id) %>%
          slice(1) %>%
          ungroup() %>%
          mutate(
            date = as.Date(start_date),
            training_load = distance_km * (total_moving_time_seconds / 3600)
          ) %>%
          arrange(date)
        
        load_data$rolling_load <- zoo::rollmean(load_data$training_load, 7, fill = NA, align = "right")
        
        ggplot(load_data, aes(x = date)) +
          geom_bar(aes(y = training_load), stat = "identity", fill = "#f39c12", alpha = 0.5) +
          geom_line(aes(y = rolling_load), size = 1, color = "#e74c3c") +
          labs(x = "Date", y = "Training Load", title = "Training Load Over Time") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        ggplot() + 
          annotate("text", x = 0, y = 0, label = "Training load data not available") +
          theme_void()
      }
    }
  })
  
  output$hr_zones_plot <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    if (exists("generate_hr_zones_plot")) {
      generate_hr_zones_plot(data)
    } else if ("average_heartrate" %in% names(data) && "id" %in% names(data)) {
      hr_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.na(average_heartrate))
      
      hr_data <- hr_data %>%
        mutate(hr_zone = case_when(
          average_heartrate < 125 ~ "Zone 1: Recovery",
          average_heartrate < 140 ~ "Zone 2: Aerobic",
          average_heartrate < 155 ~ "Zone 3: Tempo",
          average_heartrate < 170 ~ "Zone 4: Threshold",
          T ~ "Zone 5: Maximum"
        ))
      
      zone_counts <- hr_data %>%
        count(hr_zone) %>%
        mutate(hr_zone = factor(hr_zone, levels = c(
          "Zone 1: Recovery", "Zone 2: Aerobic", "Zone 3: Tempo", 
          "Zone 4: Threshold", "Zone 5: Maximum"
        )))
      
      ggplot(zone_counts, aes(x = hr_zone, y = n, fill = hr_zone)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c(
          "Zone 1: Recovery" = "#3498db",
          "Zone 2: Aerobic" = "#2ecc71",
          "Zone 3: Tempo" = "#f39c12",
          "Zone 4: Threshold" = "#e67e22",
          "Zone 5: Maximum" = "#e74c3c"
        )) +
        labs(x = "Heart Rate Zone", y = "Count", title = "Activities by Heart Rate Zone") +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Heart rate zone data not available") +
        theme_void()
    }
  })
  
  output$power_zones_plot <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    if (exists("generate_power_zones_plot")) {
      generate_power_zones_plot(data)
    } else if ("weighted_average_power" %in% names(data) && "id" %in% names(data)) {
      power_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.na(weighted_average_power))
      
      power_data <- power_data %>%
        mutate(power_zone = case_when(
          weighted_average_power < 150 ~ "Zone 1: Recovery",
          weighted_average_power < 200 ~ "Zone 2: Endurance",
          weighted_average_power < 250 ~ "Zone 3: Tempo",
          weighted_average_power < 300 ~ "Zone 4: Threshold",
          weighted_average_power < 350 ~ "Zone 5: VO2 Max",
          TRUE ~ "Zone 6: Anaerobic"
        ))
      
      zone_counts <- power_data %>%
        count(power_zone) %>%
        mutate(power_zone = factor(power_zone, levels = c(
          "Zone 1: Recovery", "Zone 2: Endurance", "Zone 3: Tempo", 
          "Zone 4: Threshold", "Zone 5: VO2 Max", "Zone 6: Anaerobic"
        )))
      
      ggplot(zone_counts, aes(x = power_zone, y = n, fill = power_zone)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c(
          "Zone 1: Recovery" = "#3498db",
          "Zone 2: Endurance" = "#2ecc71",
          "Zone 3: Tempo" = "#f39c12",
          "Zone 4: Threshold" = "#e67e22",
          "Zone 5: VO2 Max" = "#e74c3c",
          "Zone 6: Anaerobic" = "#9b59b6"
        )) +
        labs(x = "Power Zone", y = "Count", title = "Activities by Power Zone") +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Power data not available") +
        theme_void()
    }
  })
  
  output$weekly_training_load <- renderPlot({
    data <- activity_data()
    
    req(nrow(data) > 0)
    
    if ("id" %in% names(data) && "start_date" %in% names(data)) {
      if ("distance_km" %in% names(data) && 
          "total_moving_time_seconds" %in% names(data)) {
        weekly_load <- data %>%
          group_by(id) %>%
          slice(1) %>%
          ungroup() %>%
          mutate(
            week = floor_date(as.Date(start_date), "week"),
            load = distance_km * (total_moving_time_seconds / 3600)
          ) %>%
          group_by(week) %>%
          summarize(
            weekly_load = sum(load, na.rm = TRUE),
            .groups = "drop"
          )
        
        ggplot(weekly_load, aes(x = week, y = weekly_load)) +
          geom_bar(stat = "identity", fill = "#f39c12") +
          geom_line(aes(group = 1), color = "#e74c3c", size = 1) +
          labs(x = "Week", y = "Training Load", title = "Weekly Training Load") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        weekly_count <- data %>%
          group_by(id) %>%
          slice(1) %>% 
          ungroup() %>%
          mutate(week = floor_date(as.Date(start_date), "week")) %>%
          count(week)
        
        ggplot(weekly_count, aes(x = week, y = n)) +
          geom_bar(stat = "identity", fill = "#f39c12") +
          labs(x = "Week", y = "Activity Count", title = "Weekly Activities") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    } else {
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Weekly training data not available") +
        theme_void()
    }
  })
}