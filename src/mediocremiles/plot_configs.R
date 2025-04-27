library(ggplot2)
library(ggthemes)


colors.wsj <- wsj_pal()(6)

theme.base <- plot.thm <- theme_wsj(color = "white") +
  theme(axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        title = element_text(size = 16, face = "bold"),
        legend.position = "bottom",
        legend.title=element_text(size=12, face = "bold"), 
        legend.text=element_text(size=11),
        strip.text.x = element_text(size = 12, face = "bold", family = "mono"))