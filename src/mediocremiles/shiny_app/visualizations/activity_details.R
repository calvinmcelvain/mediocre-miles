#
# src/mediocremiles/shiny_app/visualizations/activity_details - Activity details plot.
#

library(ggplot2)
library(dplyr)
library(lubridate)



generate_activity_details_plot <- function(data, plot_theme) {
  monthly_time <- data %>%
    mutate(month_year = format(as.Date(start_date), "%Y-%m")) %>%
    distinct(id, .keep_all = T) %>%
    group_by(month_year, activity_type) %>%
    summarize(total_time = sum(total_elapsed_time_seconds / 3600, na.rm = T),
              .groups = "drop") %>%
    arrange(month_year)
  
  pp <- ggplot(monthly_time, aes(x = month_year, y = total_time, fill = activity_type)) +
    geom_bar(stat = "identity", aes(text = paste0(
      "Month: ", month_year,
      "<br>Activity: ", activity_type,
      "<br>Total Time (hours): ", round(total_time, 2)))) +
    labs(x = "Month", y = "Time (hours)", fill = "Activity Type") +
    scale_fill_viridis_d(option = "viridis") +
    plot_theme +
    guides(fill = "none") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "closest") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    config(displayModeBar = F)
  
  return(p)
}
