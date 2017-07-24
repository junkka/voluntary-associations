# 2.5.make_analysis_data.R

# combine 
# * Children under 5
# * Husbands occupation
# * Womens workdforce status
# * County infant mortality rates
# * Parish level popular movment size
# * Age 
# * Urban/pop density
# * Teachers
source("init.R")

library(assertthat)
library(tidyr)
library(histmaps)
library(hisco)
library(swepophist)
library(dplyr)

db <- pg_db()
m_raw <- db$get("
  SELECT 
    w.year, w.serial, w.pernum, w.bplse, w.migrant,
    w.age, w.parse, l.newid, w.nchlt5, w.labforce,
    w.occhisco as w_hisco, h.occhisco as h_hisco
  FROM napp as w 
  LEFT JOIN napp as h 
    ON w.serial = h.serial AND w.sploc = h.pernum AND w.year = h.year
  LEFT JOIN napp_to_newid l 
    ON l.parse = w.parse AND l.year = w.year
  WHERE w.age >= 15 AND w.age < 50 AND w.marst < 3 AND w.sex = 2
  ")

# add popmove
load(".cache/move_by_napp.rda")
pop_move <- move_by_napp %>% spread(orgtypn, members, fill = 0) %>% 
  select(newid:parti)

m_raw2 <- left_join(m_raw, pop_move, by = c("newid", "year")) %>% 
  mutate(
    fackf = ifelse(is.na(fackf), 0, fackf),
    frik = ifelse(is.na(frik), 0, frik),
    nykt = ifelse(is.na(nykt), 0, nykt),
    parti = ifelse(is.na(parti), 0, parti)
  )

assert_that(nrow(m_raw) == nrow(m_raw2))
assert_that(length(m_raw2$age[is.na(m_raw2$fackf)]) == 0)
assert_that(length(m_raw2$age[is.na(m_raw2$frik)]) == 0)
assert_that(length(m_raw2$age[is.na(m_raw2$nykt)]) == 0)
assert_that(length(m_raw2$age[is.na(m_raw2$parti)]) == 0)

# hisco codes
napp_hisco <- read.csv("data-raw/napp_hisco_to_hisco.csv", stringsAsFactors = FALSE) 
colnames(napp_hisco) <- c("napp_title", "occhisco", "hisco_code", "hisco", "checked", "comment")
napp_hisco <- napp_hisco %>% select(occhisco, hisco)

m_raw3 <- m_raw2 %>% 
  left_join(napp_hisco, by = c("h_hisco" = "occhisco")) %>% 
  rename(h_hisco2 = hisco) %>% 
  left_join(napp_hisco, by = c("w_hisco" = "occhisco") )%>% 
  rename(w_hisco2 = hisco) %>% 
  mutate(
    w_hisco = ifelse(w_hisco != 99999, "Working", "No occupation"),
    h_hisco = hisco_to_ses(h_hisco2, ses = "hisclass_5", label = TRUE),
    h_hisco = ifelse(is.na(h_hisco), "Unknown", as.character(h_hisco))
  )


assert_that(nrow(m_raw3) == nrow(m_raw2))

# County infant mortality rates
data(imr, package = "swepophist")

# each year a 
imr_data <- rbind(
  imr %>% 
    filter(from <= 1890, to >= 1890) %>% select(imr, county) %>% 
    mutate(year = 1890),
  imr %>% 
    filter(from <= 1900, to >= 1900) %>% select(imr, county) %>% 
    mutate(year = 1900)
)

# county for all parse


# add county to 
# link par_to_county to napp_to_nad2
get_cnty <- function(theyear) {
  load(".cache/napp_to_nad.rda")
  napp_to_nad2 <- napp_to_nad %>% 
    filter(year == theyear) %>%
    mutate(newid = create_block(parse, nadkod)) 
  cnty <- par_to_county %>% filter(from <= theyear, tom >= theyear) %>% 
    select(nadkod, county) %>% 
    left_join(napp_to_nad2) %>% 
    select(parse, county) %>% 
    distinct() %>% 
    mutate(year = theyear)
  return(cnty)
}
cnty <- rbind(get_cnty(1890), get_cnty(1900))

m_raw4 <- left_join(m_raw3, cnty)

assert_that(nrow(m_raw3) == nrow(m_raw4))

m_raw5 <- left_join(m_raw4, imr_data)

assert_that(nrow(m_raw4) == nrow(m_raw5))

# teachers 

load(".cache/teachers.rda")

m_raw6 <- left_join(m_raw5, teachers, by = c("parse", "year"))

assert_that(nrow(m_raw5) == nrow(m_raw6))


# add urban/density
load(".cache/pop_density.rda")

m_raw7 <- pop_density %>% select(newid, year, density, urban) %>% 
  left_join(m_raw6, ., by = c("newid", "year"))

assert_that(nrow(m_raw6) == nrow(m_raw7))

load(".cache/parse_lookup.rda")

m_raw8 <- left_join(m_raw7, parse_lookup, by = c("year", "parse"))

assert_that(nrow(m_raw7) == nrow(m_raw8))

m_raw9 <- m_raw8 %>% filter(!is.na(county))

napp_dat <- m_raw9

save(napp_dat, file = ".cache/napp_dat.rda")
