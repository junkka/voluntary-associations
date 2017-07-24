Instructions for replication
================

The scripts contained within this repository is used for the analysis in the paper "Voluntary associations and net fertilit during the Swedish demographic transition". 

## Software requirements

The analysis is performed using [R 3.4.1](https://www.r-project.org/) and [PostGIS 2.1](http://postgis.net/).

## Simple instructions

Given that both R and PostGIS are installed, and that the PostgreSQL credentials are updated in `R/db_config.R`, run the R scripts `required_packages.R` and then run Makefile.

		make all


## Package structure

* `required_packages.R`: Documentation of required R packages
* `Makefile`: Makefile for the analysis
* `init.R`: A inition script sourced by all other scripts
* `R/`: Collection of R functions used in the analysis
* `data-raw/`: Source datafiles
* `scripts/`: R scripts to reproduce analysis from source data files
* `figures/`: Figures
* `.cache/`: A temporary folder

## Sources

* 1890 and 1900 Swedish censuses: The microcensus data is documented within X and can be retrieved from [NAPP](https://www.nappdata.org/). After download place to data in the `data-raw` folder.
* Voluntary associations: The source data and the data cleaning process is documented in the package `movement` which is found at [github.com/junkka/movement](https://github.com/junkka/movement). The source data can be retrieved from: http://snd.gu.se/sv/catalogue/study/SND0209
* Swedish administrative boundaries: The source data and the data cleaning process is documented in the package `histmaps` which is found at [github.com/junkka/histmaps](https://github.com/junkka/histmaps). The source data can be retrieved from the Swedish National Archive http://www.ra.se

## Replication step by step

First part recreates the analysis data.

* Downlad and place NAPP census data in the data-raw folder
* Run scripts/01-make-napp-sql.R. Imports NAPP microcensus data into PostGIS database.
* Run scripts/02-napp-to-nad.R. Connects NAPP microcensus parish code to map data parish codes
* Run scripts/03-make-napp-lookup.R. Creates smallest common boundaries between NAPP microcensus parishes and map data parishes.
* Run scripts/04-make-nad-map.R. Imports shapefile to PostGIS database
* Run scripts/05-create-temp-map.R. Create a parish map in postgis by unioning at year on new common id.
* Run scripts/06-make-sql-roll-movem.R. Creates a rolling avreaged voluntary association size
* Run scripts/07-move-napp-agg.R. Calculate voluntary association size by parish
* Run scripts/08-teachers-var.R. Calculates number of teachers per children by parish.
* Run scripts/09-pop-density.R. Creates a urban variable from population density
* Run scripts/10-unit-id.R. Creates a common parish ID for both censuses, from smallest common boundaries.
* Run scripts/11-make-analysis-data.R. Combines variables into analysis dataset.
* Run scripts/12-make-variables.R. Formats and labels variables.
* Run scripts/13-correlation.R Figure 1
* Run scripts/14-movement-map.R Figure 2
* Run scripts/15-regression-1.R Table 4
* Run scripts/16-regression-2-year.R Table 5
* Run scripts/17-regression-3-urban.R Table 6
* Run scripts/18-vis-year.R Figure 3
* Run scripts/19-vis-urban.R Figure 4

