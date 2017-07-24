# movement-map.R
# One map per movement

# get map and add data
library(rgdal)
library(rgeos)
library(histmaps)
library(RColorBrewer)
library(movement)
library(assertthat)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(zoo)
library(tidyr)
library(classInt)
library(maptools)


load(".cache/napp_dat.rda")


napp_ana1 <- napp_dat %>% 
  mutate(
    w_occu = w_hisco,
    h_hisco = factor(h_hisco),
    h_hisco = relevel(h_hisco, " Self-employed farmers and fishermen"),
    total = fackf + frik + nykt + parti,
    workers = parti + fackf,
    teachers = cut(teachers, quantile(teachers[is.finite(teachers)], probs = seq(0, 1, 1/4), na.rm = T), include.lowest = TRUE),
    age_group = cut(age, breaks = seq(19, 50, 5)),
    age_group = relevel(age_group, "(24,29]"),
    imrc = (imr - 105)/100,
    year = factor(year)
  )
levels(napp_ana1$h_hisco) <- substring(levels(napp_ana1$h_hisco), 1,20) 


cut_move <- function(x) {
  res <- classIntervals(x[x < 1 & x > 0], 3, "kmeans")
  lbls <- paste(">", round(res$brks[2:3]*100), "%")
  cut(
    x, 
    breaks = c(0, res$brks[1:(length(res$brks)-1)], 10000), 
    labels = c(1:4),
    right = FALSE
  )
}

d_napp <- napp_ana1 %>% 
  mutate(
    total = cut_move(total),
    frik  = cut_move(frik),
    nykt  = cut_move(nykt),
    workers = cut_move(workers)
  )

plot_move_map <- function(theyear, napp_d){
  m_map <- readOGR("PG:dbname=maps", sprintf("napp_map_%d", theyear))

  gg_map <- sp_to_ggplot(m_map)

  d <- napp_d %>% 
    filter(year == theyear) %>% 
    select(newid, frik, nykt, total, workers) %>% 
    distinct()
  d_map <- left_join(gg_map, d, by = "newid") 

  assert_that(nrow(gg_map) == nrow(d_map))

  d_map <- tbl_df(d_map) %>% gather(org, memb, frik, nykt, total, workers) %>% filter(org != "total") %>% 
    mutate(
      org = ordered(as.character(org), 
        levels = c("frik", "nykt", "workers"), 
        labels = c("Free church", "Temperance", "Workers")
      ),
      memb = factor(memb, labels = c(" None", " Small", " Medium", " Large"))
    )
  
  
  return(d_map)
}

# Get plot data --------------

d1 <- plot_move_map(1890, d_napp)
d2 <- plot_move_map(1900, d_napp)

# Create base plot ------------
data("e1900bounds", package = "histmaps")
data("e1900", package = "histmaps")
bounds <- sp_to_ggplot(e1900bounds)

data(sweden)

bkgr <- cut_spbox(e1900, sweden, 40000)
bkgr <- sp_to_ggplot(bkgr)
d6 <- bkgr %>%
  filter(COUNTRY != 20)


bounds2 <- bounds %>%
  filter(COUNTRY %in% unique(d6$COUNTRY))

# Create swe boundaries by buffering
swe2 <- gBuffer(sweden, byid = TRUE, width = 3500)
swe2 <- SpatialPolygonsDataFrame(swe2, sweden@data)
swe <- sp_to_ggplot(sweden)
swe_g <- sp_to_ggplot(swe2)


d1 <- d1 %>% mutate(year = 1890)
d2 <- d2 %>% mutate(year = 1900)
dd <- bind_rows(d1, d2)

clrs <- c("#FFF3EC", "#BB917A", "#7C5037", "#391501") # Brown lighter



textsize = 16
keysize = .5
library(ggsn)
  
p <- ggplot() + 
  geom_polygon(data = d6, aes(long, lat, group = group), fill = "#F2F2F2") + 
  geom_path(data = bounds2, aes(long, lat, group = group), color = "#AFAFAF", size = keysize*0.8) +
  geom_polygon(data = swe_g, aes(long, lat, group = group), fill = "#727272") + 
  geom_polygon(data = dd, aes(long, lat, group = group, fill = memb)) + 
  scale_x_continuous(expand = c(0,0), limits = c(min(d6$long), max(d6$long))) + 
  scale_y_continuous(expand = c(0,0), limits = c(min(d6$lat), max(d6$lat))) +
  scale_fill_brewer(type = "seq") +
  guides(fill=guide_legend(title="Relative size")) + 
  coord_equal() + 
  facet_grid(year~org) +
  theme(axis.line = element_blank(), axis.text = element_blank(),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.spacing = unit(keysize * 1, "cm"),
        axis.ticks = element_blank(),
        text = element_text(size = textsize, color = "black"),
        legend.background = element_rect(color = "#9b9b9b"),
        legend.title = element_text(size = textsize*0.5),
        legend.text = element_text(size = textsize*0.5),
        legend.key = element_rect(size = keysize * 6, color = 'white'),
        legend.key.height = unit(keysize - (keysize*0.25), "cm"),
        legend.key.width = unit(keysize, "cm"),
        legend.position = c(0.97,0.033),
        legend.spacing = unit(keysize*1, "lines"),
        strip.background = element_blank()) + 
  labs(x = "", y = "") +
  scalebar(
    data = dd, 
    dist = 150, 
    location = "bottomright", 
    st.size = 2.5, 
    anchor = c(x = 1848030, y = 6167100),
    facet.var = c("org", "year"), 
    facet.lev = c("Free church", "1900")) 
  

ggsave("figures/movement-map.pdf", plot = p, width = 18.25, height = 25, units = "cm")

ggsave("figures/movement-map.eps", plot = p, height = 10, width = 7.35)
ggsave("figures/movement-map.png", plot = p, height = 10, width = 7.35)
