#
# src/mediocremiles/shiny_app/visualizations/activity_distribution.R - Activity distribution plot.
#

library(dplyr)
library(ggplot2)



generate_activity_distribution_plot <- function(data, plot_theme) {
  activity_counts <- data %>%
    count(activity_type) %>%
    arrange(desc(n))
  
  p <- ggplot(activity_counts, aes(x = "", y = n, fill = activity_type)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    scale_fill_wsj() +
    labs(fill = "Activity Type") +
    plot_theme
  
  return(p)
}