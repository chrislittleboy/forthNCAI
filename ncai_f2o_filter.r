library(data.table)
library(sf)
library(terra)
setwd("/home/miell/Desktop/FORTH2O Data Specialist")
alldata <- list.files("Data/NCAI", 
					pattern = ".csv", full = TRUE) |>
	lapply(fread)
	
# FORTH2O area of interest
f2oaoi <- read_sf("Data/gov/census/geog/f2o/f2oaoi.shp")
# Higher geography
hg <- read_sf("Data/gov/census/outputs/hg.shp")
# Intersection of FORTH2O area and higher geography; removes water
f2o.hg <- st_intersection(f2oaoi, hg)

mask.by.fwb <- function(x) {
	mask(crop(x))}
	
allnames <- lapply(list.files("Data/NCAI", pattern = ".csv"), 
	function(X) gsub(".csv", "", X)) |>
	unlist()
	
alldata <- setNames(alldata, allnames)
#### Spatial filtering by Forth Water Basin ####
alldata[["Fishery Statistics"]] |>
	_[i = District %in% c("Forth", "Leven"), j = , by = ]

forth_water_basin <- c(
  # Edinburgh Coastal
  "Wardie Beach",
  "Portobello (West)",
  "Portobello (Central)",
  "Fisherrow Sands",

  # East Lothian Coastal
  "Longniddry",
  "Seton Sands",
  "Gullane",
  "Yellow Craig",
  "Broad Sands",
  "North Berwick (West)",
  "North Berwick (Milsey Bay)",
  "Seacliff",
  "Dunbar (Belhaven)",
  "Dunbar (East)",
  "Whitesands",
  "Thorntonloch",
  "Pease Bay",

  # Berwick Coastal / Eye Water
  "Coldingham",
  "Eyemouth",

  # South Fife Coastal
  "Aberdour (Silversands)",
  "Aberdour Harbour (Black Sands)",
  "Burntisland",
  "Kinghorn (Harbour Beach)",
  "Kinghorn (Pettycur)",
  "Kirkcaldy (Seafield)",
  "Leven",
  "Lower Largo",
  "Elie (Harbour) and Earlsferry",
  "Elie (Ruby Bay)",
  "Anstruther (Billow Ness)",
  "Crail (Roome Bay)",
  "Kingsbarns",
  "St Andrews (East Sands)",
  "St Andrews (West Sands)"
)

alldata[["Bathing Waters Application"]] |>
	_[i = `Bathing water` %in% c(forth_water_basin), j = , by = ]
	
alldata[["Butterflies"]]

