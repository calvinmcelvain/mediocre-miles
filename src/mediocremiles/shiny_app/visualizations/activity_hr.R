#
# src/mediocremiles/shiny_app/visualizations/activity_hr - Activity HR plot.
#



generate_activity_hr_plot <- function(data, plot_theme, plot_colors) {
  activity_counts <- data %>%
    count(activity_type) %>%
    filter(n >= 20)
  
  hr_data <- data %>%
    filter(activity_type %in% activity_counts$activity_type) %>%
    distinct(id, .keep_all = T) %>%
    mutate(pace_min_mile = 60 / average_speed_mph)
  
  hr_data <- hr_data %>%
    group_by(activity_type) %>%
    mutate(
      q1_pace = quantile(pace_min_mile, 0.25, na.rm = T),
      q3_pace = quantile(pace_min_mile, 0.75, na.rm = T),
      iqr_pace = q3_pace - q1_pace,
      pace_lower_bound = q1_pace - 1.5 * iqr_pace,
      pace_upper_bound = q3_pace + 1.5 * iqr_pace) %>%
    filter(
      pace_min_mile >= pace_lower_bound & pace_min_mile <= pace_upper_bound) %>%
    select(-starts_with("q"), -starts_with("iqr"), -ends_with("bound")) %>%
    ungroup()
  
  p <- ggplot(hr_data, aes(x = pace_min_mile, y = average_heartrate)) +
    geom_point(aes(color = activity_type), alpha = 0.9) +
    scale_fill_viridis_d(option = "viridis") +
    geom_smooth(method = "lm", se = T, color = plot_colors[10], fill = plot_colors[10]) +
    labs(x = "Pace (min/mile)", y = "Heart Rate (bpm)") +
    plot_theme +
    scale_x_continuous(labels = function(x) sprintf("%.1f", x))
  
  return(p)
}