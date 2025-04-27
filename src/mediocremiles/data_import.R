library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)


data_path <- "data/strava_data.json"



import_activity_data <- function() {
  raw_data <- fromJSON(data_path)
  activities <- raw_data$activities
  
  activities_list <- list()
  activity_names <- names(activities)
  
  for (activity_id in activity_names) {
    activity <- activities[[activity_id]]
    if (is.list(activity)) {
      # Extract non-list elements for activity metadata
      activity_meta <- activity[!sapply(activity, is.list)]
      
      # Handle weather data separately
      if (!is.null(activity$weather) && is.list(activity$weather)) {
        # Extract weather data and prefix column names
        weather_data <- activity$weather
        weather_df <- as.data.frame(t(unlist(weather_data)), stringsAsFactors = FALSE)
        names(weather_df) <- paste0("weather_", names(weather_df))
        
        # Remove weather from activity_meta to avoid duplication
        activity_meta$weather <- NULL
      } else {
        weather_df <- data.frame()
      }
      
      # Convert remaining metadata to dataframe
      activity_df <- as.data.frame(t(unlist(activity_meta)), stringsAsFactors = FALSE)
      
      # Combine with weather data if available
      if (ncol(weather_df) > 0) {
        activity_df <- cbind(activity_df, weather_df)
      }
      
      # Handle the splits separately
      if (!is.null(activity$splits_standard) && length(activity$splits_standard) > 0) {
        splits <- rbind(activity$splits_standard)
        
        splits$activity_id <- activity$id
        
        common_cols <- intersect(names(splits), names(activity_df))
        common_cols <- setdiff(common_cols, "activity_id")
        
        if (length(common_cols) > 0) {
          for (col in common_cols) {
            names(splits)[names(splits) == col] <- paste0("split_", col)
          }
        }
        
        for (i in 1:nrow(splits)) {
          repeated_activity <- activity_df[rep(1, 1), ]
          combined_df <- cbind(splits[i, ], repeated_activity)
          activities_list[[length(activities_list) + 1]] <- combined_df
        }
      } else {
        activity_df$activity_id <- activity$id
        activities_list[[length(activities_list) + 1]] <- activity_df
      }
    }
  }
  
  if (length(activities_list) > 0) {
    final_df <- bind_rows(activities_list)
  } else {
    return(data.frame())
  }
  
  if ("start_date" %in% names(final_df)) {
    final_df$start_date <- as.POSIXct(final_df$start_date, format="%Y-%m-%dT%H:%M:%S", tz = "UTC")
    final_df$date <- as.Date(final_df$start_date)
    final_df$year <- year(final_df$start_date)
    final_df$month <- month(final_df$start_date)
    final_df$week <- isoweek(final_df$start_date)
    final_df$weekday <- wday(final_df$start_date, label = TRUE)
  }
  
  numeric_cols <- c("total_distance_meters", "total_moving_time_seconds", 
                    "total_elapsed_time_seconds", "average_speed_meters_sec",
                    "average_speed_mph", "average_speed_kmh",
                    "max_speed_meters_sec", "average_heartrate", "max_heartrate",
                    "distance_miles", "distance_km", "average_cadence", "pr_count",
                    "kudos_count", "workout_type", "shoe_total_distance", "calories",
                    "start_lat", "start_lon", "end_lat", "end_lon", "perceived_exertion",
                    "suffer_score", "weighted_average_power", "distance", "elapsed_time",
                    "split_average_heartrate", "split_average_speed_kmh", "split_average_speed_mph",
                    "average_grade_adjusted_speed_kmh", "average_grade_adjusted_speed_mph",
                    "moving_time", "elevation_difference", "average_grade_adjusted_speed",
                    "weather_temperature", "weather_dew_point", "weather_humidity", 
                    "weather_pressure", "weather_wind_direction", "weather_wind_speed", 
                    "weather_precipitation", "weather_temperature_f", "weather_dew_point_f",
                    "weather_precipitation_inch", "weather_snow_inch", 
                    "elevation_gain_feet",
                    "weather_wind_speed_kmh", "weather_wind_speed_mph")
  
  for (col in numeric_cols) {
    if (col %in% names(final_df) && is.character(final_df[[col]])) {
      final_df[[col]] <- as.numeric(final_df[[col]])
    }
  }
  
  return(final_df)
}

import_athlete_zones <- function() {
  raw_data <- fromJSON(data_path)
  zones <- raw_data$zones
  return(zones)
}


import_athlete_stats <- function() {
  raw_data <- fromJSON(data_path)
  stats <- raw_data$stats
  return(stats)
}
