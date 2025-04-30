#
# global.R - Global variables and package loading
#



# Package setup.
repos <- "https://cran.rstudio.com"
options(repos = repos)

required_packages <- c(
  "shiny", 
  "shinydashboard", 
  "ggplot2", 
  "dplyr", 
  "lubridate", 
  "jsonlite", 
  "zoo", 
  "here", 
  "scales", 
  "DT", 
  "shinyWidgets", 
  "shinycssloaders", 
  "plotly"
)


install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages)
}

install_if_missing(required_packages)


library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinycssloaders)
library(ggplot2)
library(dplyr)
library(lubridate)
library(here)
library(DT)
library(scales)





# Directory setup.
tryCatch({
  setwd(here())
}, error = function(e) {
  message("Note: Working with current directory. For best results, run from project root.")
})

options(strava_data_path = "data/strava_data.json")


# Source file setup.
source_files <- list(
  data = c(
    "src/mediocremiles/shiny_app/data_import.R",
    "src/mediocremiles/shiny_app/data_processing.R"
  ),
  utils = c(
    "src/mediocremiles/shiny_app/helpers.R",
    "src/mediocremiles/shiny_app/onstants.R",
    "src/mediocremiles/shiny_app/themes.R"
  ),
  visualizations = c(
    "src/mediocremiles/shiny_app/visualizations/activity_charts.R",
    "src/mediocremiles/shiny_app/visualizations/training_charts.R",
    "src/mediocremiles/shiny_app/visualizations/trend_charts.R"
  ),
  ui_modules = c(
    "src/mediocremiles/shiny_app/modules/sidebar_module.R",
    "src/mediocremiles/shiny_app/modules/filter_modules.R",
    "src/mediocremiles/shiny_app/modules/dashboard_module.R",
    "src/mediocremiles/shiny_app/modules/activities_module.R",
    "src/mediocremiles/shiny_app/modules/training_module.R",
    "src/mediocremiles/shiny_app/modules/trends_module.R",
    "src/mediocremiles/shiny_app/modules/settings_module.R"
  )
)

source_file_safely <- function(file_path) {
  tryCatch({
    source(file_path)
  }, error = function(e) {
    message(paste("Error loading:", file_path, "\nError:", e$message))
  })
}


for (category in names(source_files)) {
  message(paste("Loading", category, "files..."))
  for (file in source_files[[category]]) {
    source_file_safely(file)
  }
}