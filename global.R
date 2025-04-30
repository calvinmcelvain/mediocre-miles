#
# global.R - Global variables and package loading
#


options(repos = "https://cran.rstudio.com")

required_packages <- c(
  "shiny", "shinydashboard", "ggplot2", "dplyr", "lubridate", 
  "jsonlite", "zoo", "here", "scales", "DT", "shinyWidgets", 
  "shinycssloaders", "plotly"
)


install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages)
}


install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = T))



tryCatch({
  setwd(here())
}, error = function(e) {
  message("Note: Working with current directory. For best results, run from project root.")
})


# Default data path
DEFAULT_DATA_PATH <- "data/strava_data.json"



source_files <- c(
  "src/mediocremiles/data_import.R",
  "src/mediocremiles/plot_configs.R",
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