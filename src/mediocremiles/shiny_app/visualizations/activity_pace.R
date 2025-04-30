#
# src/mediocremiles/shiny_app/visualizations/activity_pace.R - Activity pace plot.
#




generate_activity_pace_plot <- function(data, plot_theme, plot_colors) {
  activity_counts <- data %>%
    count(activity_type) %>%
    filter(n >= 20)
  
  pace_data <- data %>%
    filter(activity_type %in% activity_counts$activity_type) %>%
    distinct(id, .keep_all = T) %>%
    mutate(pace_min_miles = 60 / average_speed_mph)
  
  pace_data <- pace_data %>%
    group_by(activity_type) %>%
    mutate(
      q1_pace = quantile(pace_min_miles, 0.25, na.rm = T),
      q3_pace = quantile(pace_min_miles, 0.75, na.rm = T),
      iqr_pace = q3_pace - q1_pace,
      pace_lower_bound = q1_pace - 1.5 * iqr_pace,
      pace_upper_bound = q3_pace + 1.5 * iqr_pace,
      q1_dist = quantile(distance_miles, 0.25, na.rm = T),
      q3_dist = quantile(distance_miles, 0.75, na.rm = T),
      iqr_dist = q3_dist - q1_dist,
      dist_lower_bound = q1_dist - 1.5 * iqr_dist,
      dist_upper_bound = q3_dist + 1.5 * iqr_dist) %>%
    filter(
      pace_min_miles >= pace_lower_bound & pace_min_miles <= pace_upper_bound &
        distance_miles >= dist_lower_bound & distance_miles <= dist_upper_bound) %>%
    select(-starts_with("q"), -starts_with("iqr"), -ends_with("bound")) %>%
    ungroup()
  
  p <- ggplot(pace_data, aes(x = distance_miles, y = pace_min_miles)) +
    geom_point(aes(color = activity_type), alpha = 0.9) +
    scale_fill_viridis_d(option = "viridis") +
    geom_smooth(method = "loess", se = T, color = plot_colors[15], 
                fill = plot_colors[15], formul = y ~ x) +
    labs(x = "Distance (miles)", y = "Pace (min/mile)") +
    plot_theme +
    guides(color = "none")
    scale_y_continuous(labels = function(x) sprintf("%.1f", x))
  
  return(p)
}