# 2.7.make_variables.R
library(classInt)
library(dplyr)
source("init.R")

load(".cache/napp_dat.rda")

napp_ana1 <- napp_dat %>% mutate(
    w_occu = factor(w_hisco),
    h_hisco = factor(h_hisco),
    h_hisco = relevel(h_hisco, levels(h_hisco)[4]),
    total = fackf + frik + nykt + parti,
    workers = fackf + parti,
    frik_con = frik,
    nykt_con = nykt,
    workers_con = workers,
    teachers = cut(teachers, quantile(teachers[is.finite(teachers)], probs = seq(0, 1, 1/4), na.rm = T), include.lowest = TRUE),
    age_group = cut(age, breaks = seq(19, 50, 5)),
    age_group = relevel(age_group, "(24,29]"),
    imrc = (imr - 105)/100,
    year = factor(year),
    urban = factor(urban)
  )
levels(napp_ana1$h_hisco) <- substring(levels(napp_ana1$h_hisco), 1,20) 

all_obs <- c(napp_ana1$frik, napp_ana1$nykt, napp_ana1$workers)

cut_move <- function(x) {
  res <- classIntervals(all_obs[all_obs < 1 & all_obs > 0], 3, "quantile")
  cut(
    x, 
    breaks = c(0, res$brks[1:(length(res$brks)-1)], 10000), 
    labels = c(1:4),
    right = FALSE
  )
}

napp_ana <- napp_ana1 %>% 
  mutate(
    workers = cut_move(workers),
    frik  = cut_move(frik),
    nykt  = cut_move(nykt),
    total = cut_move(total)
  ) %>% ungroup()

save(napp_ana, file = ".cache/napp_ana.rda")
