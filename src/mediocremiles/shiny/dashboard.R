#
# Dashboard module.
#



dashboardModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      valueBoxOutput(ns("total_activities"), width = 3),
      valueBoxOutput(ns("total_distance_miles"), width = 3),
      valueBoxOutput(ns("total_distance_km"), width = 3),
      valueBoxOutput(ns("total_time"), width = 3)
    ),
    fluidRow(
      box(
        title = div("Total Weekly distance (last 12 weeks)", 
                   style = "font-family: monospace; font-weight: bold;"),
        width = 12,
        plotOutput(ns("weekly_summary_plot")) %>% withSpinner()
      )
    ),
    fluidRow(
      box(
        title = div("Recent Activities", 
                   style = "font-family: monospace; font-weight: bold;"),
        width = 12,
        DTOutput(ns("recent_activities_table")) %>% withSpinner()
      )
    )
  )
}


dashboardModule <- function(id, activity_data, theme.base, colors.wsj) {
  moduleServer(id, function(input, output, session) {
    
    output$total_activities <- renderValueBox({
      data <- activity_data()
      
      if(values$data_loaded && nrow(data) > 0) {t
        if("id" %in% names(data)) {
          count <- length(unique(data$id))
        } else {
          count <- nrow(data)
        }
      } else {
        count <- 0
      }
      
      valueBox(
        count, 
        "Total Strava Activities",
        icon = icon("running"),
        color = "orange"
      )
    })
    
    output$total_distance_km <- renderValueBox({
      data <- activity_data()
      
      if(values$data_loaded && nrow(data) > 0) {
        total_km <- data %>% 
          group_by(id) %>% 
          summarize(distance = first(distance_km)) %>% 
          pull(distance) %>% 
          sum(na.rm = T)
      } else {
        total_km <- 0
      }
      
      valueBox(
        sprintf("%.1f km", total_km),
        "Total Distance",
        icon = icon("road"),
        color = "green"
      )
    })
    
    output$total_distance_miles <- renderValueBox({
      data <- activity_data()
      
      if(values$data_loaded && nrow(data) > 0) {
        total_miles <- data %>% 
          group_by(id) %>% 
          summarize(distance = first(distance_miles)) %>% 
          pull(distance) %>% 
          sum(na.rm = T)
      } else {
        total_miles <- 0
      }
      
      valueBox(
        sprintf("%.1f mi", total_miles),
        "Total Distance",
        icon = icon("road"),
        color = "olive"
      )
    })
    
    output$total_time <- renderValueBox({
      data <- activity_data()
      
      if(values$data_loaded && nrow(data) > 0) {
        total_seconds <- data %>% 
          group_by(id) %>% 
          summarize(time = first(total_moving_time_seconds)) %>% 
          pull(time) %>% 
          sum(na.rm = T)
        
        hours <- floor(total_seconds / 3600)
        minutes <- floor((total_seconds - hours * 3600) / 60)
        time_str <- sprintf("%d:%02d", hours, minutes)
      } else {
        time_str <- "0:00"
      }
      
      valueBox(
        time_str,
        "Total Time",
        icon = icon("clock"),
        color = "purple"
      )
    })
    
    output$weekly_summary_plot <- renderPlot({
      generate_weekly_summary_plot(activity_data(), theme.base, colors.wsj)
    })
    
    output$recent_activities_table <- renderDT({
      data <- activity_data()
      generate_recent_activities_table(data)
    })
  })
}