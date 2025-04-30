library(ggplot2)
library(dplyr)
library(scales)
library(lubridate)




generate_weekly_summary_plot <- function(data, plot_theme, plot_colors) {
  full_summary <- data %>%
    mutate(week_start = as.Date(floor_date(start_date, unit = "week", week_start = 1))) %>%
    distinct(id, .keep_all = T) %>%
    group_by(week_start) %>%
    summarize(
      total_distance = sum(distance_miles, na.rm = T),
      .groups = "drop"
    ) %>%
    arrange(week_start)
  
  pp <- ggplot(data = full_summary, aes(x = week_start, y = total_distance)) +
    geom_smooth(
      full_summary,
      mapping = aes(
        text = paste0(
          "Week: ", format(after_stat(x), "%b %d, %Y"),
          "<br>Trend: ", round(after_stat(y), 2), " mi",
          "<br>90% CI: [", round(after_stat(ymin), 2), ", ", 
          round(after_stat(ymax), 2), "] mi")),
      method = "loess",
      formula = y ~ x,
      se = T,
      linewidth = 0.8,
      color = plot_colors[6],
      fill = plot_colors[3],
      level = 0.90) +
    geom_col(
      full_summary,
      mapping = aes(
        text = paste0(
          "Week: ", format(after_stat(x), "%b %d, %Y"),
          "<br>Distance: ", round(after_stat(y), 2), " mi")),
      fill = plot_colors[3],
      alpha = 0.85
    ) +
    scale_y_continuous(name = "Distance (miles)") +
    scale_x_date(
      date_breaks = "2 weeks",
      limits = c(max(min(full_summary$week_start), full_summary$week_start - 365), 
                 max(full_summary$week_start)),
      labels = date_format("%b %d, %Y")) +
    labs(
      x = "Week Starting",
      y = NULL) +
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "x unified", hoverlabel = list(bgcolor = "white"))
  
  return(p)
}
