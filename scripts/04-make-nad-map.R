# R/sql make nad map
#   import the NAD map to postgres

source("init.R")
library(histmaps)
library(rgdal)
library("RPostgreSQL")
data(hist_parish)
temp_dir <- tempdir()
unlink(file.path(temp_dir, 'nad_temp'), recursive = T)

# Write map data to temporary shapefile
writeOGR(hist_parish, file.path(temp_dir, 'nad'), "nad", driver="ESRI Shapefile")

db <- pg_db()
db$send("DROP TABLE IF EXISTS nad;")
db$close()

# import shapefile to postgres
system(sprintf('shp2pgsql -I -s 2400 -W "latin1" %s/nad/nad.shp nad | psql -d maps', temp_dir))

unlink(file.path(temp_dir, 'nad_temp'), recursive = T)