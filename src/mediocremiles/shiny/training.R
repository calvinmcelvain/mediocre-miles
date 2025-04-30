#
# Activities module.
#



trainingModuleUI <- function(id) {
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
  )
}



trainingModule <- function(id, activity_data, theme.base, colors.wsj) {
    moduleServer(id, function(input, output, session) {
      
      output$weekly_training_load <- renderPlot({
        data <- activity_data()
        
        weekly_load <- data %>%
          group_by(id) %>%
          slice(1) %>%
          ungroup() %>%
          mutate(
            week = floor_date(as.Date(start_date), "week"),
            load = distance_km * (total_moving_time_seconds / 3600)
          ) %>%
          group_by(week) %>%
          summarize(
            weekly_load = sum(load, na.rm = T),
            .groups = "drop"
          )
        
        ggplot(weekly_load, aes(x = week, y = weekly_load)) +
          geom_bar(stat = "identity", fill = colors.wsj[5]) +
          geom_line(aes(group = 1), color = colors.wsj[1], size = 1) +
          labs(x = "Week", y = "Training Load", title = "Weekly Training Load") +
          theme.base +
          scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      })
    })
}
    
