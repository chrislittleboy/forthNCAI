library(data.table)
library(sf)
library(terra)
library(ggplot2)
setwd("C:/Users/miell/OneDrive/Desktop/FORTH2O Data Specialist")
csvdata <- list.files("Data/NCAI", 
                      pattern = ".csv", full = TRUE) |>
  lapply(fread)
shapedata <- list.files("Data/NCAI",
                      pattern = ".shp", full = TRUE) |>
  lapply(read_sf)
alldata <- list(csvdata, shapedata) |>
  unlist(recursive = FALSE)

# FORTH2O area of interest
f2oaoi <- read_sf("Data/gov/census/geog/f2o/f2oaoi.shp")
# Higher geography
hg <- read_sf("Data/gov/census/outputs/hg.shp")
# Intersection of FORTH2O area and higher geography; removes water
f2o.hg <- st_intersection(f2oaoi, hg)

mask.by.fwb <- function(x) {
  mask(crop(x))}
# Now, we extract dataset names
csvnames <- lapply(list.files("Data/NCAI", pattern = ".csv"), 
                   function(X) gsub(".csv", "", X)) |>
  unlist(recursive = FALSE)
shapenames <- lapply(list.files("Data/NCAI", pattern = ".shp"), 
                   function(X) gsub(".shp", "", X)) |>
  unlist(recursive = FALSE)
# combine
allnames <- c(csvnames, shapenames)
# assign to the list of dataframes
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

# British Birding Survey
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
f2o.ca <- c("East Lothian", "Midlothian", "West Lothian", "Edinburgh", 
            "Falkirk", "Stirling", "Clack", "Fife")

outd <- subset(alldata[["Outdoor visits per week"]], grepl(paste0(f2o.ca, collapse = "|"), area))
# River level (Stage)
stag <- st_as_sf(alldata[["River level (Stage)"]], coords = c("station_carteasting", "station_cartnorthing"), 
                 crs = 27700) |>
  st_intersection(f2o.hg)
# Water quality
wq <- st_as_sf(alldata[["Water Quality"]], coords = c("easting", "northing"), 
               crs = 27700) |>
  st_intersection(f2o.hg)
# Phosphorus
phos <- subset(alldata[["SEPA Phosphorus"]], !is.na(Easting) & !is.na(Northing)) |>
  st_as_sf(coords = c("Easting", "Northing"), crs = 27700) |>
  st_intersection(f2o.hg)
# Nitrates
nitr <- subset(alldata[["SEPA Nitrates"]], !is.na(Easting) & !is.na(Northing)) |>
  st_as_sf(coords = c("Easting", "Northing"), crs = 27700) |>
  st_intersection(f2o.hg)
# Abstractions
abst <- st_as_sf(alldata[["Abstractions"]], coords = c("Easting", "Northing"), crs = 27700) |>
  st_intersection(f2o.hg)
# Site conditions
site <- st_intersection(alldata[["Site Conditions"]], f2o.hg)

# Write all datasets as shapefiles
setwd("C:/Users/miell/OneDrive/Desktop/FORTH2O Data Specialist/Outputs/forthNCAI datasets")
fwrite(fish, "fishery-stats.csv")
fwrite(bath, "bathing-waters.csv")
write_sf(bird, "birding-survey.shp")
write_sf(bfly, "butterflies.shp")
write_sf(gwl, "ground-water-lvl.shp")
fwrite(outd, "outdoor-visits.csv")
write_sf(stag, "river-stage.shp")
write_sf(wq, "water-qual.shp")
write_sf(phos, "phosphorus.shp")
write_sf(nitr, "nitrates.shp")
write_sf(abst, "abstractions.shp")

site$FID <- NULL
write_sf(site, "site-conditions.gpkg")
