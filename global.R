#
# global.R - Global variables and package loading
#


options(repos = "https://cran.rstudio.com")

required_packages <- c(
  "shiny", "shinydashboard", "ggplot2", "dplyr", "lubridate", 
  "jsonlite", "zoo", "here", "scales", "DT", "shinyWidgets", 
  "shinycssloaders", "plotly", "ggExtra", "ggforce", "ggridges"
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
DEFAULT_DATA_PATH <- "data/demo.json"


source_files <- c(
  "src/mediocremiles/shiny_app/modules/data_manager.R",
  "src/mediocremiles/shiny_app/modules/dashboard.R",
  "src/mediocremiles/shiny_app/modules/trends.R",
  "src/mediocremiles/shiny_app/modules/training.R",
  "src/mediocremiles/shiny_app/modules/settings.R",
  "src/mediocremiles/shiny_app/utils/data_import.R",
  "src/mediocremiles/shiny_app/visualizations/plot_configs.R",
  "src/mediocremiles/shiny_app/visualizations/trends.R",
  "src/mediocremiles/shiny_app/visualizations/dashboard.R",
  "src/mediocremiles/shiny_app/visualizations/training.R",
  "src/mediocremiles/shiny_app/server.R",
  "src/mediocremiles/shiny_app/ui.R"
)

for(file in source_files) {
  tryCatch({
    source(file)
  }, error = function(e) {
    message(paste("Error loading:", file, "\nError:", e$message))
  })
}