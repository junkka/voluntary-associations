# make_napp_lookup_sql.R
# Create a community ID (newid) for each group of linked nad-to-napp codes
#  import lookuptable to postgres

source("init.R")
library(histmaps)
library(dplyr)
library(RPostgreSQL)

load(".cache/napp_to_nad.rda")

# use create_block function from histmaps to create community ID
napp_to_nad_to_newid <- napp_to_nad %>% 
  group_by(year) %>% 
  mutate(newid = create_block(parse, nadkod)) %>% 
  ungroup %>% 
  distinct()

nad_to_newid <-
  napp_to_nad_to_newid %>% 
  select(nadkod, year, newid) %>% 
  distinct()

db <- pg_db()

db$send("DROP TABLE IF EXISTS nad_to_newid;")


pgdb <- src_postgres(
  dbname = db_config$dbname,
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password
)

nad_to_newid_db <- copy_to(
  pgdb, 
  nad_to_newid, 
  temporary = FALSE, 
  indexes = list("nadkod", "newid", "year")
)

napp_to_newid <- napp_to_nad_to_newid %>% 
  select(parse, year, newid) %>% 
  distinct()


db$send("DROP TABLE IF EXISTS napp_to_newid;")


res <- copy_to(
  pgdb, 
  napp_to_newid, 
  temporary = FALSE, 
  indexes = list("parse", "newid", "year")
)

db$close()

