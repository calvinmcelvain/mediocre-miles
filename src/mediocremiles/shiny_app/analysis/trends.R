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


generate_seasonal_patterns_plot <- function(data, plot_theme, plot_colors) {
  monthly_stats <- data %>%
    mutate(month = month(start_date, label = T)) %>%
    distinct(id, .keep_all = T) %>%
    group_by(month) %>%
    summarize(
      avg_distance = mean(distance_miles, na.rm = T),
      avg_time = mean(moving_time_hours, na.rm = T),
      avg_elevation = mean(total_distance_meters, na.rm = T),
      activity_count = n(),
      .groups = "drop"
    )
  
  ggplot(monthly_stats, aes(x = month)) +
    geom_line(aes(y = avg_elevation, color = "Avg Elevation/100m"), group = 1, linewidth=1) +
    geom_bar(aes(y = avg_distance * 1000, fill = "Avg Distance"), stat = "identity", alpha = 0.9) +
    scale_fill_manual(values = c("Avg Distance" = plot_colors[4])) +
    scale_color_manual(values = c("Avg Elevation/100m" = plot_colors[1])) +
    scale_y_continuous(
      name = "Avg Elevation/100m",
      sec.axis = sec_axis(~./100, name = "Avg Distance")) +
    labs(
      x = NULL,
      fill = NULL,
      color = NULL) +
    guides(color = "none") +
    plot_theme
}


generate_yoy_comparison_plot <- function(data, plot_theme) {
  p <- ggplot(outliers_removed,
         aes(x = average_speed_mph, y = factor(year), fill = factor(year)),
         alpha = 0.5) +
    geom_density_ridges(
      aes(height = after_stat(density)),
      stat = "density",
      scale = 2, 
      alpha = 0.7) +
    scale_fill_wsj(name = "Pace (min/mile)") +
    coord_cartesian(xlim = c(
      quantile(data$split_average_speed_mph, 0.05, na.rm = T),
      quantile(data$split_average_speed_mph, 0.95, na.rm = T))) +
    labs(x = "Pace (mph)", y = "Year") +
    plot_theme
  return(p)
}