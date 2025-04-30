library(ggplot2)
library(dplyr)
library(lubridate)



generate_activity_distribution_plot <- function(data, plot_theme) {
  activity_counts <- data %>%
    count(activity_type) %>%
    arrange(desc(n))
  
  p <- ggplot(activity_counts, aes(x = "", y = n, fill = activity_type)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    scal_fill_wsj() +
    labs(fill = "Activity Type") +
    plot_theme
  
  return(p)
}


generate_activity_details_plot <- function(data, plot_theme) {
  monthly_time <- data %>%
    mutate(month_year = format(as.Date(start_date), "%Y-%m")) %>%
    distinct(id, .keep_all = T) %>%
    group_by(month_year, activity_type) %>%
    summarize(total_time = sum(total_elapsed_time_seconds / 3600, na.rm = T),
              .groups = "drop") %>%
    arrange(month_year)
  
  p <- ggplot(monthly_time, aes(x = month_year, y = total_time, fill = activity_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Monthly Time by Activity Type",
         x = "Month",
         y = "Time (hours)",
         fill = "Activity Type") +
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}


generate_recent_activities_table <- function(data) {
  recent <- data %>%
    arrange(desc(start_date)) %>%
    head(10) %>%
    select(
        name, activity_type, start_date, distance_miles, moving_time_hours,
        average_heartrate, max_heartrate, total_elevation_gain_meters)
  
  recent$start_date <- format(recent$start_date, "%Y-%m-%d %H:%M")
  recent$distance_km <- round(recent$distance_miles, 1)
  recent$moving_time_hours <- round(recent$moving_time_hours, 2)
  
  names(recent) <- c(
    "Name", "Type", "Date", "Distance (miles)", "Duration (hrs)", 
    "Avg HR", "Max HR", "Elevation Gain (m)")
  
  return(recent)
}