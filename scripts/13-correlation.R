# 3.1.correlation.R

# title: General correlations

# source("init.R")
library(swepophist)
library(movement)
library(grid)
library(gridExtra)
library(dplyr)
library(ggplot2)
library(broom)

selected = c("Sweden")

pop <- county_pop %>% 
  filter(!is.na(county)) %>% 
  mutate(county = ifelse(county == 2, 1, county)) %>% 
  group_by(year, county) %>% 
  summarise(pop = sum(pop)) %>% 
  as.data.frame() %>% 
  select(county, year, pop)

data(movement, package = "movement")
m_o <- movement %>% 
  mutate(
    orgtypn = ifelse(orgtypn %in% c("fackf", "parti"), "Workers", as.character(orgtypn)),
    orgtypn = factor(orgtypn, levels = c("frik", "nykt", "Workers"), labels = c("Free-church", "Temperance", "Workers")),
    lanskod = ifelse(lanskod == 2, 1, lanskod)
  ) %>% 
  group_by(year, orgtypn, lanskod) %>% 
  summarise(medl = sum(medl, na.rm = T)) %>% 
  filter(year <= 1940) %>% 
  left_join(pop, by = c("lanskod" = "county", "year")) %>% 
  filter(!is.na(pop)) %>% 
  ungroup %>% group_by(orgtypn) %>% 
  mutate(raw = medl/pop, Movement = orgtypn) %>% 
  ungroup %>% 
  mutate(value = raw/max(raw[orgtypn != "workers"], na.rm = T)) %>% 
  select(year, Movement, value, raw, county = lanskod) 

cnty <- pop_fert %>% count(context ) %>% as.data.frame() %>% 
  mutate(county = c(15, 10,2,21,14,9,13,23,6,8,20,11,7,12,25,18,5,16,4,1,NA,3,17,24,22,19)) %>% 
  select(-n) 

m <- pop_fert %>% 
  filter(end >1879, end < 1941, age_g < 45, age_g > 15) %>% 
  mutate(context = ifelse(context == "City of Stockholm", "Stockholm", as.character(context))) %>% 
  group_by(context, end) %>% 
  summarise(tfr = (sum(fert)*5)/1000) %>% 
  mutate(
    Context = ifelse(context %in% selected, "National", "County")
  )

dd <- m %>% left_join(cnty, by = "context") %>% 
  as.data.frame() %>% 
  filter(Context == "County") %>% 
  select(year = end, tfr, county) %>% 
  left_join(m_o, by = c("year", "county")) %>% 
  filter(!is.na(value),  year < 1930)

dd_cor <- dd %>% group_by(Movement) %>% summarise(cor = cor(tfr, raw))

dd_slope <- dd %>% mutate(size = raw * 100) %>% 
  group_by(Movement) %>% do(tidy(lm(tfr~size, data = .))) %>% 
  mutate(p.value = round(p.value, 3)) %>% 
  filter(term == "size") 
dd_slope$x = c(0.095, 0.150, 0.14) 
dd_slope$y = c(3.2, 3.5, 3.5)


pal = c("#67A43C", "#2F5D76", "#A83E5A")

p3 <- ggplot(dd, aes(raw, tfr, group = Movement)) + 
  geom_point(alpha = 0.5)+ 
  scale_x_continuous(breaks = c(0, 0.05, 0.10, 0.15), labels = c("0%", "5%", "10%", "15%")) + 
  geom_text(data = dd_slope, aes(x, y, label = round(estimate, 3)), size = 3) + 
  facet_grid(.~Movement) +
  stat_smooth(method = "lm", color = "black") +
  theme(
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "black"),
    panel.grid.major.y = element_line(colour = "#D4D4D4"),
    panel.grid.major.x = element_line(colour = "#D4D4D4"),
    plot.margin = unit(c(0, 0.5, 1, 0.5),"cm"),
    axis.title.y = element_text(vjust = 1.5),
    axis.title.x = element_text(vjust = -1.5),
    strip.background = element_blank(), 
    legend.key = element_rect(fill = NA)
  ) +
  labs(x = "Relative size", y = "TFR")

ggsave("figures/corr.pdf", plot = p3, width = 20, height = 7.6, units="cm")
