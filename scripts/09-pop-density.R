# 2.5.pop_density.R
# create a urban variable
# population by newid area

source("init.R")
library(dplyr)

db <- pg_db()

get_area <- function(theyear) {
  # get newid area
  area <- db$get(sprintf("SELECT newid, ST_Area(geom) as area FROM napp_map_%s", theyear))
  pop <- db$get(sprintf("SELECT COUNT(n.uid) as n, l.newid
    FROM napp n 
    LEFT JOIN napp_to_newid l on n.parse = l.parse
    WHERE n.year = %s
    GROUP BY l.newid", 
    theyear
    ))
  left_join(pop, area, by = "newid") %>% 
    mutate(year = theyear)
}

res <- rbind(get_area(1890), get_area(1900))


urban_d <- db$get("SELECT DISTINCT n.year, MAX(n.urban) as urban_ind, l.newid 
    FROM napp n 
    LEFT JOIN napp_to_newid l on n.parse = l.parse 
    GROUP BY l.newid, n.year")

db$close()

pop_density <- res %>% 
  mutate(density = n/(area/1000), urban = cut(density, c(0,0.3, 100), c(FALSE, TRUE))) %>% 
  left_join(urban_d) %>% 
  mutate(urban = ifelse(urban_ind == 2, 2, urban))

save(pop_density, file = ".cache/pop_density.rda")
