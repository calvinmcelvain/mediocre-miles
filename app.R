# 
# app.R - Main application entry point.
# This file loads necessary components and starts the Shiny app.
# 

source("global.R")
source("modules/ui_components.R")
source("modules/data_manager.R")
source("modules/dashboard_module.R")
source("modules/activities_module.R")
source("modules/training_module.R")
source("modules/trends_module.R")
source("modules/settings_module.R")


shinyApp(ui = appUI, server = appServer)