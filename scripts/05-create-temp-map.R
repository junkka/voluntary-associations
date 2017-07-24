# make new map on union

source("init.R")

#' Create POSTGIS napp map
#'
#' Create a parish map in postgis by unioning at year on id.
#'
#' @param year 1890 or 1900
#' @export

create_nad_map <- function(year = c(1890, 1900)) {
  if (!year %in% c(1890, 1900))
    stop("Year must be 1890 or 1900")

  db <- pg_db()
  db$send(sprintf("
    DROP TABLE IF EXISTS napp_map_%d;
    CREATE TABLE napp_map_%d AS
    SELECT p.newid,
      ST_Multi(ST_Union(n.geom)) as geom  
    FROM nad n
    LEFT JOIN nad_to_newid p ON n.nadkod = p.nadkod
    WHERE n.from <= %d AND n.tom >= %d AND p.year = %d
    GROUP BY p.newid;
    ", year, year, year, year, year))
  db$close()
}
create_nad_map(1890)
create_nad_map(1900)
