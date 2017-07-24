# R/sql create roll avg movem 
# 1. Calculate rolling avreage of popular movement membership
# 2. Import membership data to postgresql
# 3. Create point geomtry column for association location in postgresql


source("init.R")
library(movement)
library(zoo)
library(tidyr)
library(dplyr)

# aggregate and calc rollmean
rollavg <- function(x, year) {
  if (length(x) < 5) {
    return(mean(x))
  }
  y <- zoo(x, year)
  as.numeric(rollmean(y, 5, fill = x[1], align = "right"))
}

data(movement)
movem <- movement %>% group_by(geoid, orgtypn, orgnamn, year) %>% 
  summarise(memb = sum(medl, na.rm = T)) %>% 
  ungroup %>% group_by(geoid, orgtypn) %>% 
  mutate(memb = rollavg(memb, year))

movement <- movem %>% as.data.frame() %>% 
  mutate(year = paste0("medl", year)) %>% 
  spread(year, memb, fill = 0) %>% tbl_df() %>% 
  left_join(geocodes)

pbdb <- src_postgres(
  dbname = db_config$dbname,
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password
)
db <- pg_db()

db$send("DROP TABLE IF EXISTS movement;")
copy_to(pbdb, movement, temporary = FALSE, indexes = list(
  "orgnamn", "orgtypn", "lon", "lat"))

db$send(
  "ALTER TABLE movement ADD COLUMN mid BIGSERIAL PRIMARY KEY;
  SELECT AddGeometryColumn('public', 'movement', 'geom', 2400, 'POINT', 2);
  UPDATE movement SET geom = ST_SetSRID(ST_MakePoint(lon, lat), 2400);")
db$close()
