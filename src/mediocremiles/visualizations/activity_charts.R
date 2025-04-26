library(ggplot2)
library(dplyr)
library(lubridate)



generate_activity_distribution_plot <- function(data) {
  activity_counts <- data %>%
    count(activity_type) %>%
    arrange(desc(n))
  
  ggplot(activity_counts, aes(x = "", y = n, fill = activity_type)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    theme_minimal() +
    labs(title = "Activity Type Distribution",
         fill = "Activity Type") +
    theme(legend.position = "right",
          axis.title = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_blank())
}


generate_activity_details_plot <- function(data) {
  monthly_distance <- data %>%
    mutate(month_year = format(as.Date(start_date), "%Y-%m")) %>%
    group_by(month_year, activity_type) %>%
    summarize(total_distance = sum(distance_km, na.rm = TRUE),
              .groups = "drop") %>%
    arrange(month_year)
  
  ggplot(monthly_distance, aes(x = month_year, y = total_distance, fill = activity_type)) +
    geom_bar(stat = "identity") +
    theme_minimal() +
    labs(title = "Monthly Distance by Activity Type",
         x = "Month",
         y = "Distance (km)",
         fill = "Activity Type") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}


generate_recent_activities_table <- function(data) {
  recent <- data %>%
    arrange(desc(start_date)) %>%
    head(10) %>%
    select(
        name, activity_type, start_date, distance_km, moving_time_hours,
        average_heartrate, max_heartrate, total_elevation_gain_meters)
  
  recent$start_date <- format(recent$start_date, "%Y-%m-%d %H:%M")
  recent$distance_km <- round(recent$distance_km, 1)
  recent$moving_time_hours <- round(recent$moving_time_hours, 2)
  
  names(recent) <- c(
    "Name", "Type", "Date", "Distance (km)", "Duration (hrs)", 
    "Avg HR", "Max HR", "Elevation Gain (m)")
  
  return(recent)
}