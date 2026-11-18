## Clean data from the expert survey on importance of ecosystem services
## Kate O'Hara 
## 02-07-2026

# 18-Nov-2026 Adding a preliminary importance weights survey set to begin 
# building data prep for use in forthNCAI. 

# Setup
library(readr)
library(stringr)
library(tibble)
library(dplyr)

svy_dat <- file.path("imp_wts_survey", "svy_dat_prelim.csv")
raw <- readr::read_csv(svy_dat)
View(raw)

# Make short names and a codebook
codebook <- tibble::tibble(
  original = names(raw),
  short = (c(
    "id",
    "permit1",
    "permit2",
    "permit3",
    "permit4",
    "permit5",
    "sample_group",
    "g1_prov",
    "g2_regu",
    "g3_cult",
    "p1_1_crops",
    "p1_2_farmanimals",
    "p1_3_wildplantfood",
    "p1_4_aquaculture",
    "p1_5_drinkingwater",
    "p1_6_materialsdirect",
    "p1_7_materialsagri",
    "p1_8_genetic",
    "p1_9_nondrinkwater",
    "p1_10_plantenergy",
    "p1_11_animalfuel",
    "p1_12_animalmechanical",
    "r2_1_medwastebiota",
    "r2_2_medwasteecosys",
    "r2_3_medmassflow",
    "r2_4_medliquidflow",
    "r2_5_medgasflow",
    "r2_6_pollination",
    "r2_7_nursery",
    "r2_8_pestdisease",
    "r2_9_soilform",
    "r2_10_conditionwater",
    "r2_11_climatereg",
    "c3_1_physical",
    "c3_2_heritage",
    "c3_3_aesthetic",
    "c3_4_symbolic",
    "c3_5_existence",
    "expertise",
    "confid_ownopin",
    "confid_manyopin"
    )
  )
)

# Catch any mismatch of vector lengths:
stopifnot(length(codebook$short) == ncol(raw), !anyDuplicated(codebook$short))

# Query this like this:
# what_is <- function(x) codebook$original[codebook$short %in% x]
# what_is("expertise")
# Or, e.g.
# dplyr::filter(codebook, stringr::str_detect(short, "pollin"))
# Use this for help with reg ex later:
# vignette("regular-expressions", package = "stringr")

# Apply new variables by matching to the codebook:
names(raw) <- codebook$short[match(names(raw), codebook$original)]
# View(raw)

# Make working dataset
d <- raw |> 
  filter(if_all(starts_with("permit"), \(x) x == "Yes")) |> 
  select(!starts_with("permit"))

# View(d)         

# Save a copy with a date on it
write_csv(d, file.path("imp_wts_survey", format(Sys.time(), "imp_wts_svy_clean_%Y-%m-%d_%H:%M:%S")))

# Next step: produce_importance_weights.R
####


