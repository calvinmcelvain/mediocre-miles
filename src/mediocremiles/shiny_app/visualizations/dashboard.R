#
# src/mediocremiles/shiny_app/visualizations/dashboard.R - Dashboard visualizations.
#


hex_to_rgba <- function(hex, alpha = 0.4) {
  rgb <- col2rgb(hex) / 255
  sprintf("rgba(%d, %d, %d, %.2f)", rgb[1]*255, rgb[2]*255, rgb[3]*255, alpha)
}


generate_recent_activities_table <- function(data, colors) {
  activities_summary <- data %>%
    distinct(id, .keep_all = T) %>%
    select(date, name, activity_type, distance_miles, moving_time_minutes, elevation_gain_feet,
           average_heartrate, max_heartrate, average_speed_mph, calories, temperature_f,
           perceived_exertion)
  
  datatable(
    activities_summary,
    colnames = c(
      "Date", "Name", "Activity", "Distance (miles)", "Time (min)", "Elevation (ft)",
      "Avg HR (bpm)", "Max HR (bpm)", "Speed (mph)", "Calories", "Temperature (F)",
      "Perceived Exertion"),
    options = list(pageLength = 20, order = list(list(0, 'desc')), scrollX = T),
    rownames = F) %>%
    formatRound(
      columns = c("distance_miles", "moving_time_minutes", "elevation_gain_feet", 
                  "average_heartrate", "average_speed_mph", "temperature_f"),
      digits = 2) %>%
    formatStyle(
      'distance_miles',
      background = styleColorBar(activities_summary$distance_miles, hex_to_rgba(colors[2], 0.4)),
      backgroundSize = '100% 90%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'center') %>%
    formatStyle(
      'average_heartrate',
      background = styleColorBar(activities_summary$average_heartrate, hex_to_rgba(colors[1], 0.4)),
      backgroundSize = '100% 90%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'center') %>%
    formatStyle(
      'average_speed_mph',
      background = styleColorBar(activities_summary$average_speed_mph, hex_to_rgba(colors[5], 0.4)),
      backgroundSize = '100% 90%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'center') %>%
    formatStyle(
      columns = 0:11,
      fontFamily = 'monospace')
}