# make_napp_sql.R
# Import napp csv files into postgres
source("init.R")

location <- 'data-raw'
# decompress data
system(sprintf('gzip -vdk %s/napp_00001.csv.gz', location))
system(sprintf('gzip -vdk %s/napp_00002.csv.gz', location))
# fread data
path <- file.path(location, 'napp_00001.csv')
path2 <- file.path(location, 'napp_00002.csv')

# copy csv to postgres table
db <- pg_db()
db$send("
  DROP TABLE IF EXISTS napp;
  CREATE TABLE napp 
  (
    uid SERIAL PRIMARY KEY,
    sample   int,
    serial   int,
    cntry    int,
    year     int,
    numperhh int,
    hhwt     int,
    gq       int,
    urban    int,
    parse    int,
    countyse int,
    farmipum int,
    farm     int,
    nmothers int,
    nfathers int,
    ncouples int,
    nfams    int,
    prmfamsz int,
    servants int,
    headloc  int,
    pernum   int,
    perwt    int,
    momloc   int,
    stepmom  int,
    momrule  int,
    poploc   int,
    steppop  int,
    poprule  int,
    sploc    int,
    sprule   int,
    famsize  int,
    nchild   int,
    nchlt5   int,
    nchlt10  int,
    famunit  int,
    eldch    int,
    yngch    int,
    nsibs    int,
    numgen   int,
    marrydau int,
    marryson int,
    unmardau int,
    unmarson int,
    unmarkid int,
    nonrels  int,
    relate   int,
    age      int,
    sex      int,
    marst    int,
    birthyr  int,
    relatei  int,
    nativity int,
    bplcntry int,
    nappster int,
    bplse    int,
    migrant  int,
    natnalty int,
    religion int,
    labforce int,
    occhisco int,
    sursim   int,
    namelast text,
    namefrst text
  );
  CREATE INDEX sample_idx ON napp (sample);
  CREATE INDEX serial_idx ON napp (serial);
  CREATE INDEX parse_idx ON napp (parse);
  CREATE INDEX pernum_idx ON napp (pernum);
  CREATE INDEX momloc_idx ON napp (momloc);
  CREATE INDEX poploc_idx ON napp (poploc);
  CREATE INDEX sploc_idx ON napp (sploc);
  CREATE INDEX age_idx ON napp (age);
  CREATE INDEX sex_idx ON napp (sex);
  CREATE INDEX marst_idx ON napp (marst);
  CREATE INDEX occhisco_idx ON napp (occhisco);
  "
  )

system(sprintf('
  psql %s -c "\\COPY napp(sample, serial, cntry, year, numperhh, hhwt, gq, urban, parse, countyse, farmipum, farm, nmothers, nfathers, ncouples, nfams, prmfamsz, servants, headloc, pernum, perwt, momloc, stepmom, momrule, poploc, steppop, poprule, sploc, sprule, famsize, nchild, nchlt5, nchlt10, famunit, eldch, yngch, nsibs, numgen, marrydau, marryson, unmardau, unmarson, unmarkid, nonrels, relate, age, sex, marst, birthyr, relatei, nativity, bplcntry, nappster, bplse, migrant, natnalty, religion, labforce, occhisco, sursim, namelast, namefrst)
  FROM \'%s\' WITH DELIMITER \',\' CSV HEADER;"', db_config$dbname, path))


system(sprintf('
  psql %s -c "\\COPY napp(sample, serial, cntry, year, numperhh, hhwt, gq, urban, parse, countyse, farmipum, farm, nmothers, nfathers, ncouples, nfams, prmfamsz, servants, headloc, pernum, perwt, momloc, stepmom, momrule, poploc, steppop, poprule, sploc, sprule, famsize, nchild, nchlt5, nchlt10, famunit, eldch, yngch, nsibs, numgen, marrydau, marryson, unmardau, unmarson, unmarkid, nonrels, relate, age, sex, marst, birthyr, relatei, nativity, bplcntry, nappster, bplse, migrant, natnalty, religion, labforce, occhisco, sursim, namelast, namefrst)
  FROM \'%s\' WITH DELIMITER \',\' CSV HEADER;"',  db_config$dbname, path2))


unlink(path)
unlink(path2)
