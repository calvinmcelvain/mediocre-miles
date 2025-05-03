#
# src/mediocremiles/shiny_app/visualizations/training.R - Training visualizations.
#


generate_training_load_plot <- function(data, plot_theme, plot_colors) {
  training_load <- data %>%
    distinct(id, .keep_all = T) %>%
    arrange(start_date) %>%
    mutate(date = as.Date(start_date)) %>%
    group_by(date) %>%
    summarize(
      daily_distance = sum(distance_miles, na.rm = T),
      daily_time = sum(moving_time_hours, na.rm = T),
      .groups = "drop")
  
  training_load <- training_load %>%
    mutate(date = as.Date(date)) %>%
    arrange(date) %>%
    mutate(
      rolling_7d_distance = rollmean(daily_distance, 7, fill = NA, align = "right"),
      rolling_28d_distance = rollmean(daily_distance, 28, fill = NA, align = "right"),
      acute_chronic_ratio = rolling_7d_distance / rolling_28d_distance)
  
  pp <- ggplot(training_load, aes(x = date)) +
    geom_bar(aes(y = daily_distance, text = paste0( 
      "Date: ", format(after_stat(x), "%b %d, %Y"),
      "<br>Miles: ", round(after_stat(y), 2))), 
      stat = "identity", fill = plot_colors[6], alpha = 0.3) +
    geom_line(aes(y = rolling_7d_distance, color = "7-day avg", text = paste0( 
      "Date: ", format(after_stat(x), "%b %d, %Y"),
      "<br>7-Day Trend: ", round(after_stat(y), 2))), linewidth = 0.9) +
    geom_line(aes(y = rolling_28d_distance, color = "28-day avg", text = paste0( 
      "Date: ", format(after_stat(x), "%b %d, %Y"),
      "<br>28-Day Trend: ", round(after_stat(y), 2))), linewidth = 0.9) +
    scale_color_manual(values = c("7-day avg" = plot_colors[3], "28-day avg" = plot_colors[2])) +
    scale_x_date(limits = c(max(min(training_load$date), training_load$date - 720), 
                            max(training_load$date))) +
    labs(x = NULL, y = "Distance (miles)", color = "Trend") +
    plot_theme +
    theme(legend.position = "bottom")
  
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



generate_hr_zones_plot <- function(data, plot_theme, plot_colors) {
  activities_summary <- data %>%
    distinct(id, .keep_all = T) %>%
    filter(distance_miles > 0)
  
  
  pp <- ggplot(activities_summary, aes(x = date, y = distance_miles)) +
    geom_point(aes(
      size = distance_miles * 1.5,
      color = average_heartrate,
      text = paste(
        "Activity: ", name,
        "<br>Date: ", date,
        "<br>Distance: ", round(distance_miles, 2), "miles",
        "<br>Time: ", round(moving_time_minutes, 1), "min",
        "<br>Avg HR: ", round(average_heartrate, 1), "bpm",
        "<br>Elevation: ", round(elevation_gain_feet, 1), "feet")), alpha = 0.8) +
    scale_color_viridis_c(name = "Avg HR (bpm)", option = "viridis") +
    guides(color = "none") +
    labs(x = NULL, y = "Distance (miles)") +
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


generate_power_zones_plot <- function(data, plot_theme, plot_colors) {
  power_data <- data %>%
    distinct(id, .keep_all = T) %>%
    filter(!is.na(weighted_average_power)) %>%
    filter(average_heartrate > 100)
  
  pp <- ggplot(power_data, aes(x = average_heartrate, y = weighted_average_power)) +
    geom_jitter(mapping = aes(text = paste0(
      "Heartrate: ", round(average_heartrate, 2), " bpm",
      "<br>Speed: ", round(weighted_average_power, 2), " mph"
    )), height = 0.5, color = plot_colors[4], alpha = 0.8, size = 1) +
    geom_smooth(se = T, fill = plot_colors[4], color = "black") + 
    guides(fill = "none") +
    labs(x = "Average Heart Rate (bpm)", 
         y = "Average Power (watts)",
         fill = NULL) +
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


generate_training_summary_plot <- function(data, plot_theme, plot_colors) {
  weekly_load <- data %>%
    distinct(id, .keep_all = T) %>%
    mutate(
      week = floor_date(as.Date(start_date), "week"),
      load = distance_km * (total_moving_time_seconds / 3600)) %>%
    group_by(week) %>%
    summarize(
      weekly_load = sum(load, na.rm = T),
      .groups = "drop")
  
  pp <- ggplot(weekly_load, aes(x = week, y = weekly_load)) +
    geom_bar(mapping = aes(text = paste0(
      "Date: ", after_stat(x),
      "<br>Trainging Load: ", round(after_stat(y), 2)
    )), stat = "identity", fill = plot_colors[2], alpha = 0.7) +
    geom_line(mapping = aes(group = 1, text = paste0(
      "Date: ", after_stat(x),
      "<br>Trainging Load: ", round(after_stat(y), 2)
    )), color = plot_colors[5], linewidth = 0.9) +
    labs(x = NULL, y = "Training Load") +
    plot_theme +
    scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d",
                 limits = c(max(min(weekly_load$week), weekly_load$week - 720), 
                            max(weekly_load$week))) +
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


generate_radar_plot <- function(data, plot_theme, plot_colors) {
  data <- data %>%
    mutate(split_category = case_when(
      split <= 6 ~ "Short",
      split > 6 & split <= 12 ~ "Medium",
      split > 12 ~ "Long"
    )) %>%
    drop_na(split_category)
  hr_radar_data <- data %>%
    group_by(split_category) %>%
    summarize(
      avg_hr = mean(split_average_heartrate, na.rm = T),
      avg_cadence = mean(average_cadence, na.rm = T),
      avg_pace = mean(split_average_speed_mph, na.rm = T),
      avg_elevation = mean(split_elevation_difference_ft, na.rm = T),
      efficiency = mean(split_average_speed_mph / split_average_heartrate, na.rm = T),
      run_count = n(),
      .groups = "drop") %>%
    mutate(
      hr_norm = rescale(avg_hr, to = c(0.1, 1)),
      cadence_norm = rescale(avg_cadence, to = c(0.1, 1)),
      pace_norm = rescale(-avg_pace, to = c(0.1, 1)),
      elev_norm = rescale(avg_elevation, to = c(0.1, 1)),
      eff_norm = rescale(-efficiency, to = c(0.1, 1)),
      count_norm = rescale(run_count, to = c(0.3, 1))) %>%
    select(split_category, 
           "Heart Rate" = hr_norm, 
           "Speed" = pace_norm, 
           "Cadence" = cadence_norm,
           "Efficiency" = eff_norm,
           "Elevation" = elev_norm,
           "Frequency" = count_norm) %>%
    pivot_longer(cols = -split_category,
                 names_to = "metric",
                 values_to = "value")
  
  metrics <- c(
    "Heart Rate", "Speed", "Cadence", "Efficiency", "Elevation", "Frequency")
  n_metrics <- length(metrics)
  
  radar_data_complete <- expand.grid(
    split_category = unique(data$split_category),
    metric = metrics, stringsAsFactors = F) %>%
    arrange(split_category, factor(metric, levels = metrics)) %>%
    left_join(hr_radar_data,
              by = c("split_category", "metric"))
  
  radar_coords <- radar_data_complete %>%
    group_by(split_category) %>%
    mutate(
      angle = match(metric, metrics) * 2 * pi / n_metrics,
      x = value * sin(angle),
      y = value * cos(angle),
      id = row_number())
  
  axis_coords <- data.frame(
    metric = metrics,
    angle = seq(1, n_metrics) * 2 * pi / n_metrics,
    stringsAsFactors = F) %>%
    mutate(
      x_end = sin(angle),
      y_end = cos(angle),
      label_x = 1.15 * sin(angle),
      label_y = 1.15 * cos(angle))
  
  
  ggplot() +
    geom_circle(aes(x0 = 0, y0 = 0, r = 0.25), color = "grey80", fill = NA) +
    geom_circle(aes(x0 = 0, y0 = 0, r = 0.5), color = "grey80", fill = NA) +
    geom_circle(aes(x0 = 0, y0 = 0, r = 0.75), color = "grey80", fill = NA) +
    geom_circle(aes(x0 = 0, y0 = 0, r = 1.0), color = "grey80", fill = NA) +
    geom_segment(data = axis_coords,
                 aes(x = 0, y = 0, xend = x_end, yend = y_end),
                 color = "grey70", linetype = "dashed") +
    geom_text(data = axis_coords,
              aes(x = label_x, y = label_y, label = metric),
              fontface = "bold") +
    geom_polygon(data = radar_coords %>%
                   group_by(split_category) %>%
                   mutate(orig_id = id) %>%
                   do(bind_rows(., 
                                filter(., id == min(.$id)) %>% 
                                  mutate(id = max(.$id) + 1))) %>%
                   ungroup(),
                 aes(x = x, y = y, group = split_category, fill = split_category),
                 alpha = 0.2) +
    geom_path(data = radar_coords %>%
                group_by(split_category) %>%
                do(bind_rows(., 
                             filter(., id == min(.$id)) %>% 
                               mutate(id = max(.$id) + 1))) %>%
                ungroup(),
              aes(x = x, y = y, group = split_category, color = split_category),
              size = 1) +
    geom_point(data = radar_coords,
               aes(x = x, y = y, color = split_category),
               size = 3) +
    scale_fill_manual(values = plot_colors[c(2,3,5)]) +
    scale_color_manual(values = plot_colors[c(2,3,5)]) +
    coord_equal(clip = "off") +
    theme_void() +
    labs(x = NULL, y = NULL) +
    plot_theme +
    theme(axis.text = element_blank(),axis.title = element_blank(),
      axis.ticks = element_blank()) + 
    labs(fill = "Distance Category", color = "Distance Category")
}
