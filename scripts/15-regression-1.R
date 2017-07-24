# 3.3.regression_1.R

library(lme4)
library(dplyr)

load(".cache/napp_ana.rda")

d <- sample_n(napp_ana, 100000)

napp_ana <- napp_ana %>% mutate(parse = factor(p2))

res_all <- glmer(nchlt5 ~ workers + frik + nykt + imrc + age_group + w_occu + h_hisco + teachers +  
                       urban + year + (1 | parse), 
                       family = poisson(link = "log"),
                       data = napp_ana)


save(res_all, file = ".cache/res_all.rda")
