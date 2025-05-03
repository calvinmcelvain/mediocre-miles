#
# src/mediocremiles/shiny_app/visualizations/trends.R - Trend visualizations.
#



generate_pace_trend_plot <- function(data, plot_theme, plot_colors) {
  data$split_pace_min_mile <- 60 / data$split_average_speed_mph
  filtered_trend_data <- data %>% filter(activity_type == "Run")
  
  pp <- ggplot(filtered_trend_data, aes(x = date, y = split_pace_min_mile)) +
    geom_jitter(aes(text = paste0(
      "Date: ", after_stat(x),
      "<br>Pace: ", round(after_stat(y), 2), " min/mile"
    )), height = 0.2, width = 0.5, alpha = 0.7, color = plot_colors[6]) +
    geom_smooth(method = "loess", color = plot_colors[3], fill = plot_colors[3], se = T, level = 0.99) +
    labs(x = NULL, y = "Pace (min/mile)") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
    scale_y_continuous(limits = c(4, 10)) + 
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "closest") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    layout(font = list(family = "monospace")) %>%
    layout(legend = list(
      orientation = "h", 
      y = -0.3,
      x = 0.5, 
      xanchor = "center",
      font = list(family = "monospace", size = 12, color = "black", weight = "bold")
    )) %>%
    layout(margin = list(b = 120)) %>%
    config(displayModeBar = F)
  
  return(p)
}



generate_hr_trend_plot <- function(data, plot_theme) {
  filtered_trend_data <- data %>% distinct(id, .keep_all = T)
  
  pp <- ggplot(filtered_trend_data, aes(x = date, y = average_heartrate)) +
    geom_jitter(aes(text = paste0(
      "Date: ", date,
      "<br>Activity: ", activity_type,
      "<br>Heart Rate: ", round(average_heartrate, 2), " bpm"
    ), color = activity_type), width = 0.5, alpha = 0.7) +
    geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
    scale_color_wsj() +
    scale_fill_wsj() +
    labs(x = NULL,  y = "Heart Rate (bpm)", color = "Activity Type", fill = "Activity Type") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "closest") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    layout(font = list(family = "monospace")) %>%
    layout(legend = list(
      orientation = "h", 
      y = -0.3,
      x = 0.5, 
      xanchor = "center",
      font = list(family = "monospace", size = 12, color = "black", weight = "bold")
    )) %>%
    layout(margin = list(b = 120)) %>%
    config(displayModeBar = F)
  
  return(p)
}


generate_distance_trend_plot <- function(data, plot_theme) {
  trend_data_filtered <- data %>%
    distinct(id, .keep_all = T) %>%
    filter(distance_miles > 1)
  
  pp <- ggplot(trend_data_filtered, aes(x = date, y = distance_miles)) +
    geom_jitter(aes(text = paste0(
      "Date: ", date,
      "<br>Activity: ", activity_type,
      "<br>Distance: ", round(distance_miles, 2), " miles"
    ), color = activity_type), width = 0.5, alpha = 0.7) +
    geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
    scale_color_wsj() +
    scale_fill_wsj() +
    guides(color = "none") +
    labs(x = NULL,  y = "Distance (miles)", color = "Activity Type", fill = "Activity Type") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
    plot_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "closest") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    layout(font = list(family = "monospace")) %>%
    layout(legend = list(
      orientation = "h", 
      y = -0.3,
      x = 0.5, 
      xanchor = "center",
      font = list(family = "monospace", size = 12, color = "black", weight = "bold")
    )) %>%
    layout(margin = list(b = 120)) %>%
    config(displayModeBar = F)
  
  return(p)
}


generate_seasonal_patterns_plot <- function(data, plot_theme, plot_colors) {
  monthly_stats <- data %>%
    mutate(month = month(start_date, label = T)) %>%
    distinct(id, .keep_all = T) %>%
    group_by(month) %>%
    summarize(
      avg_distance = mean(distance_miles, na.rm = T),
      avg_time = mean(moving_time_hours, na.rm = T),
      avg_elevation = mean(elevation_gain_feet, na.rm = T),
      activity_count = n(),
      .groups = "drop")
  
  pp <- ggplot(monthly_stats, aes(x = month)) +
    geom_line(aes(y = avg_elevation, color = "Avg Elevation (feet)", text = paste0(
      "Month: ", month,
      "<br>Average Elevation Gain: ", round(avg_elevation, 2), " feet"
    )), group = 1, linewidth=1) +
    geom_bar(aes(y = avg_distance * 10, fill = "Avg Distance (miles)", text = paste0(
      "Month: ", month,
      "<br>Average Distance: ", round(avg_distance, 2), " miles"
    )), stat = "identity", alpha = 0.9) +
    scale_fill_manual(values = c("Avg Distance (miles)" = plot_colors[4])) +
    scale_color_manual(values = c("Avg Elevation (feet)" = plot_colors[1])) +
    scale_y_continuous(
      name = "Avg Elevation (feet)",
      sec.axis = sec_axis(~./10, name = "Avg Distance (miles)")) +
    labs(x = NULL, fill = NULL, color = NULL) +
    guides(color = "none") +
    plot_theme
  
  p <- ggplotly(pp, tooltip = "text") %>%
    layout(hovermode = "closest") %>%
    layout(hoverlabel = list(bgcolor = "white")) %>%
    layout(xaxis = list(fixedrange = T), yaxis = list(fixedrange = T)) %>%
    layout(font = list(family = "monospace")) %>%
    layout(legend = list(
      orientation = "h", 
      y = -0.3,
      x = 0.5, 
      xanchor = "center",
      font = list(family = "monospace", size = 12, color = "black", weight = "bold")
    )) %>%
    layout(margin = list(b = 120)) %>%
    config(displayModeBar = F)
  
  return(p)
}


generate_yoy_comparison_plot <- function(data, plot_theme) {
  ggplot(data,
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
}
