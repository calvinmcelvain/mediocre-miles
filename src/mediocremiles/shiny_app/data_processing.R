#
# R/data/data_processing.R - Functions for processing Strava data
#


calculate_training_load <- function(activities) {
  required_cols <- c("id", "start_date", "distance_km", "total_moving_time_seconds")
  if (!all(required_cols %in% names(activities))) {
    missing <- setdiff(required_cols, names(activities))
    warning("Missing columns for training load calculation: ", 
            paste(missing, collapse = ", "))
    return(activities)
  }
  
  load_data <- activities %>%
    group_by(id) %>%
    slice(1) %>%
    ungroup() %>%
    mutate(
      date = as.Date(start_date),
      training_load = distance_km * (total_moving_time_seconds / 3600),
      intensity_factor = case_when(
        !is.na(average_heartrate) ~ scale_to_range(average_heartrate, 0.7, 1.2),
        TRUE ~ 1.0
      ),
      weighted_load = training_load * intensity_factor
    ) %>%
    arrange(date)
  
  if (nrow(load_data) > 0) {
    load_data$rolling_load <- zoo::rollmean(load_data$training_load, 
                                           k = 7, 
                                           fill = NA, 
                                           align = "right")
    
    load_data$rolling_weighted_load <- zoo::rollmean(load_data$weighted_load, 
                                                   k = 7, 
                                                   fill = NA, 
                                                   align = "right")
  }
  
  return(load_data)
}


calculate_hr_zones <- function(activities, zones = NULL) {
  if (!("average_heartrate" %in% names(activities))) {
    warning("No heart rate data available")
    return(activities)
  }
  
  hr_data <- activities %>%
    group_by(id) %>%
    slice(1) %>%
    ungroup() %>%
    filter(!is.na(average_heartrate))
  
  if (is.null(zones)) {
    hr_data <- hr_data %>%
      mutate(hr_zone = case_when(
        average_heartrate < 125 ~ "Zone 1: Recovery",
        average_heartrate < 140 ~ "Zone 2: Aerobic",
        average_heartrate < 155 ~ "Zone 3: Tempo",
        average_heartrate < 170 ~ "Zone 4: Threshold",
        TRUE ~ "Zone 5: Maximum"
      ))
  } else {
  }
  return(hr_data)
}


calculate_power_zones <- function(activities, zones = NULL) {
  if (!("weighted_average_power" %in% names(activities))) {
    warning("No power data available")
    return(activities)
  }
  
  power_data <- activities %>%
    group_by(id) %>%
    slice(1) %>%
    ungroup() %>%
    filter(!is.na(weighted_average_power))
  
  if (is.null(zones)) {
    power_data <- power_data %>%
      mutate(power_zone = case_when(
        weighted_average_power < 150 ~ "Zone 1: Recovery",
        weighted_average_power < 200 ~ "Zone 2: Endurance",
        weighted_average_power < 250 ~ "Zone 3: Tempo",
        weighted_average_power < 300 ~ "Zone 4: Threshold",
        weighted_average_power < 350 ~ "Zone 5: VO2 Max",
        TRUE ~ "Zone 6: Anaerobic"
      ))
  } else {
  }
  
  return(power_data)
}


aggregate_by_week <- function(activities) {
  if (!all(c("id", "start_date") %in% names(activities))) {
    warning("Missing required columns for weekly aggregation")
    return(data.frame())
  }
  
  weekly_data <- activities %>%
    group_by(id) %>%
    slice(1) %>%
    ungroup() %>%
    mutate(week = floor_date(as.Date(start_date), "week")) %>%
    group_by(week) %>%
    summarize(
      activity_count = n(),
      total_distance_km = sum(distance_km, na.rm = T),
      total_distance_miles = sum(distance_miles, na.rm = T),
      total_duration_hours = sum(total_moving_time_seconds / 3600, na.rm = T),
      avg_heartrate = mean(average_heartrate, na.rm = T),
      avg_speed_kmh = mean(average_speed_kmh, na.rm = T),
      avg_speed_mph = mean(average_speed_mph, na.rm = T),
      .groups = "drop"
    )
  
  return(weekly_data)
}


scale_to_range <- function(x, min_val = 0, max_val = 1, na.rm = T) {
  if (length(x) == 1) {
    return((min_val + max_val) / 2)
  }
  
  x_min <- min(x, na.rm = na.rm)
  x_max <- max(x, na.rm = na.rm)
  
  if (x_min == x_max) {
    return(rep((min_val + max_val) / 2, length(x)))
  }
  
  x_scaled <- (x - x_min) / (x_max - x_min)
  
  return(min_val + x_scaled * (max_val - min_val))
}