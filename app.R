repos <- "https://cran.rstudio.com"
options(repos=repos)


required_packages <- c("shiny", "shinydashboard", "ggplot2", "dplyr", "lubridate", 
                      "jsonlite", "zoo", "here", "scales", "DT", "shinyWidgets", 
                      "shinycssloaders", "plotly")

install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages)
}


install_if_missing(required_packages)


library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinycssloaders)
library(ggplot2)
library(dplyr)
library(lubridate)
library(here)
library(DT)
library(scales)


tryCatch({
  setwd(here())
}, error = function(e) {
  message("Note: Working with current directory. For best results, run from project root.")
})

source_files <- c(
  "src/mediocremiles/data_import.R",
  "src/mediocremiles/plot_configs.R",
  "src/mediocremiles/analysis/training_load.R",
  "src/mediocremiles/analysis/trends.R",
  "src/mediocremiles/visualizations/activity_charts.R",
  "src/mediocremiles/visualizations/weekly_summary.R"
)

for(file in source_files) {
  tryCatch({
    source(file)
  }, error = function(e) {
    message(paste("Error loading:", file, "\nError:", e$message))
  })
}


ui <- dashboardPage(
  skin = "purple",
  
  dashboardHeader(
    title = span(icon("running"), "Mediocre Miles"),
    titleWidth = 300
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Activities", tabName = "activities", icon = icon("running")),
      menuItem("Training Load", tabName = "training", icon = icon("chart-line")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-area")),
      menuItem("Settings", tabName = "settings", icon = icon("cog"))
    ),
    
    dateRangeInput(
      "date_range", 
      "Filter by Date:",
      start = min(import_activity_data()$start_date),
      end = Sys.Date(),
      max = Sys.Date()
    ),
    
    selectizeInput(
      "activity_type", 
      "Activity Type:", 
      choices = c("All" = "all", unique(import_activity_data()$activity_type)),
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
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("total_activities", width = 3),
                valueBoxOutput("total_distance_miles", width = 3),
                valueBoxOutput("total_distance_km", width = 3),
                valueBoxOutput("total_time", width = 3)
              ),
              fluidRow(
                box(
                  title = div(
                    "Total Weekly distance (last 12 weeks)", 
                    style = "font-family: monospace; font-weight: bold;"),
                  width = 12,
                  plotOutput("weekly_summary_plot") %>% withSpinner()
                )
              ),
              fluidRow(
                box(
                  title = div(
                    "Recent Activities", 
                    style = "font-family: monospace; font-weight: bold;"),
                  width = 12,
                  DTOutput("recent_activities_table") %>% withSpinner()
                )
              )
      ),
      
      tabItem(tabName = "activities",
              fluidRow(
                box(
                  title = "Activity Distribution",
                  status = "info",
                  solidHeader = T,
                  collapsible = T,
                  width = 6,
                  plotOutput("activity_distribution") %>% withSpinner()
                ),
                box(
                  title = "Activity Details",
                  status = "info",
                  solidHeader = T,
                  collapsible = T,
                  width = 6,
                  plotOutput("activity_details") %>% withSpinner()
                )
              ),
              fluidRow(
                box(
                  title = "Activity Pace vs. Distance",
                  status = "info",
                  collapsible = T,
                  width = 6,
                  plotOutput("pace_vs_distance") %>% withSpinner()
                ),
                box(
                  title = "Activity Heart Rate vs. Pace",
                  status = "info",
                  solidHeader = T,
                  collapsible = T,
                  width = 6,
                  plotOutput("hr_vs_pace") %>% withSpinner()
                )
              )
      ),
      
      tabItem(tabName = "training",
              fluidRow(
                box(
                  title = "Training Load Over Time",
                  status = "warning",
                  solidHeader = T,
                  width = 12,
                  plotOutput("training_load_plot", height = "300px") %>% 
                    withSpinner()
                )
              ),
              fluidRow(
                box(
                  title = "Heart Rate Zones",
                  status = "warning",
                  solidHeader = T,
                  width = 6,
                  plotOutput("hr_zones_plot") %>% withSpinner()
                ),
                box(
                  title = "Power Zones",
                  status = "warning", 
                  solidHeader = T,
                  width = 6,
                  plotOutput("power_zones_plot") %>% withSpinner()
                )
              ),
              fluidRow(
                box(
                  title = "Weekly Training Summary",
                  status = "warning",
                  solidHeader = T,
                  width = 12,
                  plotOutput("weekly_training_load") %>% withSpinner()
                )
              )
      ),
      
      tabItem(tabName = "trends",
              fluidRow(
                box(
                  title = "Performance Trends",
                  status = "success",
                  solidHeader = T,
                  width = 12,
                  radioButtons(
                    "trend_metric", "Metric:",
                    choices = c("Average Pace" = "pace", 
                               "Average Heart Rate" = "hr", 
                               "Distance" = "distance"),
                    selected = "pace",
                    inline = T
                  ),
                  plotOutput("performance_trends") %>% withSpinner()
                )
              ),
              fluidRow(
                box(
                  title = "Seasonal Patterns",
                  status = "success",
                  solidHeader = T,
                  width = 6,
                  plotOutput("seasonal_patterns") %>% withSpinner()
                ),
                box(
                  title = "Year-over-Year Comparison",
                  status = "success",
                  solidHeader = T,
                  width = 6,
                  plotOutput("yoy_comparison") %>% withSpinner()
                )
              )
      ),
      
      tabItem(tabName = "settings",
              fluidRow(
                box(
                  title = "Data Settings",
                  status = "primary",
                  solidHeader = T,
                  width = 12,
                  fileInput("upload_json", "Upload Strava Data (JSON):", accept = ".json"),
                  textInput("data_path", "Data File Path:", value = "data/strava_data.json"),
                  actionButton("save_settings", "Save Settings", icon = icon("save")),
                  actionButton("refresh_data", "Refresh Data", icon = icon("sync"))
                )
              ),
              fluidRow(
                box(
                  title = "About",
                  status = "primary",
                  solidHeader = T,
                  width = 12,
                  HTML("<p>Mediocre Miles is a dashboard for analyzing your Strava running data.</p>
                        <p>Upload your Strava data export JSON file to get started.</p>
                        <p>Created with R Shiny.</p>")
                )
              )
      )
    )
  )
)


