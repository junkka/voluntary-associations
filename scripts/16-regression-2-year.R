# 3.4.regression_2_year.R

library(lme4)
library(dplyr)

load(".cache/napp_ana.rda")

d <- napp_ana %>% filter(!is.na(age_group)) %>% 
  mutate(parse = factor(p2)) %>% 
  select(nchlt5, workers, frik, nykt, imrc, age_group, w_occu, 
    h_hisco, year, teachers, urban, parse)

system.time(
  i_res_all <- glmer(
    nchlt5 ~ workers + frik + nykt + imrc + age_group + w_occu + h_hisco + 
    teachers + urban +
    workers * year +
    frik * year +
    nykt * year +
    (1 | parse), 
  family = poisson(link = "log"),
  data = d)
)

save(i_res_all, file = ".cache/i_res_all.rda")
