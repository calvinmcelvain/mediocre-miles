#
# src/mediocremiles/shiny_app/modules/settings.R - Settings tab logic.
#



settings_module <- function(input, output, session, data_manager) {
  observe({
    updateTextInput(session, "data_path", value = data_manager$get_data_path())
  })
}