#
# Main app module.
#


source("global.R")

install_if_missing(app_config$required_packages)

library(shinydashboard)
library(shiny)
library(shinycssloaders)
library(DT)


ui <- dashboardPage(
  skin = app_config$theme$skin,
  
  dashboardHeader(
    title = span(icon("running"), "Mediocre Miles"),
    titleWidth = app_config$theme$dashboard_width
  ),
  
  dashboardSidebar(
    width = app_config$theme$dashboard_width,
    sidebarMenu(
      id = "sidebar",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Activities", tabName = "activities", icon = icon("running")),
      menuItem("Training Load", tabName = "training", icon = icon("chart-line")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-area")),
      menuItem("Settings", tabName = "settings", icon = icon("cog"))
    ),
    
    # filter controls.
    dateRangeInput(
      "date_range", 
      "Filter by Date:",
      start = min(process_strava_data(app_config$data_path)$activities$start_date),
      end = Sys.Date(),
      max = Sys.Date()
    ),
    
    selectizeInput(
      "activity_type", 
      "Activity Type:", 
      choices = c("All" = "all", unique(process_strava_data(app_config$data_path)$activities$activity_type)),
      multiple = F,
      selected = "all"
    ),
    
    actionButton(
      "reset_filters", 
      "Reset Filters", 
      icon = icon("sync")
    )
  ),
  
  dashboardBody(
    uiOutput("data_notification"),
    
    tabItems(
      tabItem(tabName = "dashboard", dashboardModuleUI("dashboard")),
      tabItem(tabName = "activities", activitiesModuleUI("activities")),
      tabItem(tabName = "training", trainingModuleUI("training")),
      tabItem(tabName = "trends", trendsModuleUI("trends")),
      tabItem(tabName = "settings", settingsModuleUI("settings"))
    )
  )
)

server <- function(input, output, session) {
  data <- dataModule("data", app_config$data_path)
  
  output$data_notification <- renderUI({
    status <- data$data_status()
    if(!is.null(status$error)) {
      div(class = "alert alert-danger",
          icon("exclamation-triangle"),
          status$error)
    } else if(!status$loaded) {
      div(class = "alert alert-warning",
          icon("spinner", class = "fa-spin"),
          "Loading data...")
    } else if(nrow(data$activity_data()) == 0) {
      div(class = "alert alert-warning",
          icon("exclamation-triangle"),
          "No activities found with current filters")
    } else {
      return(NULL)
    }
  })
  
  dashboardModule("dashboard", data$activity_data, theme.base, colors.wsj)
  activitiesModule("activities", data$activity_data, theme.base)
  trainingModule("training", data$activity_data, data$hr_zones_data, data$power_zones_data, theme.base)
  trendsModule("trends", data$activity_data, theme.base, colors.wsj)
  settingsModule("settings", app_config$data_path, data$refresh_trigger)
  
  
  observeEvent(input$reset_filters, {
    data <- process_strava_data(input$data_path)$activities
    updateDateRangeInput(
      session,
      "date_range",
      start = min(data$start_date),
      end = Sys.Date()
    )
    updateSelectizeInput(session, "activity_type", selected = "all")
  })
}


shinyApp(ui = ui, server = server)
