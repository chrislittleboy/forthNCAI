library(data.table)
library(sf)
library(terra)
library(ggplot2)
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

# Fishery statistics
fish <- alldata[["Fishery Statistics"]] |>
  _[i = District %in% c("Forth", "Leven"), j = , by = ]

fwb.bw.loc <- c(
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

# Bathing waters
bath <- alldata[["Bathing Waters Application"]] |>
  _[i = `Bathing water` %in% c(fwb.bw.loc), j = , by = ]

# British Birding Survey (problem: ETRS89 (4258))
bird <- st_as_sf(alldata[["British Birding Survey"]], coords = c("ETRS89Long", "ETRS89Lat"), crs = 4258) |>
  st_transform(crs = st_crs(f2o.hg)) |>
  st_intersection(f2o.hg)

# Butterflies	
bfly <- st_as_sf(alldata[["Butterflies"]], coords = c("decimalLongitude", "decimalLatitude"), crs = 4326) |>
  st_transform(crs = st_crs(f2o.hg)) |>
  st_intersection(f2o.hg)

# Groundwater levels
gwl <- st_as_sf(alldata[["Groundwater levels"]], coords = c("station_carteasting", "station_cartnorthing"), 
                crs = 27700) |>
  st_intersection(f2o.hg)

# Outdoor visits per week
# Council area reference dataset
la.ref <- data.frame(
  area = c("Aberdeen City", "Aberdeenshire", "Angus", "Argyll and Bute", "Borders",
           "Clackmannshire", "Dumfries and Galloway", "Dundee City", "East Ayrshire",
           "East Dumbartonshire", "East Lothian", "East Renfrewshire", "Edinburgh City",
           "Falkirk", "Fife", "Glasgow City", "Highland", "Inverclyde", "Midlothian",
           "Moray", "North Ayrshire", "North Lanarkshire", "Orkney", "Perth and Kinross",
           "Renfrewshire", "Shetland", "South Ayrshire", "South Lanarkshire", "Stirling",
           "West Dumbartonshire", "West Lothian", "Western Isles", "No school child",
           "Don't know"),
  code = c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
           "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5",
           "6", "ZY", "ZZ"),
  stringsAsFactors = FALSE
)
# inner join with la.ref
alldata[["Outdoor visits per week"]] <- merge(
  alldata[["Outdoor visits per week"]],
  la.ref, 
  by.x = "la", by.y = "code")
outd <- st_as_sf(alldata[["Outdoor visits per week"]], coords = c("station_carteasting", "station_cartnorthing"), 
                 crs = 27700) |>
  st_intersection(f2o.hg)
# River level (Stage)
stag <- st_as_sf(alldata[["River level (Stage)"]], coords = c("station_carteasting", "station_cartnorthing"), 
                 crs = 27700) |>
  st_intersection(f2o.hg)
# Water quality
wq <- st_as_sf(alldata[["Water Quality"]], coords = c("EASTING", "NORTHING"), 
                       crs = 27700) |>
  st_intersection(f2o.hg)
