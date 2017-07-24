source("init.R")
library(dplyr)


db <- pg_db()
m_raw <- db$get("
SELECT DISTINCT parse, year FROM napp
")
db$close()

# Create a common parish idea of the smallest common parish boundaries in 1890 and 1900

d <- tbl_df(m_raw)

prse <- d %>% 
  select(year, parse) %>% distinct()

prse1890 <- filter(prse, year == 1890)
prse1900 <- filter(prse, year == 1900)

p1 <- prse1890 %>% filter(!parse %in% prse1900$parse)
p2 <- prse1900 %>% filter(!parse %in% prse1890$parse)

manual <- read.csv(textConnection('year,p1,p2,type
1900,68002999,68002002,"pre"
1900,88106000,88105000,"pre"
1900,113703000,113701000,"pre"
1900,156622000,156620000,"pre"
1900,168214000,168214002,"pre"
1900,168501000,168502000,"pre"
1900,208503999,208503000,"pre"
1900,218090000,218001001,"pre"
1900,228301998,228301000,"pre"
1900,231303000,231304000,"pre"
1900,238001999,238001000,"pre"
1890,59999999,58001000,"post"
1890,69999999,58001002,"post"
1890,129999999,128001000,"post"
1890,148092000,148090000,"post"
'))

parse_lookup <- manual %>% 
  select(p1,p2,year) %>% 
  left_join(prse, ., by = c("parse" = "p1", "year" = "year")) %>% 
  mutate(
    p2 = ifelse(is.na(p2), parse, p2)
  ) %>% 
  as.data.frame()

save(parse_lookup, file = ".cache/parse_lookup.rda")
