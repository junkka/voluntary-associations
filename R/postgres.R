#' Database wrapper class
#'
#' functions for get and send query, and close connection
#'
#' @param db_cnfg db_config list with credentials
#' @export


pg_db <- function(db_cnfg = db_config) {
  library(RPostgreSQL)
  drv <- DBI::dbDriver("PostgreSQL")
  con <- DBI::dbConnect(drv, 
      dbname = db_cnfg$dbname,
      host = db_cnfg$host,
      port = db_cnfg$port,
      user = db_cnfg$user,
      password = db_cnfg$password
    )
  return(list(
    get_con = function(){
      return(con)
    },
    close = function(){
      DBI::dbDisconnect(con)  
    },
    get = function(query){
      res <- DBI::dbGetQuery(con, query)
      return(res)
    },
    send = function(statement){
      DBI::dbSendQuery(con, statement)
    }
  ))
}
