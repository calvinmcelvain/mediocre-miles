library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)


data_path <- "data/strava_data.json"



import_activity_data <- function() {
  raw_data <- fromJSON(data_path)
  activities <- raw_data$activities
  
  if (is.list(activities) && !is.data.frame(activities)) {
    activities_list <- list()
    activity_names <- names(activities)
    
    for (activity_id in activity_names) {
      activity <- activities[[activity_id]]
      if (is.list(activity)) {
        # Extract non-list elements for activity metadata
        activity_meta <- activity[!sapply(activity, is.list)]
        activity_df <- as.data.frame(t(unlist(activity_meta)), 
                                     stringsAsFactors = FALSE)
        
        # Handle the splits separately
        if (!is.null(activity$splits_standard) && length(activity$splits_standard) > 0) {
          splits <- bind_rows(activity$splits_standard)
          
          if (nrow(splits) > 0) {
            # Add activity_id to splits
            splits$activity_id <- activity$id
            
            # Rename any columns in splits that might conflict with activity_df
            # First, identify potential conflicts
            common_cols <- intersect(names(splits), names(activity_df))
            common_cols <- setdiff(common_cols, "activity_id") # Exclude activity_id
            
            # Rename conflicting columns in splits with a prefix
            if (length(common_cols) > 0) {
              for (col in common_cols) {
                names(splits)[names(splits) == col] <- paste0("split_", col)
              }
            }
            
            # Now repeat the activity data and combine
            for (i in 1:nrow(splits)) {
              repeated_activity <- activity_df[rep(1, 1), ] # Just one row 
              combined_df <- cbind(splits[i, ], repeated_activity)
              activities_list[[length(activities_list) + 1]] <- combined_df
            }
          } else {
            activity_df$activity_id <- activity$id
            activities_list[[length(activities_list) + 1]] <- activity_df
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
  } else if (is.data.frame(activities)) {
    final_df <- activities
  } else {
    stop("Unexpected format for activities data")
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
                    "max_speed_meters_sec", "average_heartrate", "max_heartrate",
                    "distance_miles", "distance_km", "average_cadence", "pr_count",
                    "kudos_count", "workout_type", "shoe_total_distance", "calories",
                    "start_lat", "start_lon", "end_lat", "end_lon", "perceived_exertion",
                    "suffer_score", "weighted_average_power", "distance", "elapsed_time",
                    "moving_time", "elevation_difference", "average_grade_adjusted_speed")
  
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
