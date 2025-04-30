#
# src/mediocremiles/shiny_app/visualizations/recent_activities.R - Recent activities DF.
#

library(dplyr)
library(lubridate)


generate_recent_activities_table <- function(data) {
  recent <- data %>%
    arrange(desc(start_date)) %>%
    select(
      name, activity_type, start_date, distance_miles, moving_time_hours,
      average_heartrate, max_heartrate, total_elevation_gain_meters)
  
  recent$start_date <- format(recent$start_date, "%Y-%m-%d %H:%M")
  recent$distance_miles <- round(recent$distance_miles, 1)
  recent$moving_time_hours <- round(recent$moving_time_hours, 2)
  
  names(recent) <- c(
    "Name", "Type", "Date", "Distance (miles)", "Duration (hrs)", 
    "Avg HR", "Max HR", "Elevation Gain (m)")
  
  return(recent)
}