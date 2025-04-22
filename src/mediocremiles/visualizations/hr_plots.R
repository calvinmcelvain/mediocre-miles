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
outliers_removed <- strava.df %>% filter(pace_min_per_mile < 10)
hr.p2 <- ggplot(outliers_removed,
       aes(x = pace_min_per_mile, y = factor(year), fill = factor(year)),
       alpha = 0.5) +
  geom_density_ridges(
    aes(height = after_stat(density)),
    stat = "binline",
    bins=100,
    scale = 2, 
    alpha = 0.7
  ) +
  scale_fill_wsj(name = "Pace (min/mile)") +
  labs(title = "Distribution of Running Pace by Year",
       x = "Pace (min/mile)",
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


