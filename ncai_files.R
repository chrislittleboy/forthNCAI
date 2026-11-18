library(data.table)
library(haven)
library(rvest)
library(readxl)

###### DOWNLOANDING AND PROCESSING DATA TO COMPUTE NCAI

#### Outdoor visits per week ####
# get file paths for social_public datasets
ovpw.folder <- "./Data/NCAI/Outdoor visits per week"
ovpw.files <- list.dirs(ovpw.folder)[grep("(stata/stata/stata)|(stata11_se/stata11_se)", 
                                          list.dirs(ovpw.folder))] |>
  lapply(list.files, full.names = TRUE) |>
  unlist()
# get files
ovpw.files <- ovpw.files[grep("social_public", ovpw.files)]
ovpw.year <- regmatches(ovpw.files, regexpr("20[0-9]{2}", ovpw.files))
# files into a single list
mylist <- lapply(ovpw.files, function(X) read_dta(X) |> as.data.table() ) |>
	setNames(ovpw.year)
# column indices to pass to Map functional
colind <- lapply(mylist, function(X) 
  which(colnames(X) %in% c("UNIQIDNEW", "la", "LA_WT", "LA_WT2", "council", "outdoor")))
# Map -- apply lists elementwise to a function
mylist <- Map(function(X, Y) X[, ..Y], mylist, colind)
lapply(mylist, setnames, 
				old = c("LA_WT2", "council"), 
				new = c("LA_WT", "la"), 
				skip_absent = TRUE)
# binding everything into a single data.table
mydata <- rbindlist(mylist, use.names = TRUE, fill = TRUE, 
                    idcol = "year")
					
fwrite(mydata, "./Data/NCAI/Outdoor visits per week.csv")

#### Groundwater levels ####
station.lookup <- read_html("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getStationList&returnfields=station_name,station_id,station_carteasting,station_cartnorthing") |>
	html_table(header = TRUE) |>
	as.data.table()
ts.lookup <- read_html("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getTimeseriesList&ts_name=Month.Mean&parametertype_name=GWLVL") |>
	html_table(header = TRUE) |>
	as.data.table()
ts.lookup[i = , j = ts_id := as.character(ts_id), by = ]
ts.ids <- na.omit(ts.lookup$ts_id)
gwlvl.urls <- sprintf("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getTimeseriesValues&ts_id=%s&from=1981-01-01",
	ts.ids)
t.reader <- function(x, readfrom = 1) {
	x <- read_html(x) |> html_table()
	x <- as.data.table(x)
	x <- x[i = readfrom:nrow(x), j = , by = ] 
	colnames(x) <- c('Timestamp', 'Value')
	x[i = , j = Value := as.numeric(Value), by = ]
	return(x)
	}
gwlvl <- lapply(gwlvl.urls, 
	t.reader, readfrom = 5) |>
	setNames(ts.ids) |>
	rbindlist(use.names = TRUE, fill = TRUE, idcol = 'id')
	
gwlvl <- merge(gwlvl, ts.lookup[, list(ts_id, station_id)], 
	by.x = 'id', by.y = 'ts_id') |>
	merge(station.lookup, by = 'station_id')
	
fwrite(gwlvl, "./Data/NCAI/Groundwater levels.csv")

#### Tide levels ####
station.lookup <- read_html("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getStationList&returnfields=station_name,station_id,station_carteasting,station_cartnorthing") |>
	html_table(header = TRUE) |>
	as.data.table()
ts.lookup <- read_html("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getTimeseriesList&ts_name=Month.Mean&parametertype_name=S") |>
	html_table(header = TRUE) |>
	as.data.table()
ts.lookup[i = , j = ts_id := as.character(ts_id), by = ]
ts.ids <- na.omit(ts.lookup$ts_id)
stage.urls <- sprintf("https://timeseries.sepa.org.uk/KiWIS/KiWIS?service=kisters&type=queryServices&datasource=0&request=getTimeseriesValues&ts_id=%s&from=1981-01-01",
	ts.ids)
t.reader <- function(x, readfrom = 1) {
	x <- read_html(x) |> html_table()
	x <- as.data.table(x)
	x <- x[i = readfrom:nrow(x), j = , by = ] 
	colnames(x) <- c('Timestamp', 'Value')
	x[i = , j = Value := as.numeric(Value), by = ]
	return(x)
	}
