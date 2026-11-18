## Process data from the expert survey on importance of ecosystem services
## Kate O'Hara 
## 02-07-2026

# 18-NOV-2026 adding some data as downloaded from Jisc Online Surveys to make a
# start on a cleaning script. 

# Setup
svy_dat <- file("imp_wts_survey", "svy_dat_prelim.csv")
d <- read.csv(svy_dat)