server <- function(input, output, session) {
  values <- reactiveValues(
    data_path = "data/strava_data.json",
    data_loaded = F,
    error_message = NULL
  )
  
  load_data <- function() {
    tryCatch({
      values$error_message <- NULL
      
      data <- import_activity_data()
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
    
    data <- load_data()
    
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
  
  observeEvent(input$reset_filters, {
    data <- import_activity_data()
    updateDateRangeInput(
      session,
      "date_range",
      start = min(data$start_date),
      end = Sys.Date()
    )
    updateSelectizeInput(session, "activity_type", selected = "all")
  })
  
  observeEvent(input$save_settings, {
    values$data_path <- input$data_path
    showNotification("Settings saved", type = "message")
    
    values$data_loaded <- F
  })
  
  observeEvent(input$upload_json, {
    req(input$upload_json)
    
    file.copy(input$upload_json$datapath, values$data_path, overwrite = T)
    
    showNotification("File uploaded successfully", type = "message")
    
    values$data_loaded <- F
  })
  
  output$data_notification <- renderUI({
    if(!is.null(values$error_message)) {
      div(class = "alert alert-danger",
          icon("exclamation-triangle"),
          values$error_message)
    } else if(!values$data_loaded) {
      div(class = "alert alert-warning",
          icon("spinner", class = "fa-spin"),
          "Loading data...")
    } else if(nrow(activity_data()) == 0) {
      div(class = "alert alert-warning",
          icon("exclamation-triangle"),
          "No activities found with current filters")
    } else {
      return(NULL)
    }
  })
  
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
  
  output$activity_distribution <- renderPlot({
    data <- activity_data()
    generate_activity_distribution_plot(data, theme.base)
  })
  
  output$activity_details <- renderPlot({
    data <- activity_data()
    generate_activity_details_plot(data, theme.base)
  })
  
  # Pace vs distance plot
  output$pace_vs_distance <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if("average_speed_kmh" %in% names(data) && "distance_km" %in% names(data) && "id" %in% names(data)) {
      # De-duplicate split data
      pace_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        # Convert speed to pace (minutes per km)
        mutate(pace_min_km = 60 / average_speed_kmh)
      
      ggplot(pace_data, aes(x = distance_km, y = pace_min_km)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(method = "loess", se = T, color = "#3498db") +
        labs(x = "Distance (km)", y = "Pace (min/km)", title = "Pace vs. Distance") +
        theme_minimal() +
        scale_y_continuous(labels = function(x) sprintf("%.1f", x))
    } else {
      # Placeholder if data not available
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Speed data not available") +
        theme_void()
    }
  })
  
  # Heart rate vs pace plot
  output$hr_vs_pace <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if("average_heartrate" %in% names(data) && "average_speed_kmh" %in% names(data) && "id" %in% names(data)) {
      # De-duplicate split data
      hr_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.na(average_heartrate)) %>%
        # Convert speed to pace (minutes per km)
        mutate(pace_min_km = 60 / average_speed_kmh)
      
      ggplot(hr_data, aes(x = pace_min_km, y = average_heartrate)) +
        geom_point(aes(color = activity_type), alpha = 0.7) +
        geom_smooth(method = "lm", se = T, color = "#3498db") +
        labs(x = "Pace (min/km)", y = "Heart Rate (bpm)", title = "Heart Rate vs. Pace") +
        theme_minimal() +
        scale_x_continuous(labels = function(x) sprintf("%.1f", x))
    } else {
      # Placeholder if data not available
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Heart rate data not available") +
        theme_void()
    }
  })
  
  # Training load plot
  output$training_load_plot <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if(exists("generate_training_load_plot")) {
      generate_training_load_plot(data)
    } else {
      # Simple training load calculation (distance * time)
      if("distance_km" %in% names(data) && "total_moving_time_seconds" %in% names(data) && 
         "id" %in% names(data) && "start_date" %in% names(data)) {
        
        # De-duplicate split data
        load_data <- data %>%
          group_by(id) %>%
          slice(1) %>%
          ungroup() %>%
          mutate(
            date = as.Date(start_date),
            # Simple training load score
            training_load = distance_km * (total_moving_time_seconds / 3600)
          ) %>%
          arrange(date)
        
        # Calculate rolling average
        load_data$rolling_load <- zoo::rollmean(load_data$training_load, 7, fill = NA, align = "right")
        
        ggplot(load_data, aes(x = date)) +
          geom_bar(aes(y = training_load), stat = "identity", fill = "#f39c12", alpha = 0.5) +
          geom_line(aes(y = rolling_load), size = 1, color = "#e74c3c") +
          labs(x = "Date", y = "Training Load", title = "Training Load Over Time") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        # Placeholder if data not available
        ggplot() + 
          annotate("text", x = 0, y = 0, label = "Training load data not available") +
          theme_void()
      }
    }
  })
  
  # Heart rate zones plot
  output$hr_zones_plot <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if(exists("generate_hr_zones_plot")) {
      generate_hr_zones_plot(data)
    } else if("average_heartrate" %in% names(data) && "id" %in% names(data)) {
      # De-duplicate split data
      hr_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.nafilter(!is.na(average_heartrate)))
      
      # Define heart rate zones (estimated)
      hr_data <- hr_data %>%
        mutate(hr_zone = case_when(
          average_heartrate < 125 ~ "Zone 1: Recovery",
          average_heartrate < 140 ~ "Zone 2: Aerobic",
          average_heartrate < 155 ~ "Zone 3: Tempo",
          average_heartrate < 170 ~ "Zone 4: Threshold",
          T ~ "Zone 5: Maximum"
        ))
      
      # Count activities in each zone
      zone_counts <- hr_data %>%
        count(hr_zone) %>%
        mutate(hr_zone = factor(hr_zone, levels = c(
          "Zone 1: Recovery", "Zone 2: Aerobic", "Zone 3: Tempo", 
          "Zone 4: Threshold", "Zone 5: Maximum"
        )))
      
      ggplot(zone_counts, aes(x = hr_zone, y = n, fill = hr_zone)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c(
          "Zone 1: Recovery" = "#3498db",
          "Zone 2: Aerobic" = "#2ecc71",
          "Zone 3: Tempo" = "#f39c12",
          "Zone 4: Threshold" = "#e67e22",
          "Zone 5: Maximum" = "#e74c3c"
        )) +
        labs(x = "Heart Rate Zone", y = "Count", title = "Activities by Heart Rate Zone") +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      # Placeholder if data not available
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Heart rate zone data not available") +
        theme_void()
    }
  })
  
  # Power zones plot
  output$power_zones_plot <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if(exists("generate_power_zones_plot")) {
      generate_power_zones_plot(data)
    } else if("weighted_average_power" %in% names(data) && "id" %in% names(data)) {
      # De-duplicate split data
      power_data <- data %>%
        group_by(id) %>%
        slice(1) %>%
        ungroup() %>%
        filter(!is.na(weighted_average_power))
      
      # Define power zones (estimated)
      power_data <- power_data %>%
        mutate(power_zone = case_when(
          weighted_average_power < 150 ~ "Zone 1: Recovery",
          weighted_average_power < 200 ~ "Zone 2: Endurance",
          weighted_average_power < 250 ~ "Zone 3: Tempo",
          weighted_average_power < 300 ~ "Zone 4: Threshold",
          weighted_average_power < 350 ~ "Zone 5: VO2 Max",
          T ~ "Zone 6: Anaerobic"
        ))
      
      # Count activities in each zone
      zone_counts <- power_data %>%
        count(power_zone) %>%
        mutate(power_zone = factor(power_zone, levels = c(
          "Zone 1: Recovery", "Zone 2: Endurance", "Zone 3: Tempo", 
          "Zone 4: Threshold", "Zone 5: VO2 Max", "Zone 6: Anaerobic"
        )))
      
      ggplot(zone_counts, aes(x = power_zone, y = n, fill = power_zone)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c(
          "Zone 1: Recovery" = "#3498db",
          "Zone 2: Endurance" = "#2ecc71",
          "Zone 3: Tempo" = "#f39c12",
          "Zone 4: Threshold" = "#e67e22",
          "Zone 5: VO2 Max" = "#e74c3c",
          "Zone 6: Anaerobic" = "#9b59b6"
        )) +
        labs(x = "Power Zone", y = "Count", title = "Activities by Power Zone") +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      # Placeholder if data not available
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Power data not available") +
        theme_void()
    }
  })
  
  # Weekly training load
  output$weekly_training_load <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
    if("id" %in% names(data) && "start_date" %in% names(data)) {
      # Calculate a simple weekly training load
      if("distance_km" %in% names(data) && "total_moving_time_seconds" %in% names(data)) {
        weekly_load <- data %>%
          group_by(id) %>%
          slice(1) %>%  # Take first row to avoid duplicates from splits
          ungroup() %>%
          mutate(
            week = floor_date(as.Date(start_date), "week"),
            # Simple load calculation
            load = distance_km * (total_moving_time_seconds / 3600)
          ) %>%
          group_by(week) %>%
          summarize(
            weekly_load = sum(load, na.rm = T),
            .groups = "drop"
          )
        
        ggplot(weekly_load, aes(x = week, y = weekly_load)) +
          geom_bar(stat = "identity", fill = "#f39c12") +
          geom_line(aes(group = 1), color = "#e74c3c", size = 1) +
          labs(x = "Week", y = "Training Load", title = "Weekly Training Load") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        # Fallback to activity count by week if load can't be calculated
        weekly_count <- data %>%
          group_by(id) %>%
          slice(1) %>%  # Take first row to avoid duplicates from splits
          ungroup() %>%
          mutate(week = floor_date(as.Date(start_date), "week")) %>%
          count(week)
        
        ggplot(weekly_count, aes(x = week, y = n)) +
          geom_bar(stat = "identity", fill = "#f39c12") +
          labs(x = "Week", y = "Activity Count", title = "Weekly Activities") +
          theme_minimal() +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    } else {
      # Placeholder if data not available
      ggplot() + 
        annotate("text", x = 0, y = 0, label = "Weekly training data not available") +
        theme_void()
    }
  })
  
  # Performance trends plot
  output$performance_trends <- renderPlot({
    data <- activity_data()
    
    req(values$data_loaded, nrow(data) > 0)
    
      # De-duplicate split data
      trend_data <- data %>% distinct(id, .keep_all = T) 
      
      if(input$trend_metric == "pace") {
        trend_data$pace_min_mile <- 60 / trend_data$average_speed_mph
        filtered_trend_data <- trend_data %>% filter(activity_type == "Run")
        
        ggplot(filtered_trend_data, aes(x = date, y = pace_min_mile)) +
          geom_point(aes(color = activity_type), alpha = 0.7, color = colors.wsj[6]) +
          geom_smooth(method = "loess", color = colors.wsj[3], fill = colors.wsj[3]) +
          labs(x = NULL, y = "Pace (min/mile)") +
          theme.base +
          scale_y_continuous(labels = function(x) sprintf("%.1f", x)) +
          scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else if(input$trend_metric == "hr") {
        ggplot(trend_data, aes(x = date, y = average_heartrate)) +
          geom_point(aes(color = activity_type), alpha = 0.7) +
          geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
          scale_color_wsj() +
          scale_fill_wsj() +
          labs(x = NULL, y = "Heart Rate (bpm)", color = "Activity Type", fill = "Activity Type") +
          theme.base +
          scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else if(input$trend_metric == "distance" && "distance_km" %in% names(trend_data)) {
        trend_data.2 <- trend_data %>% filter(distance_miles > 1)
        ggplot(trend_data.2, aes(x = date, y = distance_miles)) +
          geom_point(aes(color = activity_type), alpha = 0.7) +
          geom_smooth(aes(color = activity_type, fill = after_scale(color)), method = "loess") +
          scale_color_wsj() +
          scale_fill_wsj() +
          labs(x = NULL, y = "Distance (miles)", color = "Activity Type", fill = "Activity Type") +
          theme.base +
          scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        # Placeholder if selected metric not available
        ggplot() + 
          annotate("text", x = 0, y = 0, label = "Selected metric data not available") +
          theme_void()
      }
  })
  
  # Seasonal patterns plot
  output$seasonal_patterns <- renderPlot({
    data <- activity_data()
    generate_seasonal_patterns_plot(data, theme.base, colors.wsj)
  })
  
  # Year-over-year comparison plot
  output$yoy_comparison <- renderPlot({
    data <- activity_data()
    generate_yoy_comparison_plot(data, theme.base)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
