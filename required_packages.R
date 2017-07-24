# Required packages
install.packages(c(
	"devtools",
  "assertthat",
  "broom",
  "classInt",
  "dplyr",
  "fitdistrplus",
  "ggplot2",
  "gridExtra",
  "lme4",
  "Matrix",
  "RColorBrewer",
  "rgdal",
  "rgeos",
  "RPostgreSQL",
  "tidyr",
  "zoo",
	"dbplyr"
))

# Custom packages
cust_packages <- c(
	"junkka/histmaps",
	"junkka/swepophist",
	"cedarfoundation/hisco",
	"junkka/movement"
)

lapply(cust_packages, devtools::install_github)
