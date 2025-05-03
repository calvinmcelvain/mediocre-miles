#
# src/mediocremiles/shiny_app/app.R - Main application entry point.
#


source("global.R")


shinyApp(ui = appUI, server = appServer)
