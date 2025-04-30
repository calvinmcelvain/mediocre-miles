# Loading plot utils.
library(dotenv)

env_path <- file.path(path.expand("~"), "dotfiles/mediocre_miles.env")
dotenv::load_dot_env(env_path)


util_path = file.path(
  Sys.getenv("PROJECT_DIRECTORY"),
  "src/mediocremiles/visualizations/plot_utils.R"
)
source(util_path)


### Radar Plot ###

hr_radar_data <- strava.df %>%
  group_by(distance_category) %>%
  summarize(
    avg_hr = mean(average_heartrate, na.rm = T),
    avg_cadence = mean(average_cadence, na.rm = T),
    avg_pace = mean(pace_min_per_mile, na.rm = T),
    avg_elevation = mean(total_elevation_gain_meters, na.rm = T),
    efficiency = mean(efficiency, na.rm = T),
    run_count = n(),
    .groups = "drop"
  ) %>%
  mutate(
    hr_norm = rescale(avg_hr, to = c(0.1, 1)),
    cadence_norm = rescale(avg_cadence, to = c(0.1, 1)),
    pace_norm = rescale(-avg_pace, to = c(0.1, 1)),
    elev_norm = rescale(avg_elevation, to = c(0.1, 1)),
    eff_norm = rescale(-efficiency, to = c(0.1, 1)),
    count_norm = rescale(run_count, to = c(0.3, 1))
  ) %>%
  select(distance_category, 
         "Heart Rate" = hr_norm, 
         "Speed" = pace_norm, 
         "Cadence" = cadence_norm,
         "Efficiency" = eff_norm,
         "Elevation" = elev_norm,
         "Frequency" = count_norm) %>%
  pivot_longer(cols = -distance_category,
               names_to = "metric",
               values_to = "value")

metrics <- c(
  "Heart Rate", "Speed", "Cadence", "Efficiency", "Elevation", "Frequency")
n_metrics <- length(metrics)

radar_data_complete <- expand.grid(
  distance_category = unique(strava.df$distance_category),
  metric = metrics, stringsAsFactors = F) %>%
  arrange(distance_category, factor(metric, levels = metrics)) %>%
  left_join(hr_radar_data,
            by = c("distance_category", "metric"))

radar_coords <- radar_data_complete %>%
  group_by(distance_category) %>%
  mutate(
    angle = match(metric, metrics) * 2 * pi / n_metrics,
    x = value * sin(angle),
    y = value * cos(angle),
    id = row_number())

axis_coords <- data.frame(
  metric = metrics,
  angle = seq(1, n_metrics) * 2 * pi / n_metrics,
  stringsAsFactors = FALSE) %>%
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
                 group_by(distance_category) %>%
                 mutate(orig_id = id) %>%
                 do(bind_rows(., 
                              filter(., id == min(.$id)) %>% 
                                mutate(id = max(.$id) + 1))) %>%
                 ungroup(),
               aes(x = x, y = y, group = distance_category, fill = distance_category),
               alpha = 0.2) +
  geom_path(data = radar_coords %>%
              group_by(distance_category) %>%
              do(bind_rows(., 
                           filter(., id == min(.$id)) %>% 
                             mutate(id = max(.$id) + 1))) %>%
              ungroup(),
            aes(x = x, y = y, group = distance_category, color = distance_category),
            size = 1) +
  geom_point(data = radar_coords,
             aes(x = x, y = y, color = distance_category),
             size = 3) +
  scale_fill_manual(values = wsj_colors[c(1,3,5)]) +
  scale_color_manual(values = wsj_colors[c(1,3,5)]) +
  coord_equal(clip = "off") +
  theme_void() +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5)) +
  labs(title = "Running Metrics Radar by Distance Category",
       subtitle = "Higher values indicate better performance",
       fill = "Distance Category", color = "Distance Category")

