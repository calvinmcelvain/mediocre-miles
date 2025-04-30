#
# src/mediocremiles/shiny_app/modules/activities.R - Hold activities tab logic & UI.
#



activities_module <- function(input, output, session, activity_data) {
  output$activity_distribution <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_activity_distribution_plot(activity_data(), theme.base)
  })
  
  output$activity_details <- renderPlotly({
    req(nrow(activity_data()) > 0)
    generate_activity_details_plot(activity_data(), theme.base)
  })
  
  output$pace_vs_distance <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_activity_pace_plot(activity_data(), theme.base, colors.vir)
  })
  
  output$hr_vs_pace <- renderPlot({
    req(nrow(activity_data()) > 0)
    generate_activity_hr_plot(activity_data(), theme.base, colors.vir)
  })
}