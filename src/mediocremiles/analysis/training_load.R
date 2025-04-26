library(ggplot2)
library(dplyr)
library(lubridate)



generate_training_load_plot <- function(data) {
  training_load <- data %>%
    arrange(start_date) %>%
    mutate(date = as.Date(start_date)) %>%
    group_by(date) %>%
    summarize(
      daily_distance = sum(distance_km, na.rm = TRUE),
      daily_time = sum(moving_time_hours, na.rm = TRUE),
      .groups = "drop"
    )
  
  training_load <- training_load %>%
    arrange(date) %>%
    mutate(
      rolling_7d_distance = zoo::rollmean(daily_distance, 7, fill = NA, align = "right"),
      rolling_28d_distance = zoo::rollmean(daily_distance, 28, fill = NA, align = "right"),
      acute_chronic_ratio = rolling_7d_distance / rolling_28d_distance
    )
  
  ggplot(training_load, aes(x = date)) +
    geom_bar(aes(y = daily_distance), stat = "identity", fill = "lightblue", alpha = 0.5) +
    geom_line(aes(y = rolling_7d_distance, color = "7-day avg"), size = 1.2) +
    geom_line(aes(y = rolling_28d_distance, color = "28-day avg"), size = 1.2) +
    scale_color_manual(values = c("7-day avg" = "red", "28-day avg" = "blue")) +
    labs(
      title = "Training Load Over Time",
      subtitle = "Daily distance with 7-day and 28-day rolling averages",
      x = "Date",
      y = "Distance (km)",
      color = "Metric"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
}


generate_hr_zones_plot <- function(data) {
  hr_data <- data %>%
    filter(!is.na(average_heartrate))
  
  ggplot(hr_data, aes(x = average_heartrate)) +
    geom_histogram(binwidth = 5, fill = "coral", color = "black", alpha = 0.7) +
    labs(
      title = "Distribution of Average Heart Rates",
      x = "Average Heart Rate (bpm)",
      y = "Count"
    ) +
    theme_minimal()
}


generate_power_zones_plot <- function(data) {
  power_data <- data %>%
    filter(!is.na(weighted_average_power))
  
  ggplot(power_data, aes(x = weighted_average_power)) +
    geom_histogram(binwidth = 10, fill = "steelblue", color = "black", alpha = 0.7) +
    labs(
      title = "Distribution of Weighted Average Power",
      x = "Power (watts)",
      y = "Count"
    ) +
    theme_minimal()
}