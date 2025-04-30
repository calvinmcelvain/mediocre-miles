#
# src/mediocremiles/shiny_app/visualizations/activity_distribution.R - Activity distribution plot.
#

library(dplyr)
library(ggplot2)



generate_activity_distribution_plot <- function(data, plot_theme) {
  activity_counts <- data %>%
    count(activity_type, name = "count") %>%
    arrange(desc(count)) %>%
    mutate(
      prop = count / sum(count) * 100,
      ypos = cumsum(prop) - 0.5 * prop)
  
  p <- ggplot(activity_counts, aes(x = "", y = prop, fill = activity_type)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar(theta = "y", start = 0) +
    scale_fill_viridis_d(option = "viridis") +
    labs(fill = "Activity Type") +
    theme_void()
  
  return(p)
}