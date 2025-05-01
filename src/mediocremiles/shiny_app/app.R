# 
# app.R - Main application entry point.
# This file loads necessary components and starts the Shiny app.
# 

source("global.R")
source("ui.R")
source("server.R")

source("modules/data_manager.R")

source("modules/recent_activity/overview.R")
source("modules/recent_activity/details.R")
source("modules/recent_activity/training_load.R")

source("modules/performance/overview.R")
source("modules/performance/trends.R")
source("modules/performance/yearly.R")

source("modules/gear/overview.R")
source("modules/gear/comparison.R")

source("modules/weather/overview.R")
source("modules/weather/impact.R")

source("modules/settings.R")

shinyApp(ui = appUI, server = appServer)