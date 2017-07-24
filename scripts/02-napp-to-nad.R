# Explore geolinks
source("init.R")
library(histmaps)
library(dplyr)
library(rcustom)
library(ggplot2)

# Link movement 1900 to folk 1900
# link movement 1890 to napp 1890

# Matches between napp parishes and nad forkod
# Load nad 
data(hist_parish)
nad <- hist_parish@data

# forkod 1900
nad_codes <- nad %>% 
  filter(from <= 1900, tom >= 1900) %>% 
  count(nadkod, socken) 

# get napp parse codes
db <- pg_db()
napp_codes <- db$get("SELECT parse as nadkod, COUNT(uid) as n FROM napp WHERE year = 1900 GROUP BY nadkod")
db$close()

# link directly by code
linked <- left_join(napp_codes, nad_codes, by = 'nadkod') %>% 
  transmute(nadkod, 
    nad_id = ifelse(is.na(socken), NA, nadkod)
  )

# how many are not linked from nad and napp
#  create short version of nadkod
nad_nolink <- nad_codes %>% filter(!nadkod %in% linked$nadkod) %>% 
  mutate(short = floor(nadkod/1000))
napp_nolink <- napp_codes %>% filter(!nadkod %in% nad_codes$nadkod) %>% 
  mutate(short = floor(nadkod/1000))

napp_unique <- napp_nolink %>% 
  group_by(short) %>% 
  summarise(n = n()) %>% 
  filter(n == 1) %>% 
  left_join(napp_nolink, by = 'short')
nad_unique <- nad_nolink %>% 
  group_by(short) %>% 
  summarise(n = n()) %>% 
  filter(n == 1) %>% 
  left_join(nad_nolink, by = 'short')

# Link by short nadkod version
napp_update <- left_join(napp_unique, nad_unique, by = 'short') %>% 
  filter(!is.na(nadkod.y)) %>% 
  select(nadkod = nadkod.x, nad_idupp = nadkod.y)
linked2 <- left_join(linked, napp_update, by = 'nadkod') %>% 
  transmute(nadkod, nad_id = ifelse(is.na(nad_id), nad_idupp, nad_id))

# extract napp codes still not linked
napp_nolink2 <- linked2 %>% filter(is.na(nad_id))
# These are written to a csv file and manually linked to nad codes

# read manually linked codes
manual_napp_to_nad <- read.csv('data-raw/napp_manual.csv')
napp_to_nad <- left_join(linked2, manual_napp_to_nad, by = 'nadkod') %>% 
  transmute(parse = nadkod, nadkod = ifelse(is.na(nad_id), nad_id_upp, nad_id))

save(napp_to_nad, file = '.cache/napp_to_nad.rda')
