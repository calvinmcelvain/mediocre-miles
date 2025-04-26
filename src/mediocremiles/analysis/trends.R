library(ggplot2)
library(dplyr)
library(lubridate)



generate_performance_trends_plot <- function(data) {
  run_data <- data %>%
    filter(activity_type == "Run") %>%
    mutate(
      pace_min_per_km = moving_time_hours * 60 / distance_km,
      distance_binned = cut(distance_km, 
                           breaks = c(0, 5, 10, 15, 20, 100),
                           labels = c("0-5km", "5-10km", "10-15km", "15-20km", "20km+"))
    ) %>%
    filter(!is.na(pace_min_per_km), pace_min_per_km < 10)
  
  ggplot(run_data, aes(x = start_date, y = pace_min_per_km)) +
    geom_point(aes(color = distance_binned, size = distance_km), alpha = 0.7) +
    geom_smooth(method = "loess", color = "black") +
    scale_y_reverse() +
    scale_color_brewer(palette = "Set1") +
    labs(
      title = "Running Performance Trend",
      subtitle = "Pace over time (lower is better)",
      x = "Date",
      y = "Pace (min/km)",
      color = "Distance",
      size = "Distance (km)"
    ) +
    theme_minimal() +
    theme(legend.position = "right")
}


generate_seasonal_patterns_plot <- function(data) {
  monthly_stats <- data %>%
    mutate(month = month(start_date, label = TRUE)) %>%
    group_by(month) %>%
    summarize(
      avg_distance = mean(distance_km, na.rm = TRUE),
      avg_time = mean(moving_time_hours, na.rm = TRUE),
      avg_elevation = mean(total_elevation_gain_meters, na.rm = TRUE) / 100,
      activity_count = n(),
      .groups = "drop"
    )
  
  ggplot(monthly_stats, aes(x = month)) +
    geom_bar(aes(y = avg_distance, fill = "Avg Distance"), stat = "identity", alpha = 0.7) +
    geom_line(aes(y = avg_elevation, color = "Avg Elevation/100m"), group = 1, size = 1.5) +
    geom_point(aes(y = avg_elevation), color = "red", size = 3) +
    scale_fill_manual(values = c("Avg Distance" = "steelblue")) +
    scale_color_manual(values = c("Avg Elevation/100m" = "red")) +
    labs(
      title = "Seasonal Activity Patterns",
      x = "Month",
      y = "Average Distance (km)",
      fill = NULL,
      color = NULL
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
}


generate_yoy_comparison_plot <- function(data) {
  yoy_data <- data %>%
    mutate(
      year = year(start_date),
      month = month(start_date),
      date_key = paste(month, format(start_date, "%d"), sep = "-")
    ) %>%
    filter(year >= year(Sys.Date()) - 3) %>% 
    group_by(year, date_key) %>%
    summarize(
      daily_distance = sum(distance_km, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(year, date_key) %>%
    group_by(year) %>%
    mutate(cumulative_distance = cumsum(daily_distance)) %>%
    ungroup()
  
  ggplot(yoy_data, aes(x = date_key, y = cumulative_distance, color = factor(year), group = year)) +
    geom_line(size = 1.2) +
    scale_color_brewer(palette = "Set1") +
    labs(
      title = "Year-over-Year Cumulative Distance",
      x = "Date (Month-Day)",
      y = "Cumulative Distance (km)",
      color = "Year"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 90, hjust = 1, size = 8)
    )
}