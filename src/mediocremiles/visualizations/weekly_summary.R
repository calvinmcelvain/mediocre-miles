library(ggplot2)
library(dplyr)
library(lubridate)




generate_weekly_summary_plot <- function(data) {
  weekly_summary <- data %>%
    mutate(week_start = floor_date(as.Date(start_date), "week")) %>%
    group_by(week_start) %>%
    summarize(
      total_distance = sum(distance_km, na.rm = TRUE),
      total_hours = sum(moving_time_hours, na.rm = TRUE),
      activity_count = n(),
      .groups = "drop"
    ) %>%
    arrange(week_start) %>%
    tail(12)
  
  ggplot(weekly_summary, aes(x = week_start)) +
    geom_bar(aes(y = total_distance, fill = "Distance"), stat = "identity", alpha = 0.7) +
    geom_line(aes(y = total_hours * 10, color = "Time"), size = 1.5) +
    geom_point(aes(y = total_hours * 10), color = "red", size = 3) +
    scale_y_continuous(
      name = "Distance (km)",
      sec.axis = sec_axis(~./10, name = "Time (hours)")
    ) +
    scale_fill_manual(values = c("Distance" = "steelblue")) +
    scale_color_manual(values = c("Time" = "red")) +
    labs(
      title = "Weekly Training Summary (Last 12 Weeks)",
      x = "Week Starting",
      fill = NULL,
      color = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
}