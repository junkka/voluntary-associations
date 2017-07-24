# 2.5.teachers_var.R
# calculate prop teachers by parish
source("init.R")
library(dplyr)
library(assertthat)

db <- pg_db()

dat <- db$get("
  SELECT 
    sum(CASE WHEN occhisco IN (13100, 13210, 13220, 13230, 13240, 13250, 17130) THEN 1 ELSE 0 END) as teachers,
    sum(CASE WHEN age > 6 AND age < 13 THEN 1 ELSE 0 END) as children,
    parse, year
    FROM napp 
    GROUP BY parse, year
  ")

teachers <- dat %>% 
  mutate(
    teachers = teachers/children,
    teachers = ifelse(is.infinite(teachers), 0, teachers),
    teachers = ifelse(is.na(teachers), 0, teachers)
  ) 
assert_that(length(teachers$teachers[is.infinite(teachers$teachers)]) == 0)
assert_that(length(teachers$teachers[is.na(teachers$teachers)]) == 0)
save(teachers, file = ".cache/teachers.rda")
