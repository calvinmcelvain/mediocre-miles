library(ggplot2)
library(dplyr)
library(lubridate)




generate_weekly_summary_plot <- function(data, plot_theme, plot_colors) {
  weekly_summary <- data %>%
    mutate(week_start = floor_date(start_date, unit = "week", week_start = 1)) %>%
    distinct(id, .keep_all = TRUE) %>%
    group_by(week_start) %>%
    summarize(
      total_distance = sum(distance_miles, na.rm = T),
      total_hours = sum(as.numeric(moving_time_hours), na.rm = T),
      activity_count = n(),
      .groups = "drop"
    ) %>%
    arrange(week_start) %>%
    tail(12)
  
  p <- ggplot(data = weekly_summary, aes(x = week_start)) +
    geom_smooth(
      aes(
        y = total_distance * 1.45, 
        color = "Time (hours)", 
        fill = "Time (hours)"
      ), 
      method = "loess", se = TRUE, size = 1, level = 0.90) +
    geom_col(
      aes(y = total_distance, fill = "Distance (miles)"), 
      alpha = 0.85) +
    geom_text(
      aes(
        y = total_distance,
        label = paste0(round(total_distance, 1), " mi")
      ),
      vjust = -0.5,
      size = 5,
      color = "black",
      family = "mono",
      fontface = "bold") +
    scale_fill_manual(values = c("Distance (miles)" = plot_colors[3])) +
    scale_color_manual(values = c("Time (hours)" = plot_colors[6])) +
    scale_y_continuous(
      name = "Distance (miles)",
      sec.axis = sec_axis(~./1.45)) +
    guides(fill = "none", color = "none") +
    labs(
      x = "Week Starting",
      y = NULL,
      fill = NULL,
      color = NULL
    ) +
    plot_theme
  
  return(p)
}