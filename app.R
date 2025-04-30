# 
# app.R - Main application entry point.
# This file loads necessary components and starts the Shiny app.
# 

source("global.R")
source("src/mediocremiles/shiny_app/server.R")
source("src/mediocremiles/shiny_app/modules/ui.R")
source("src/mediocremiles/shiny_app/modules/data_manager.R")
source("src/mediocremiles/shiny_app/modules/dashboard.R")
source("src/mediocremiles/shiny_app/modules/activities.R")
source("src/mediocremiles/shiny_app/modules/training.R")
source("src/mediocremiles/shiny_app/modules/trends.R")
source("src/mediocremiles/shiny_app/modules/settings.R")


shinyApp(ui = appUI, server = appServer)