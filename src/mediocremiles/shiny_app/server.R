#
# src/mediocremiles/shiny_app/server.R - Main server function.
#



appServer <- function(input, output, session) {
  options(DT.options = list(pageLength = 20))
  data_manager <- DataManager()
  
  data_manager$load_data()
  
  activity_data <- reactive({
    input$refresh_data
    
    data_manager$filter_activities(input$date_range, input$activity_type)
  })
  
  output$download <- downloadHandler(
    filename = function() {
      paste0("strava_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(activity_data(), file, row.names = F)
    }
  )
  
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
  })
  
  observeEvent(input$reset_filters, {
    updateDateRangeInput(
      session,
      "date_range",
      start = data_manager$get_earliest_date(),
      end = Sys.Date())
    updateSelectizeInput(session, "activity_type", selected = "all")
  })
  
  observeEvent(input$save_settings, {
    data_manager$set_data_path(input$data_path)
    showNotification("Settings saved", type = "message")
  })
  
  observeEvent(input$upload_json, {
    req(input$upload_json)
    
    file.copy(
      input$upload_json$datapath, 
      data_manager$get_data_path(), 
      overwrite = T)
    
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
  
  dashboard_module(input, output, session, activity_data)
  training_module(input, output, session, activity_data, data_manager)
  trends_module(input, output, session, activity_data)
  settings_module(input, output, session, data_manager)
}