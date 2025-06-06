library(ggplot2)
library(ggthemes)


colors.wsj <- wsj_pal()(6)
colors.vir <- viridis_pal()(25)
colors.brew <- brewer_pal(palette = "Set1")(9)

theme.base <- plot.thm <- theme_minimal() +
  theme(axis.title.x = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        title = element_text(size = 16, face = "bold"),
        legend.position = "bottom",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.title=element_text(size=12, family = "mono", face = "bold"), 
        legend.text=element_text(size=11, family = "mono", face = "bold"),
        strip.text.x = element_text(size = 12, face = "bold", family = "mono"))