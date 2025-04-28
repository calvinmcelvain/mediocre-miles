#
# Settings module.
#




settingsModuleUI <- function(id) {
  ns <- NS(id)
  
  tabItem(tabName = "settings",
          fluidRow(
            box(
              title = "Data Settings",
              status = "primary",
              solidHeader = T,
              width = 12,
              fileInput("upload_json", "Upload Strava Data (JSON):", accept = ".json"),
              textInput("data_path", "Data File Path:", value = app_config$data_path),
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
}



settingsModule <- function(id, activity_data, theme.base, colors.wsj) {
  moduleServer(id, function(input, output, session) {
  })
}