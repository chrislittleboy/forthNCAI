library(openNCAI)
library(terra)
library(sf)
##### HABITAT EXTENTS

##### WEIGHTS

##### CONDITION INDICATORS

files <- list.files("./data/condition_indicators", full.names = TRUE)
files
longhand <- substr(basename(files))
longhand <- sub(pattern = "(.*)\\..*$", replacement = "\\1", longhand)
shorthand <- c("bwa", "bbs", "but","fis", "gwa", "ov", "rl", "nit", "pho", "wq")
for(i in 1:10) {
  assign(shorthand[i], read.csv(files[i]))
}

aoi <- vect("./data/f2oaoi_noholes.shp")
bbsv <- vect(bbs, crs = sf::st_crs(4326)[[2]], geom = c("ETRS89Long","ETRS89Lat"))
bbsv <- project(bbsv, aoi)
bbsvf <- bbsv[aoi]

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