stage <- lapply(stage.urls, 
	t.reader, readfrom = 5) |>
	setNames(ts.ids) |>
	rbindlist(use.names = TRUE, fill = TRUE, idcol = 'id')
	
stage <- merge(stage, ts.lookup[, list(ts_id, station_id)], 
	by.x = 'id', by.y = 'ts_id') |>
	merge(station.lookup, by = 'station_id')
	
fwrite(stage, "./Data/NCAI/River level (Stage).csv")

#### Birds (BTO) ####
bird.data <- fread("./Data/NCAI/BTO/BBS_bird_dataset.csv")
grid.lookup <- fread("./Data/NCAI/BTO/grid_square_coordinates_lookup.csv")

bto <- merge(bird.data, grid.lookup, by = "square") |>
		_[i = Scottish_woodland == 1, j = , by = ]
setcolorder(bto, c("ETRS89Lat", "ETRS89Long", "BBS_region"), after = 2)
section_n <- grep("section", colnames(bto))
bto <- bto[i = , j = total_count := rowSums(.SD), by = , .SDcols = section_n]
bto
fwrite(bto, "./Data/NCAI/British Birding Survey.csv")

#### Water Chemicals ####
sepa.chem <- list.files("./Data/NCAI/SEPA/Chemicals", 
	full.names = TRUE) |>
	lapply(function(X) as.data.table(read_excel(X))) |>
	rbindlist(use.names = TRUE, fill = TRUE)

sepa.chem <- sepa.chem[i = order(`Date Sampled`), j = , by = ]

phosphates <- sepa.chem |>
	_[i = grep("Total Phosph", Determinand)] |>
	_[i = grep("mg/L", Unit)]
	
nitrates <- sepa.chem |>
	_[i = grep("Nitrate", Determinand)] |>
	_[i = grep("mg/L", Unit)]
fwrite(phosphates, "./Data/NCAI/SEPA Phosphorus.csv")
fwrite(nitrates, "./Data/NCAI/SEPA Nitrates.csv")

#### Water quality ####
# load all data
sepa.qual.cols <- fread("./Data/NCAI/SEPA/Quality/Water Classification Hub - Classification data by water body.csv") |>
	_[1:2] |>
	lapply(paste)
sepa.qual.data <- fread("./Data/NCAI/SEPA/Quality/Water Classification Hub - Classification data by water body.csv",
	skip = 2, header = FALSE)
sepa.qual.info <- fread("./Data/NCAI/SEPA/Quality/Water Classification Hub - Water Body - Protected Area General Information.csv")
idcols <- sapply(sepa.qual.cols, function(X) X[1] == X[2])
sepa.qual.cols <- lapply(sepa.qual.cols, 
		function(X) ifelse(X[1] == X[2], X[1], paste(X[1], X[2]))) |>
		unlist()

setnames(sepa.qual.data, sepa.qual.cols)
# long data format
sepa.qual.data <- melt(sepa.qual.data, id.vars = which(idcols))
# split variable column
# then, all "" turn into NA
sepa.qual.data |>
	_[
	i = , 
	j = c("Year", "Variable") := tstrsplit(variable, " ", keep = 1:2),
	by = ] |>
	_[
	i = ,
	j = value := ifelse(value == "", NA, value)]
# value as last column
setcolorder(sepa.qual.data, "value", after = ncol(sepa.qual.data))
# merge data and info
sepa.qual <- merge(sepa.qual.info, sepa.qual.data, by = "ID")
fwrite(sepa.qual, "./Data/NCAI/Water Quality.csv")
#### Fishing (nets and rods) ####
list.files("./Data/NCAI/Fishing",
	full = TRUE) |>
	lapply(fread) |>
	setNames(c("Nets", "Rods")) |>
	rbindlist(idcol = "Fishery", fill = TRUE, use.names = TRUE) |>
	fwrite("./Data/NCAI/Fishery Statistics.csv")
#### Butterflies
# Read a large csv file
butterflies <- fread("./Data/NCAI/0000746-260623161305970.csv")
butterflies <- butterflies[stateProvince == "Scotland"]
fwrite(butterflies, "./Data/NCAI/Butterflies.csv")