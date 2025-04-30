# 
# app.R - Main application entry point.
# This file loads necessary components and starts the Shiny app.
# 



source("global.R")



ui <- dashboardPage(
  skin = "purple",
  
  dashboardHeader(
    title = span(icon("running"), "Mediocre Miles"),
    titleWidth = 300
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenuUI("sidebarMenu"),
    dateRangeFilterUI("dateFilter"),
    activityTypeFilterUI("activityFilter"),
    actionButton(
      "reset_filters", 
      "Reset Filters", 
      icon = icon("sync")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    uiOutput("data_notification"),
    
    tabItems(
      dashboardTabUI("dashboardTab"),
      activitiesTabUI("activitiesTab"),
      trainingTabUI("trainingTab"),
      trendsTabUI("trendsTab"),
      settingsTabUI("settingsTab")
    )
  )
)



server <- function(input, output, session) {
  app_data <- reactiveValues(
    data_path = getOption("strava_data_path", "data/strava_data.json"),
    data_loaded = FALSE,
    error_message = NULL
  )
  
  data_source <- dataSourceServer(
    "dataSource", 
    app_data = app_data
  )
  
  observeEvent(input$reset_filters, {
    resetFiltersServer("dateFilter", "activityFilter", data_source$raw_data)
  })
  
  date_filter <- dateRangeFilterServer("dateFilter", data_source$raw_data)
  activity_filter <- activityTypeFilterServer("activityFilter", data_source$raw_data)
  
  filtered_data <- reactive({
    req(data_source$raw_data())
    
    data <- data_source$raw_data()$activities
    
    if (!is.null(date_filter$date_range())) {
      date_range <- date_filter$date_range()
      data <- data %>%
        filter(as.Date(start_date) >= date_range[1] & as.Date(start_date) <= date_range[2])
    }
    
    if (!is.null(activity_filter$selected_types()) && 
        !("all" %in% activity_filter$selected_types())) {
      data <- data %>% 
        filter(activity_type %in% activity_filter$selected_types())
    }
    
    return(data)
  })
  
  output$data_notification <- renderUI({
    if (!is.null(app_data$error_message)) {
      div(class = "alert alert-danger",
          icon("exclamation-triangle"),
          app_data$error_message)
    } else if (!app_data$data_loaded) {
      div(class = "alert alert-warning",
          icon("spinner", class = "fa-spin"),
          "Loading data...")
    } else if (nrow(filtered_data()) == 0) {
      div(class = "alert alert-warning",
          icon("exclamation-triangle"),
          "No activities found with current filters")
    } else {
      return(NULL)
    }
  })
  
  dashboardTabServer("dashboardTab", filtered_data)
  activitiesTabServer("activitiesTab", filtered_data)
  trainingTabServer("trainingTab", filtered_data, data_source$raw_data)
  trendsTabServer("trendsTab", filtered_data)
  settingsTabServer("settingsTab", app_data, data_source$refresh_data)
}



shinyApp(ui = ui, server = server)
