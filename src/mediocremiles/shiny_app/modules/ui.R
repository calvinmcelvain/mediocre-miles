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
      width = 300,
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
        dashboardTabUI(),
        activitiesTabUI(),
        trainingTabUI(),
        trendsTabUI(),
        settingsTabUI()
      )
    )
  )
}



sidebarMenuUI <- function() {
  sidebarMenu(
    id = "sidebar",
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Activities", tabName = "activities", icon = icon("running")),
    menuItem("Training Load", tabName = "training", icon = icon("chart-line")),
    menuItem("Trends", tabName = "trends", icon = icon("chart-area")),
    menuItem("Settings", tabName = "settings", icon = icon("cog"))
  )
}



dateFilterUI <- function() {
  dateRangeInput(
    "date_range", 
    "Filter by Date:",
    start = Sys.Date() - 365,
    end = Sys.Date(),
    max = Sys.Date()
  )
}



activityTypeFilterUI <- function() {
  selectizeInput(
    "activity_type", 
    "Activity Type:", 
    choices = c("All" = "all"),
    multiple = F,
    selected = "all"
  )
}



dashboardTabUI <- function() {
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
                "Total Weekly Distance", 
                style = "font-family: monospace; font-weight: bold;"),
              width = 12,
              plotlyOutput("weekly_summary_plot") %>% withSpinner()
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
  )
}



activitiesTabUI <- function() {
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
  )
}



trainingTabUI <- function() {
  tabItem(tabName = "training",
          fluidRow(
            box(
              title = "Training Load Over Time",
              status = "warning",
              solidHeader = T,
              width = 12,
              plotOutput("training_load_plot", height = "300px") %>% withSpinner()
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
  )
}



trendsTabUI <- function() {
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
  )
}

# Settings tab UI
settingsTabUI <- function() {
  tabItem(tabName = "settings",
          fluidRow(
            box(
              title = "Data Settings",
              status = "primary",
              solidHeader = T,
              width = 12,
              fileInput("upload_json", "Upload Strava Data (JSON):", accept = ".json"),
              textInput("data_path", "Data File Path:", value = DEFAULT_DATA_PATH),
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
              HTML(
              "<p>Mediocre Miles is a dashboard for analyzing your Strava running data.</p>
              <p>Upload your Strava data export JSON file to get started.</p>
              <p>Created with R Shiny.</p>")
            )
          )
  )
}