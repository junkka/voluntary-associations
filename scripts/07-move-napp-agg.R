# move_napp_agg.R
# Estimate the relative size of a voluntary association on a parish level.
source("init.R")
library(assertthat)
library(dplyr)
library(RPostgreSQL)

db <- pg_db()

# Create new columns to hold avreage relative membership in 1890 and 1900
db$send("
  ALTER TABLE movement 
    DROP COLUMN IF EXISTS rel1890,
    DROP COLUMN IF EXISTS rel1900,
    ADD COLUMN rel1890 double precision,
    ADD COLUMN rel1900 double precision;
")

# get population over 15 by geom
# sum population where o.geom within distance of m.geom
update_move <- function(theyear){
  db$send(sprintf("
    UPDATE movement SET rel%d = 
      (SELECT move.medl%d/SUM(pg.pop) as rel
          FROM 
            movement as move,
            (SELECT o.pop, nm.geom
            FROM 
              napp_map_%d as nm,
              /* For each parish summarise population over 15 */
              (SELECT count(p.serial) as pop, q.newid 
                FROM napp AS p, napp_to_newid as q 
                WHERE q.parse = p.parse AND 
                  q.year = %d AND
                  p.year = %d AND
                  p.age > 15
                GROUP BY q.newid) as o
            WHERE nm.newid = o.newid) as pg
          WHERE 
            movement.mid = move.mid AND
            ST_DWithin(move.geom, pg.geom, 5000)
          GROUP BY move.mid)
  ", theyear, theyear - 1, theyear, theyear, theyear))
  
}

update_move(1890)
update_move(1900)

get_move_napp <- function(theyear){
  # For each parish summarise the proportional size of organizations 
  #   within 5 km
  napp_move <- db$get(sprintf('SELECT s.newid, m.orgtypn,
    coalesce(sum(m.rel%d),0) AS members
    FROM 
      napp_map_%d AS s, 
      movement AS m
    WHERE ST_DWithin(s.geom, m.geom, 5000)
    GROUP BY s.newid, m.orgtypn', theyear, theyear))
  napp_move %>% mutate(year = theyear)
}

move_by_napp <- rbind(get_move_napp(1890), get_move_napp(1900))

# check that all newid has a observation

newids <- db$get("SELECT * FROM napp_to_newid")

db$close()

res <- left_join(newids, move_by_napp)

assert_that(nrow(filter(res, is.na(members))) == 0)

save(move_by_napp, file = ".cache/move_by_napp.rda")
