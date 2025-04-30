library(ggplot2)
library(dplyr)
library(scales)
library(lubridate)




generate_weekly_summary_plot <- function(data, plot_theme, plot_colors) {
  full_summary <- data %>%
    mutate(week_start = as.Date(floor_date(start_date, unit = "week", week_start = 1))) %>%
    distinct(id, .keep_all = T) %>%
    group_by(week_start) %>%
    summarize(total_distance = sum(distance_miles, na.rm = T), .groups = "drop") %>%
    arrange(week_start)
  
  pp <- ggplot(data = full_summary, aes(x = week_start, y = total_distance)) +
    geom_smooth(
      mapping = aes(text = paste0( 
        "Date: ", format(after_stat(x), "%b %d, %Y"),
        "<br>Trend Miles: ", round(after_stat(y), 2),
        "<br>Upper Estimate: ", round(after_stat(ymax), 2),
        "<br>Lower Estimate: ", round(after_stat(ymin), 2))),
      method = "loess",
      formula = y ~ x,
      se = T,
      level = 0.90,
      linewidth = 0.7,
      color = plot_colors[6],
      fill = plot_colors[3]) +
    geom_col(
      mapping = aes(text = paste0(
        "Date: ", format(after_stat(x), "%b %d, %Y"),
        "<br>Total Miles: ", round(after_stat(y), 2))),
      fill = plot_colors[3], alpha = 0.85) +
    scale_y_continuous(name = "Distance (miles)") +
    scale_x_date(
      date_breaks = "2 weeks",
      limits = c(max(min(full_summary$week_start), full_summary$week_start - 365), 
                 max(full_summary$week_start)),
      labels = date_format("%b %d, %Y")) +
    labs(x = "Week Starting", y = NULL) +
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "text") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    config(displayModeBar = F)
  
  return(p)
}