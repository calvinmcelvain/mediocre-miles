# Packge loading
library(dotenv)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(ggExtra)
library(ggridges)
library(patchwork)
library(forecast)
library(scales)
library(tidyverse)
library(ggforce)

# Getting working dir.
env_path <- file.path(path.expand("~"), "dotfiles/mediocre_miles.env")
dotenv::load_dot_env(env_path)

# Loading data
data_path <- file.path(Sys.getenv("PROJECT_DIRECTORY"), "data/strava_data.csv")
data <- read.csv(data_path)

# Data preprocessing
strava.df <- data %>%
  filter(activity_type == "Run") %>%
  filter(
    !is.na(average_heartrate),
    !is.na(distance_miles),
    !is.na(average_cadence)) %>%
  mutate(
    start_date = as_datetime(start_date),
    date = as.Date(start_date),
    year = year(date),
    pace_min_per_km = 60 / average_speed_kmh,
    pace_min_per_mile = 60 / average_speed_mph,
    hr_zones = factor(case_when(
      average_heartrate < 142 ~ "Recovery",
      average_heartrate < 161 ~ "Endurance",
      average_heartrate < 170 ~ "Power",
      average_heartrate < 183 ~ "Threshold",
      TRUE ~ "Anaerobic"
    ), levels = c("Recovery", "Endurance", "Power", "Threshold", "Anaerobic")),
    efficiency = average_heartrate / average_speed_mph,
    distance_category = factor(case_when(
      distance_miles < 7 ~ "Short",
      distance_miles < 12 ~ "Medium",
      TRUE ~ "Long"
    )),
    week = as.Date(floor_date(date, "week")),
    month = as.Date(floor_date(date, "month"))
  ) %>%
  arrange(start_date) %>%
  group_by(week) %>%
  mutate(weekly_mileage = sum(distance_miles)) %>%
  group_by(month) %>%
  mutate(monthly_mileage = sum(distance_miles)) %>%
  ungroup()

# Standard theme
plot.thm <- theme_wsj(color = "white") +
  theme(axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        title = element_text(size = 16, face = "bold"),
        legend.position = "bottom",
        legend.title=element_text(size=12, face = "bold"), 
        legend.text=element_text(size=11),
        strip.text.x = element_text(size = 12, face = "bold", family = "mono"))

# Color palette
wsj_colors <- wsj_pal()(6)