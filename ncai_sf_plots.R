library(sf)
library(ggplot2)

#### Read spatial files
setwd("/home/miell/Desktop/FORTH2O Data Specialist")
# FORTH2O area of interest
f2oaoi <- read_sf("Data/gov/census/geog/f2o/f2oaoi.shp")
# Higher geography
hg <- read_sf("Data/gov/census/outputs/hg.shp")
# Intersection of FORTH2O area and higher geography; removes water
f2o.hg <- st_intersection(f2oaoi, hg)
mydata <- list.files("Outputs/forthNCAI datasets", 
  full.names = TRUE, pattern = ".shp|.gpkg") |>
  lapply(read_sf) |>
  setNames(list.files("Outputs/forthNCAI datasets", 
                      pattern = ".shp|.gpkg"))
#### Plot spatial data
lapply(mydata[c(1:6)], 
  function(X) ggplot() + geom_sf(data = f2o.hg) + geom_sf(data = X) + theme_classic())

