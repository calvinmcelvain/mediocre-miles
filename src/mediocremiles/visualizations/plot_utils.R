# Packge loading
library(dotenv)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(ggExtra)
library(ggridges)

# Getting working dir.
env_path <- file.path(path.expand("~"), "dotfiles/mediocre_miles.env")
dotenv::load_dot_env(env_path)

# Loading data
data_path <- file.path(Sys.getenv("PROJECT_DIRECTORY"), "data/strava_data.csv")
strava.df <- read.csv(data_path)

# Standard theme
plot.thm <- theme_wsj(color = "white") +
  theme(axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        title = element_text(size = 16, face = "bold"),
        legend.position = "bottom",
        legend.title=element_text(size=12, face = "bold"), 
        legend.text=element_text(size=11),
        strip.text.x = element_text(size = 12, face = "bold", family = "mono"))