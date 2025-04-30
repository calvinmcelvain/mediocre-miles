# Loading plot utils.
library(dotenv)

env_path <- file.path(path.expand("~"), "dotfiles/mediocre_miles.env")
dotenv::load_dot_env(env_path)


util_path = file.path(
  Sys.getenv("PROJECT_DIRECTORY"),
  "src/mediocremiles/visualizations/plot_utils.R"
)
source(util_path)


##############################################################################
#----------------------------- Heart Rate Plots -----------------------------#
##############################################################################


# 1. Average HR vs. Weekly Mileage.
weekly_data <- strava.df %>%
  group_by(week) %>%
  summarize(
    avg_hr = mean(average_heartrate),
    weekly_mileage = first(weekly_mileage),
    .groups = "drop")

hr.p1 <- ggplot(weekly_data, aes(x = weekly_mileage, y = avg_hr)) +
  geom_point(size = 2.2, color = wsj_colors[6]) +
  geom_smooth(se = T, color = wsj_colors[3], fill = wsj_colors[3], size = 1) +
  labs(title = "Average HR vs. Weekly Mileage",
       x = "Weekly Mileage",
       y = "Average Heart Rate (bpm)") +
  scale_x_continuous(breaks=seq(0, 70, by=10)) +
  plot.thm



# 2. Distribution of paces by year.
library(ggridges)
ggplot(outliers_removed,
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
  labs(x = "Pace (mph)",
       y = "Year") +
  plot.thm



# 3. Pace Distribution by Distance and Heart Rate Zone
hr.p3 <- ggplot(outliers_removed, aes(x = pace_min_per_mile, y = distance_miles)) +
  geom_point(data = mutate(outliers_removed, hr_zones = NULL), color = "grey80") +
  geom_point(size = 2.2, aes(color = hr_zones)) +
  facet_wrap(~hr_zones) +
  scale_color_wsj(name = "Heart Rate Zone",
                  labels = c("> 183", "170 - 182", "161 - 169", "142 - 160", "< 142")) +
  labs(
    title = "Pace Distribution by Distance and Heart Rate Zone",
    x = "Pace (minutes/mile)",
    y = "Distance (miles)"
  ) +
  plot.thm





# Other
weekly_data <- data %>%
  mutate(week_start = floor_date(start_date, unit = "week", week_start = 1)) %>%
  distinct(id, .keep_all = T) %>%
  group_by(week_start) %>%
  summarize(
    avg_hr = mean(average_heartrate),
    weekly_mileage = sum(distance_miles),
    .groups = "drop")

ggplot(weekly_data, aes(x = weekly_mileage, y = avg_hr)) +
  geom_point(size = 2, color = colors.wsj[6]) +
  geom_smooth(se = T, color = colors.wsj[3], fill = colors.wsj[3], size = 1) +
  labs(title = "Average HR vs. Weekly Mileage",
       x = "Weekly Mileage (miles)",
       y = "Average Heart Rate (bpm)") +
  scale_x_continuous(breaks=seq(0, 70, by=10)) +
  plot.thm



# 2. Elevation Profile with Speed Impact
ggplot(data, aes(x = split_average_speed_mph, y = elevation_difference_ft)) +
  geom_jitter(size = 1.1, color = "orange", height = 0.02, width = 0.01) +
  scale_x_continuous(limits = c(5.5, 12)) +
  labs(x = "Speed (MPH)", y = "Net Elelvation") +
  theme.base

# 3. Grade-Adjusted Speed Analysis
max_lines <- data %>%
  group_by(split) %>%
  summarize(max_mph = max(split_average_speed_mph),
            max_grade_adj = max(average_grade_adjusted_speed_mph))


ggplot(data, aes(x = split)) +
  geom_line(data = max_lines, aes(y = max_mph, x = split), size = 1.2, color = colors.wsj[3]) +
  geom_line(data = max_lines, aes(y = max_grade_adj, x = split), size = 1.2, color = colors.wsj[1]) +
  labs(
    title = "Actual vs. Grade-Adjusted Speed",
    subtitle = "How the terrain affects your effective running effort",
    x = "Split Number",
    y = "Speed (mph)",
    color = "Measurement"
  ) +
  theme.base

# 4. Heart Rate Zones Analysis
# Assuming the following zones:
# Zone 1: <130 bpm
# Zone 2: 130-150 bpm
# Zone 3: 150-170 bpm
# Zone 4: >170 bpm

hr_data <- data.frame(
  Zone = c("Zone 1 (<130)", "Zone 2 (130-150)", "Zone 3 (150-170)", "Zone 4 (>170)"),
  Count = c(
    sum(data$split_average_heartrate < 130, na.rm = T),
    sum(data$split_average_heartrate >= 130 & data$split_average_heartrate < 150, na.rm = T),
    sum(data$split_average_heartrate >= 150 & data$split_average_heartrate < 170, na.rm = T),
    sum(data$split_average_heartrate >= 170, na.rm = T)
  )
)

hr_zones_plot <- ggplot(hr_data, aes(x = Zone, y = Count, fill = Zone)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("green", "yellow", "orange", "red")) +
  labs(
    title = "Heart Rate Zone Distribution",
    subtitle = "Time spent in different heart rate zones during your run",
    x = NULL,
    y = "Number of Splits"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

data$efficiency <- data$split_average_speed_mph / (data$split_average_heartrate / 100)

ggplot(data, aes(x = split, y = efficiency)) +
  geom_line(size = 1.2, color = "darkblue") +
  geom_point(size = 3, color = "darkblue") +
  labs(
    title = "Running Efficiency Throughout Run",
    subtitle = "Higher values indicate better cardiovascular efficiency",
    x = "Split Number",
    y = "Efficiency (Speed/HR ratio)"
  ) +
  theme_minimal()

weather_data <- data[1, c("weather_temperature_f", "weather_humidity", "weather_wind_speed_mph")]
weather_data_long <- data.frame(
  Factor = c("Temperature (°F)", "Humidity (%)", "Wind Speed (mph)"),
  Value = c(weather_data$weather_temperature_f, weather_data$weather_humidity, weather_data$weather_wind_speed_mph)
)

ggplot(weather_data_long, aes(x = Factor, y = Value, fill = Factor)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("skyblue", "lightblue", "steelblue")) +
  labs(
    title = "Weather Conditions During Run",
    subtitle = "Environmental factors that may have affected performance",
    x = NULL,
    y = "Value"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
