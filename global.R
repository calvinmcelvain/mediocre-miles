#
# Module for Shiny app configs
#

install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages)
}

install_if_missing(c("jsonlite", "here"))


library(jsonlite)
library(here)

tryCatch({
  setwd(here())
}, error = function(e) {
  message("Note: Working with current directory. For best results, run from project root.")
})

source_files <- c(
  "src/mediocremiles/data_import.R",
  "src/mediocremiles/plot_configs.R",
  "src/mediocremiles/shiny/data.R",
  "src/mediocremiles/shiny/dashboard.R",
  "src/mediocremiles/shiny/activities.R",
  "src/mediocremiles/shiny/training.R",
  "src/mediocremiles/shiny/trends.R",
  "src/mediocremiles/shiny/settings.R",
  "src/mediocremiles/analysis/training_load.R",
  "src/mediocremiles/analysis/trends.R",
  "src/mediocremiles/visualizations/activity_charts.R",
  "src/mediocremiles/visualizations/weekly_summary.R"
)

for(file in source_files) {
  tryCatch({
    source(file)
  }, error = function(e) {
    message(paste("Error loading:", file, "\nError:", e$message))
  })
}


config <- tryCatch( 
  { fromJSON("configs/config.json") },
  error = function(e) {
    message("Error loading config.json: ", e$message)
    list(
      paths = list(data = "data/strava_data.json"))
})


app_config <- list(
  data_path = config$paths$data,
  repos = "https://cran.rstudio.com",
  required_packages = c("shiny", "shinydashboard", "ggplot2", "dplyr",
                        "lubridate", "jsonlite", "zoo", "here", "scales", "DT", 
                        "shinyWidgets", "shinycssloaders", "plotly"),
  theme = list(
    skin = "purple",
    dashboard_width = 300
  )
)