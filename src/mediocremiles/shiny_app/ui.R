#
# src/mediocremiles/shiny_app/modules/ui.R - Shiny app UI components
#


appUI <- function() {
  dashboardPage(
    skin = "purple",
    dashboardHeader(
      title = span(icon("running"), "Mediocre Miles"),
      titleWidth = 300
    ),
    dashboardSidebar(
      width = 230,
      sidebarMenuUI(),
      dateFilterUI(),
      activityTypeFilterUI(),
      actionButton(
        "reset_filters", 
        "Reset Filters", 
        icon = icon("sync")
      )
    ),
    dashboardBody(
      uiOutput("data_notification"),
      tabItems(
        recentActivityTabUI(),
        performanceTabUI(),
        gearTabUI(),
        weatherTabUI(),
        settingsTabUI()
      )
    )
  )
}

sidebarMenuUI <- function() {
  sidebarMenu(
    id = "sidebar",
    menuItem("Recent Activity", tabName = "recent_activity", icon = icon("dashboard"),
             menuSubItem("Overview", tabName = "recent_overview"),
             menuSubItem("Activity Details", tabName = "recent_details"),
             menuSubItem("Training Load", tabName = "recent_training")),
    menuItem("Performance", tabName = "performance", icon = icon("chart-line"),
             menuSubItem("Overview", tabName = "performance_overview"),
             menuSubItem("Yearly Trends", tabName = "performance_yearly"),
             menuSubItem("Seasonal Patterns", tabName = "performance_seasonal")),
    menuItem("Gear Analysis", tabName = "gear", icon = icon("tshirt"),
             menuSubItem("Overview", tabName = "gear_overview"),
             menuSubItem("Comparison", tabName = "gear_comparison")),
    menuItem("Weather Impact", tabName = "weather", icon = icon("cloud-sun"),
             menuSubItem("Overview", tabName = "weather_overview"),
             menuSubItem("Performance Impact", tabName = "weather_impact")),
    menuItem("Settings", tabName = "settings", icon = icon("cog"))
  )
}


