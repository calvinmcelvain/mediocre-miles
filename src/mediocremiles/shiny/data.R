#
# Data module.
#


dataModule <- function(id, data_path) {
  moduleServer(id, function(input, output, session) {
    values <- reactiveValues(
      data_path = data_path,
      data_loaded = F,
      error_message = NULL
    )
    
    load_data <- function() {
      tryCatch({
        values$error_message <- NULL
        
        data <- process_strava_data(input$data_path)
        values$data_loaded <- T
        
        return(data)
      }, error = function(e) {
        values$error_message <- paste("Error loading data:", e$message)
        values$data_loaded <- F
        
        return(data.frame())
      })
    }
    
    activity_data <- reactive({
      input$refresh_data
      
      data <- load_data()$activities
      
      if(values$data_loaded && nrow(data) > 0 && "start_date" %in% names(data)) {
        date_range <- input$date_range
        
        data <- data %>%
          filter(as.Date(start_date) >= date_range[1] & as.Date(start_date) <= date_range[2])
        
        if(!is.null(input$activity_type) && !("all" %in% input$activity_type)) {
          data <- data %>% filter(activity_type %in% input$activity_type)
        }
      }
      
      return(data)
    })
    
    return(list(
      activity_data = activity_data,
      hr_zones_data = reactive({ load_data()$heart_rate_zones }),
      power_zones_data = reactive({ load_data()$power_zones }),
      athlete_stats_data = reactive({ load_data()$stats }),
      data_status = reactive({ list(
        loaded = values$data_loaded,
        error = values$error_message
      )})
    ))
  })
}