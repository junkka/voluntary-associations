# 3.7.vis_urban.R

source("R/predict_modmer.R")
library(lme4)
library(dplyr)
library(ggplot2)

load(".cache/i_res_v2.rda")

d <- as.data.frame(i_res_v2@frame)
a <- plyr::ldply(c("frik", "nykt", "workers"), function(b){
  newdata <- expand.grid(
    frik      = if (b == "frik") levels(d$frik) else levels(d$frik)[1], 
    nykt      = if (b == "nykt") levels(d$nykt) else levels(d$nykt)[1], 
    workers   = if (b == "workers") levels(d$workers) else levels(d$workers)[1], 
    imrc      = mean(d$imrc), 
    age_group = levels(d$age_group)[1],
    w_occu    = levels(d$w_occu)[1],
    h_hisco   = levels(d$h_hisco)[1],
    teachers  = levels(d$teachers)[1],
    urban     = unique(d$urban),
    year      = levels(d$year)[1]
  )
  pred <- predict_mermod(i_res_v2, newdata, c(b, "urban"))

  select_(newdata, b, "urban") %>% cbind(pred) %>% 
    rename_("size" = b) %>% mutate(var = b)
})

a2 <- a %>% 
  mutate(
    urban = factor(urban, labels = c("Rural", "Urban")),
    size = factor(size, labels = c("None", "Small", "Medium", "Large")),
    var = factor(var, labels = c("Free church", "Temperance", "Workers"))
  ) %>% 
  group_by(var, urban) %>% 
  mutate(
    pp2 = pred/pred[row_number() == 1],
    ci_lwr2 = ci_lwr/pred[row_number() == 1],
    ci_upr2 = ci_upr/pred[row_number() == 1]
  ) %>% as.data.frame()

lines <- a2 %>% 
  group_by(urban) %>% 
  summarise(ref = pp2[row_number() == 1]) %>% 
  as.data.frame()

pal = c("#67A43C", "#2F5D76", "#A83E5A")

p <- ggplot(a2, aes(size, pp2, group = urban)) + 
  geom_hline(data = lines, aes(yintercept = ref), color = "#676767") +
  geom_line(aes(color = var)) + 
  geom_point(aes(color = var)) +
  geom_ribbon(aes(ymax = ci_upr2, ymin = ci_lwr2, fill = var), alpha = 0.2) +
  scale_fill_manual(values = pal) + 
  scale_color_manual(values = pal) + 
  facet_grid(urban~var)+ 
  theme(
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "black"),
    panel.grid.major.y = element_line(color = "lightgrey"),
    strip.background = element_blank(), 
    legend.position = "none"
  ) +
  labs(x = "Size", y = "Net fertility")
p

ggsave("figures/interaction_mixed.pdf", plot = p, width = 6.5, height = 2.84375)