recentActivityTabUI <- function() {
  tabItems(
    tabItem(tabName = "recent_overview",
            h2("Recent Activity Overview"),
            fluidRow(
              valueBoxOutput("total_recent_activities", width = 3),
              valueBoxOutput("recent_distance", width = 3),
              valueBoxOutput("recent_time", width = 3),
              valueBoxOutput("recent_elevation", width = 3)
            ),
            fluidRow(
              box(
                title = "Weekly Summary", 
                width = 12,
                plotlyOutput("recent_weekly_summary") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Recent Activities",
                width = 12,
                DTOutput("recent_activities_table") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "recent_details",
            h2("Activity Details"),
            fluidRow(
              box(
                title = "Activity Selection",
                width = 12,
                selectInput("selected_activity", "Select Activity:", choices = NULL)
              )
            ),
            fluidRow(
              valueBoxOutput("activity_date", width = 3),
              valueBoxOutput("activity_distance", width = 3),
              valueBoxOutput("activity_time", width = 3),
              valueBoxOutput("activity_pace", width = 3)
            ),
            fluidRow(
              box(
                title = "Pace Analysis",
                width = 6,
                plotOutput("activity_pace_chart") %>% withSpinner()
              ),
              box(
                title = "Heart Rate Analysis",
                width = 6,
                plotOutput("activity_hr_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Elevation Profile",
                width = 12,
                plotOutput("activity_elevation") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "recent_training",
            h2("Training Load Analysis"),
            fluidRow(
              valueBoxOutput("acute_load", width = 4),
              valueBoxOutput("chronic_load", width = 4),
              valueBoxOutput("training_stress", width = 4)
            ),
            fluidRow(
              box(
                title = "Training Load Trend",
                width = 12,
                plotOutput("training_load_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Weekly Training Summary",
                width = 6,
                plotOutput("weekly_volume_chart") %>% withSpinner()
              ),
              box(
                title = "Training Intensity",
                width = 6,
                plotOutput("training_intensity_chart") %>% withSpinner()
              )
            )
    )
  )
}


performanceTabUI <- function() {
  tabItems(
    tabItem(tabName = "performance_overview",
            h2("Performance Overview"),
            fluidRow(
              box(
                title = "Performance Metrics",
                width = 12,
                selectInput("performance_metric", "Select Metric:",
                            choices = c("Pace" = "pace", 
                                      "Heart Rate" = "hr",
                                      "Distance" = "distance",
                                      "Elevation" = "elevation")),
                plotOutput("performance_overview_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Recent PRs",
                width = 6,
                DTOutput("recent_prs_table") %>% withSpinner()
              ),
              box(
                title = "Performance Distribution",
                width = 6,
                plotOutput("performance_distribution") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "performance_yearly",
            h2("Yearly Performance Trends"),
            fluidRow(
              box(
                title = "Year-over-Year Comparison",
                width = 12,
                selectInput("yoy_metric", "Select Metric:",
                           choices = c("Distance" = "distance",
                                     "Time" = "time",
                                     "Pace" = "pace")),
                plotOutput("yoy_comparison_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Annual Stats",
                width = 12,
                DTOutput("annual_stats_table") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "performance_seasonal",
            h2("Seasonal Performance Patterns"),
            fluidRow(
              box(
                title = "Monthly Patterns",
                width = 12,
                plotOutput("monthly_patterns_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Day of Week Patterns",
                width = 6,
                plotOutput("dow_patterns_chart") %>% withSpinner()
              ),
              box(
                title = "Time of Day Patterns",
                width = 6,
                plotOutput("tod_patterns_chart") %>% withSpinner()
              )
            )
    )
  )
}


gearTabUI <- function() {
  tabItems(
    tabItem(tabName = "gear_overview",
            h2("Gear Usage Overview"),
            fluidRow(
              box(
                title = "Gear Selection",
                width = 12,
                selectInput("gear_filter", "Filter by Gear:", choices = NULL)
              )
            ),
            fluidRow(
              valueBoxOutput("gear_usage_count", width = 4),
              valueBoxOutput("gear_total_distance", width = 4),
              valueBoxOutput("gear_lifetime", width = 4)
            ),
            fluidRow(
              box(
                title = "Gear Usage Over Time",
                width = 12,
                plotOutput("gear_usage_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Activity Details with Selected Gear",
                width = 12,
                DTOutput("gear_activities_table") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "gear_comparison",
            h2("Gear Performance Comparison"),
            fluidRow(
              box(
                title = "Performance Metric",
                width = 12,
                selectInput("gear_metric", "Compare by:",
                           choices = c("Pace" = "pace",
                                     "Heart Rate" = "heartrate",
                                     "Distance" = "distance"))
              )
            ),
            fluidRow(
              box(
                title = "Gear Comparison",
                width = 12,
                plotOutput("gear_comparison_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Comparison Statistics",
                width = 12,
                DTOutput("gear_comparison_table") %>% withSpinner()
              )
            )
    )
  )
}


weatherTabUI <- function() {
  tabItems(
    tabItem(tabName = "weather_overview",
            h2("Weather Impact Overview"),
            fluidRow(
              box(
                title = "Weather Filters",
                width = 12,
                selectInput("weather_condition", "Filter by Condition:", choices = NULL),
                sliderInput("temp_range", "Temperature Range (°F):", min = 0, max = 100, value = c(30, 90))
              )
            ),
            fluidRow(
              box(
                title = "Activities by Weather Condition",
                width = 6,
                plotOutput("weather_distribution_chart") %>% withSpinner()
              ),
              box(
                title = "Temperature Distribution",
                width = 6,
                plotOutput("temperature_distribution_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Activities in Selected Weather",
                width = 12,
                DTOutput("weather_activities_table") %>% withSpinner()
              )
            )
    ),
    
    tabItem(tabName = "weather_impact",
            h2("Weather Performance Impact"),
            fluidRow(
              box(
                title = "Performance Metric",
                width = 12,
                selectInput("weather_metric", "Analyze by:",
                           choices = c("Pace" = "pace",
                                     "Heart Rate" = "heartrate",
                                     "Perceived Exertion" = "effort"))
              )
            ),
            fluidRow(
              box(
                title = "Performance by Temperature",
                width = 6,
                plotOutput("temp_impact_chart") %>% withSpinner()
              ),
              box(
                title = "Performance by Weather Condition",
                width = 6,
                plotOutput("condition_impact_chart") %>% withSpinner()
              )
            ),
            fluidRow(
              box(
                title = "Optimal Weather Conditions",
                width = 12,
                verbatimTextOutput("optimal_conditions_summary")
              )
            )
    )
  )
}


settingsTabUI <- function() {
  tabItem(tabName = "settings",
          h2("Settings"),
          fluidRow(
            box(
              title = "Data Management",
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              fileInput("upload_json", "Upload Strava Data (JSON):", accept = ".json"),
              textInput("data_path", "Data File Path:", value = DEFAULT_DATA_PATH),
              actionButton("save_settings", "Save Settings", icon = icon("save")),
              actionButton("refresh_data", "Refresh Data", icon = icon("sync"))
            )
          ),
          fluidRow(
            box(
              title = "Preferences",
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              radioButtons("units_preference", "Preferred Units:",
                          choices = c("Miles" = "imperial", "Kilometers" = "metric"),
                          selected = "imperial"),
              selectInput("default_date_range", "Default Date Range:",
                         choices = c("Last 30 Days" = "30",
                                   "Last 90 Days" = "90",
                                   "Last 180 Days" = "180",
                                   "Last 365 Days" = "365",
                                   "All Time" = "all"),
                         selected = "30"),
              actionButton("save_preferences", "Save Preferences", icon = icon("save"))
            )
          ),
          fluidRow(
            box(
              title = "About",
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              HTML(
                "<p>Mediocre Miles is a dashboard for analyzing your Strava running data.</p>
                <p>Upload your Strava data export JSON file to get started.</p>
                <p>Created with R Shiny.</p>")
            )
          )
  )
}