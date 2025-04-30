library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)



process_strava_data <- function(data_path) {
  raw_data <- fromJSON(data_path)

  # process.
  activities_df <- process_activities(raw_data$activities)
  hr_zones_df <- process_heart_rate_zones(raw_data$zones$heart_rate_zones)
  power_zones_df <- process_power_zones(raw_data$zones$power_zones)
  stats_df <- process_athlete_stats(raw_data$stats)

  # list of dfs.
  return(list(
    activities = activities_df,
    heart_rate_zones = hr_zones_df,
    power_zones = power_zones_df,
    stats = stats_df
  ))
}


process_activities <- function(activities) {
  if (length(activities) == 0) return(data.frame())

  activities_list <- list()

  for (activity_id in names(activities)) {
    activity <- activities[[activity_id]]

    if (!is.list(activity)) next

    activity_data <- activity[!sapply(activity, is.list)]
    activity_df <- as.data.frame(t(unlist(activity_data)), stringsAsFactors = F)
    
    if (!is.null(activity$weather) && is.list(activity$weather) && !all(sapply(activity$weather, is.null))) {
      weather_data <- lapply(activity$weather, function(x) {
        if (is.null(x)) return(NA)
        else return(x)
      })
      
      weather_df <- data.frame(
        temperature = weather_data$temperature,
        dew_point = weather_data$dew_point,
        humidity = weather_data$humidity,
        pressure = weather_data$pressure,
        wind_direction = weather_data$wind_direction,
        wind_speed = weather_data$wind_speed,
        snow = weather_data$snow,
        precipitation = weather_data$precipitation,
        conditions = weather_data$conditions,
        temperature_f = weather_data$temperature_f,
        dew_point_f = weather_data$dew_point_f,
        precipitation_inch = weather_data$precipitation_inch,
        snow_inch = weather_data$snow_inch,
        wind_speed_kmh = weather_data$wind_speed_kmh,
        wind_speed_mph = weather_data$wind_speed_mph,
        stringsAsFactors = F
      )
      
      # Add weather data to activity dataframe
      activity_df <- cbind(activity_df, weather_df)
    }
    
    if (!is.null(activity$splits_standard) && length(activity$splits_standard) > 0) {
      splits_df <- process_splits(activity$splits_standard, activity$id)
      activities_list[[paste0(activity_id, "_splits")]] <- splits_df
    }
    
    activities_list[[activity_id]] <- activity_df
  }
  
  if (length(activities_list) > 0) {
    combined_df <- bind_rows(activities_list, .id = "activity_list_id")
  } else {
    return(data.frame())
  }
  
  # Convert date columns
  if ("start_date" %in% names(combined_df)) {
    combined_df$start_date <- as.POSIXct(combined_df$start_date, format="%Y-%m-%dT%H:%M:%S", tz = "UTC")
    combined_df$date <- as.Date(combined_df$start_date)
    combined_df$year <- year(combined_df$start_date)
    combined_df$month <- month(combined_df$start_date)
    combined_df$week <- isoweek(combined_df$start_date)
    combined_df$weekday <- wday(combined_df$start_date, label = TRUE)
  }
  
  combined_df <- convert_to_numeric(combined_df)
  
  return(combined_df)
}


process_splits <- function(splits, activity_id) {
  if (length(splits) == 0) return(data.frame())
  
  splits_df <- bind_rows(lapply(splits, function(split) {
    as.data.frame(t(unlist(split)), stringsAsFactors = F)
  }))
  
  splits_df$activity_id <- activity_id
  
  colnames(splits_df) <- paste0("split_", colnames(splits_df))
  splits_df$split_activity_id <- activity_id
  
  splits_df <- convert_to_numeric(splits_df)
  
  return(splits_df)
}


process_heart_rate_zones <- function(zones) {
  if (length(zones) == 0) return(data.frame())
  
  zones_df <- bind_rows(lapply(zones, function(zone) {
    as.data.frame(t(unlist(zone)), stringsAsFactors = F)
  }))
  
  # Convert to numeric
  zones_df <- convert_to_numeric(zones_df)
  
  return(zones_df)
}


process_power_zones <- function(zones) {
  if (length(zones) == 0) return(data.frame())
  
  zones_df <- bind_rows(lapply(zones, function(zone) {
    as.data.frame(t(unlist(zone)), stringsAsFactors = F)
  }))
  
  zones_df <- convert_to_numeric(zones_df)
  
  return(zones_df)
}


process_athlete_stats <- function(stats) {
  if (length(stats) == 0) return(list())
  
  stat_categories <- c(
    "recent_ride_totals", "recent_run_totals", "recent_swim_totals",
    "ytd_ride_totals", "ytd_run_totals", "ytd_swim_totals",
    "all_ride_totals", "all_run_totals", "all_swim_totals"
  )
  
  stats_list <- list()
  
  for (category in stat_categories) {
    if (!is.null(stats[[category]])) {
      category_df <- as.data.frame(stats[[category]], stringsAsFactors = F)
      category_df$stat_category <- category
      stats_list[[category]] <- category_df
    }
  }
  
  if (!is.null(stats$biggest_ride_distance)) {
    stats_list$biggest_ride_distance <- data.frame(
      value = stats$biggest_ride_distance,
      stat_name = "biggest_ride_distance",
      stringsAsFactors = F
    )
  }
  
  if (!is.null(stats$biggest_climb_elevation_gain)) {
    stats_list$biggest_climb_elevation_gain <- data.frame(
      value = stats$biggest_climb_elevation_gain,
      stat_name = "biggest_climb_elevation_gain",
      stringsAsFactors = F
    )
  }
  
  if (length(stats_list) > 0) {
    combined_stats <- bind_rows(stats_list, .id = "stat_id")
    combined_stats <- convert_to_numeric(combined_stats)
    return(combined_stats)
  } else {
    return(data.frame())
  }
}


convert_to_numeric <- function(df) {
  possible_numeric <- sapply(df, function(x) {
    all(is.na(x) | grepl("^-?\\d*\\.?\\d*$", x))
  })
  
  for (col in names(df)[possible_numeric]) {
    if (is.character(df[[col]])) {
      df[[col]] <- as.numeric(df[[col]])
    }
  }
  
  return(df)
}
