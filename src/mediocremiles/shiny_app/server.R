#
# src/mediocremiles/shiny_app/server.R - Shiny app local server logic
#


appServer <- function(input, output, session) {
  data_manager <- DataManager()
  data_manager$load_data()
  
  activity_data <- reactive({
    input$refresh_data
    
    data_manager$filter_activities(
      date_range = input$date_range, 
      activity_type = input$activity_type,
      gear = input$gear_filter,
      weather_condition = input$weather_condition
    )
  })
  
  observe({
    updateSelectizeInput(
      session, 
      "activity_type",
      choices = data_manager$get_activity_types(),
      selected = "all")
    
    updateDateRangeInput(
      session,
      "date_range",
      start = data_manager$get_earliest_date(),
      end = Sys.Date())
    
    updateSelectInput(
      session,
      "gear_filter",
      choices = data_manager$get_gear_options(),
      selected = "all")
    
    updateSelectInput(
      session,
      "weather_condition",
      choices = data_manager$get_weather_conditions(),
      selected = "all")
  })
  
  observeEvent(input$reset_filters, {
    updateDateRangeInput(
      session,
      "date_range",
      start = data_manager$get_earliest_date(),
      end = Sys.Date())
    
    updateSelectizeInput(session, "activity_type", selected = "all")
    updateSelectInput(session, "gear_filter", selected = "all")
    updateSelectInput(session, "weather_condition", selected = "all")
  })
  
  observeEvent(input$save_settings, {
    data_manager$set_data_path(input$data_path)
    showNotification("Settings saved", type = "message")
  })
  
  observeEvent(input$save_preferences, {
    showNotification("Preferences saved", type = "message")
  })
  
  observeEvent(input$upload_json, {
    req(input$upload_json)
    
    file.copy(
      input$upload_json$datapath, 
      data_manager$get_data_path(), 
      overwrite = TRUE)
    
    showNotification("File uploaded successfully", type = "message")
    data_manager$load_data()
  })
  
  observeEvent(input$refresh_data, {
    data_manager$load_data()
  })
  
  output$data_notification <- renderUI({
    if (!is.null(data_manager$get_error_message())) {
      div(class = "alert alert-danger",
          icon("exclamation-triangle"),
          data_manager$get_error_message())
    } else if (!data_manager$is_loaded()) {
      div(class = "alert alert-warning",
          icon("spinner", class = "fa-spin"),
          "Loading data...")
    } else if (nrow(activity_data()) == 0) {
      div(class = "alert alert-warning",
          icon("exclamation-triangle"),
          "No activities found with current filters")
    } else {
      return(NULL)
    }
  })
  
  recent_activity_overview_module(input, output, session, activity_data, data_manager)
  activity_details_module(input, output, session, activity_data)
  
  # Call additional modules for other tabs
  # training_load_module(input, output, session, activity_data, data_manager)
  # performance_overview_module(input, output, session, activity_data)
  # gear_analysis_module(input, output, session, activity_data)
  # weather_impact_module(input, output, session, activity_data)
  # settings_module(input, output, session, data_manager)
}