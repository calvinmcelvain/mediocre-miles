#
# src/mediocremiles/shiny_app/data_import.R - Imports & processes data
#

library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)


process_strava_data <- function(data_path) {
  if (!file.exists(data_path)) {
    stop("Data file not found: ", data_path)
  }
  
  tryCatch({
    raw_data <- fromJSON(data_path)
    
    activities_df <- process_activities(raw_data$activities)
    hr_zones_df <- process_zones(raw_data$zones$heart_rate_zones)
    power_zones_df <- process_zones(raw_data$zones$power_zones)
    stats_df <- process_athlete_stats(raw_data$stats)
    
    return(list(
      activities = activities_df,
      heart_rate_zones = hr_zones_df,
      power_zones = power_zones_df,
      stats = stats_df
    ))
  }, error = function(e) {
    stop("Error processing Strava data: ", e$message)
  })
}



process_activities <- function(activities) {
  if (length(activities) == 0) return(data.frame())
  
  result_rows <- list()
  
  for (activity_id in names(activities)) {
    activity <- activities[[activity_id]]
    
    if (!is.list(activity)) next
    
    activity_data <- activity[!sapply(activity, is.list)]
    activity_df <- as.data.frame(t(unlist(activity_data)), stringsAsFactors = F)
    
    if (has_weather_data(activity)) {
      weather_df <- extract_weather_data(activity$weather)
      activity_df <- cbind(activity_df, weather_df)
    }
    
    if (has_splits_data(activity)) {
      split_df <- as.data.frame(activity$splits_standard, stringsAsFactors = F)
      combined_row <- cbind(activity_df, split_df)
      result_rows[[length(result_rows) + 1]] <- combined_row[order(-as.numeric(combined_row$split)), ]
    } else {
      result_rows[[length(result_rows) + 1]] <- activity_df
    }
  }
  
  if (length(result_rows) == 0) return(data.frame())
  
  combined_df <- bind_rows(result_rows)
  
  combined_df <- process_date_columns(combined_df)
  combined_df <- convert_numeric_columns(combined_df)
  
  return(combined_df)
}


has_weather_data <- function(activity) {
  !is.null(activity$weather) && 
    is.list(activity$weather) && 
    !all(sapply(activity$weather, is.null))
}


has_splits_data <- function(activity) {
  !is.null(activity$splits_standard) && 
    length(activity$splits_standard) > 0
}


extract_weather_data <- function(weather_data) {
  weather_fields <- c(
    "temperature", "dew_point", "humidity", "pressure", "wind_direction", 
    "wind_speed", "snow", "precipitation", "conditions", "temperature_f", 
    "dew_point_f", "precipitation_inch", "snow_inch", "wind_speed_kmh", 
    "wind_speed_mph"
  )
  
  weather_values <- lapply(weather_fields, function(field) {
    if (is.null(weather_data[[field]])) NA else weather_data[[field]]
  })
  
  names(weather_values) <- weather_fields
  return(as.data.frame(weather_values, stringsAsFactors = FALSE))
}


process_date_columns <- function(df) {
  if (!"start_date" %in% names(df)) return(df)
  
  df$start_date <- as.POSIXct(df$start_date, format="%Y-%m-%dT%H:%M:%S", tz = "UTC")
  df$date <- as.Date(df$start_date)
  df$year <- year(df$start_date)
  df$month <- month(df$start_date)
  df$week <- isoweek(df$start_date)
  df$weekday <- wday(df$start_date, label = TRUE)
  
  return(df)
}


process_zones <- function(zones) {
  if (length(zones) == 0) return(data.frame())
  
  zones_df <- bind_rows(lapply(zones, function(zone) {
    as.data.frame(t(unlist(zone)), stringsAsFactors = FALSE)
  }))
  

  zones_df <- convert_numeric_columns(zones_df)
  
  return(zones_df)
}


process_athlete_stats <- function(stats) {
  if (length(stats) == 0) return(data.frame())
  

  stat_categories <- c(
    "recent_ride_totals", "recent_run_totals", "recent_swim_totals",
    "ytd_ride_totals", "ytd_run_totals", "ytd_swim_totals",
    "all_ride_totals", "all_run_totals", "all_swim_totals"
  )
  

  stats_list <- process_stat_categories(stats, stat_categories)
  

  individual_stats <- c("biggest_ride_distance", "biggest_climb_elevation_gain")
  stats_list <- c(stats_list, process_individual_stats(stats, individual_stats))
  

  if (length(stats_list) > 0) {
    combined_stats <- bind_rows(stats_list, .id = "stat_id")
    combined_stats <- convert_numeric_columns(combined_stats)
    return(combined_stats)
  } else {
    return(data.frame())
  }
}


process_stat_categories <- function(stats, categories) {
  stats_list <- list()
  
  for (category in categories) {
    if (!is.null(stats[[category]])) {
      category_df <- as.data.frame(stats[[category]], stringsAsFactors = F)
      category_df$stat_category <- category
      stats_list[[category]] <- category_df
    }
  }
  
  return(stats_list)
}


process_individual_stats <- function(stats, stat_names) {
  stats_list <- list()
  
  for (stat_name in stat_names) {
    if (!is.null(stats[[stat_name]])) {
      stats_list[[stat_name]] <- data.frame(
        value = stats[[stat_name]],
        stat_name = stat_name,
        stringsAsFactors = F
      )
    }
  }
  
  return(stats_list)
}


convert_numeric_columns <- function(df) {
  for (col in names(df)) {
    if (is.character(df[[col]])) {
      if (all(is.na(df[[col]]) | grepl("^-?\\d*\\.?\\d*$", df[[col]]))) {
        df[[col]] <- as.numeric(df[[col]])
      }
    }
  }
  
  return(df)
}