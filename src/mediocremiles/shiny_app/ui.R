#
# src/mediocremiles/shiny_app/modules/ui.R - Shiny app UI components
#


appUI <- function() {
  dashboardPage(
    skin = "black",
    dashboardHeader(
      title = span(icon("running"), "Mediocre Miles",
                   style = "font-family: monospace;"),
      titleWidth = 300),
    dashboardSidebar(
      width = 300,
      sidebarMenuUI(),
      dateFilterUI(),
      activityTypeFilterUI(),
      actionButton(
        "reset_filters", 
        div("Reset Filters", style = "font-family: monospace;"), 
        icon = icon("sync")
      )
    ),
    dashboardBody(
      uiOutput("data_notification"),
      tabItems(
        dashboardTabUI(),
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
    menuItem(div("Dashboard", style = "font-family: monospace;"), 
             tabName = "dashboard", icon = icon("dashboard")),
    menuItem(div("Training & Performance", style = "font-family: monospace; "),
             tabName = "training", icon = icon("chart-line")),
    menuItem(div("Trends", style = "font-family: monospace;"),
             tabName = "trends", icon = icon("chart-area")),
    menuItem(div("Settings", style = "font-family: monospace;"),
             tabName = "settings", icon = icon("cog"))
  )
}



dateFilterUI <- function() {
  dateRangeInput(
    "date_range", 
    div("Filter by Date", style = "font-family: monospace;"),
    start = Sys.Date() - 365,
    end = Sys.Date(),
    max = Sys.Date()
  )
}



activityTypeFilterUI <- function() {
  selectizeInput(
    "activity_type", 
    div("Activity Type", style = "font-family: monospace;"), 
    choices = c("All" = "all"),
    multiple = F,
    selected = "all"
  )
}



dashboardTabUI <- function() {
  tabItem(tabName = "dashboard",
          h2("Overview",
             style = "font-family: monospace; font-weight: bold;"),
          fluidRow(
            valueBoxOutput("total_activities", width = 3),
            valueBoxOutput("total_distance_miles", width = 3),
            valueBoxOutput("total_distance_km", width = 3),
            valueBoxOutput("total_time", width = 3)
          ),
          fluidRow(
            valueBoxOutput("ytd_activities", width = 3),
            valueBoxOutput("ytd_distance_miles", width = 3),
            valueBoxOutput("ytd_distance_km", width = 3),
            valueBoxOutput("ytd_time", width = 3)
          ),
          fluidRow(
            box(
              width = 12,
              DTOutput("recent_activities_table") %>% withSpinner()
            )
          )
  )
}



trainingTabUI <- function() {
  tabItem(tabName = "training",
          h2("Training",
             style = "font-family: monospace; font-weight: bold;"),
          fluidRow(
            box(
              title = div(
                "Distance Over Time",
                style = "font-family: monospace; font-weight: bold;"),
              status = "warning",
              width = 12,
              plotlyOutput("training_load_plot", height = "300px") %>% withSpinner()
            )
          ),
          fluidRow(
            tabBox(
              width = 8,
              tabPanel(
                div(
                  "Heart Rate",
                  style = "font-family: monospace; font-weight: bold;"),
                box(
                  title = div(
                    "Heart Rate Zones",
                    style = "font-family: monospace; font-weight: bold;"),
                  status = "warning",
                  width = 8.5,
                  plotlyOutput("hr_zones_plot") %>% withSpinner())
              ),
              tabPanel(
                "Power",
                box(
                  title = div(
                    "Power Zones",
                    style = "font-family: monospace; font-weight: bold;"),
                  status = "warning", 
                  width = 8.5,
                  plotlyOutput("power_zones_plot") %>% withSpinner())
              )
            ),
            box(
              title = div(
                "Efficiency",
                style = "font-family: monospace; font-weight: bold;"),
              status = "warning",
              width = 4,
              plotOutput("radar_plot") %>% withSpinner())
          ),
          fluidRow(
            box(
              title = div(
                "Weekly Training Summary",
                style = "font-family: monospace; font-weight: bold;"),
              status = "warning",
              width = 12,
              plotlyOutput("weekly_training_load") %>% withSpinner())
          )
  )
}



trendsTabUI <- function() {
  tabItem(tabName = "trends",
          fluidRow(
            tabBox(
              width = 12,
              tabPanel(
                div(
                  "Pace",
                  style = "font-family: monospace; font-weight: bold;"),
                box(
                  title = div(
                    "Pace Trend",
                    style = "font-family: monospace; font-weight: bold;"),
                  status = "success",
                  width = 12.5,
                  plotlyOutput("pace_trend") %>% withSpinner())),
              tabPanel(
                div(
                  "Heart Rate",
                  style = "font-family: monospace; font-weight: bold;"),
                box(
                  title = div(
                    "Heart Rate Trend",
                    style = "font-family: monospace; font-weight: bold;"),
                  status = "success",
                  width = 12.5,
                  plotlyOutput("hr_trend") %>% withSpinner())),
              tabPanel(
                div(
                  "Distance",
                  style = "font-family: monospace; font-weight: bold;"),
                box(
                  title = div(
                    "Distance Trend",
                    style = "font-family: monospace; font-weight: bold;"),
                  status = "success",
                  width = 12.5,
                  plotlyOutput("distance_trend") %>% withSpinner()))
            )
          ),
          fluidRow(
            box(
              title = div(
                "Seasonal Patterns",
                style = "font-family: monospace; font-weight: bold;"),
              status = "success",
              width = 6,
              plotlyOutput("seasonal_patterns") %>% withSpinner()
            ),
            box(
              title = div(
                "Year-over-Year Comparison",
                style = "font-family: monospace; font-weight: bold;"),
              status = "success",
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
              title = div(
                "Data Settings",
                style = "font-family: monospace; font-weight: bold;"),
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              fileInput("upload_json", "Upload Strava Data (JSON):", accept = ".json"),
              textInput("data_path", "Data File Path:", value = DEFAULT_DATA_PATH),
              actionButton("save_settings", "Save Settings", icon = icon("save")),
              actionButton("refresh_data", "Refresh Data", icon = icon("sync")),
              br(), br(),
              downloadButton("download", "Download Data as CSV", icon = icon("file-csv"))
            )
          ),
          fluidRow(
            box(
              title = div(
                "About",
                style = "font-family: monospace; font-weight: bold;"),
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