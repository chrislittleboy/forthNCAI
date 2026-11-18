## Starting with .csv of clean data (from clean_survey_data.R), generate 
## data frames of weight survey responses for computation. 

# SETUP 
library(tidyverse)
library(openNCAI)

# LOAD DATA
clean_svy_dat <- file.path("imp_wts_survey", 
                                 "imp_wts_svy_clean_2026-11-18_15:28:28")
clean <- read_csv(clean_svy_dat)
# View(clean)

# GET WEIGHT VECTORS 
# First let's just get subsets containing only the weights in each set:

# Between-group weights
svy_between_weights <- clean |> 
  select(matches("^g\\d_"))
names(svy_between_weights)

# Provisioning service weights
svy_within_prov_weights <- clean |> 
  select(matches("^p\\d_"))
names(svy_within_prov_weights)

# Regulating and maintenance service weights
svy_within_regu_weights <- clean |> 
  select(matches("^r\\d_"))
names(svy_within_regu_weights)

# Provisioning service weights
svy_within_cult_weights <- clean |> 
  select(matches("^c\\d_"))
names(svy_within_cult_weights)

# Just for now, to try out, we could see how Scotland's NCAI changes if we 
# used the mean of the F2O sweights.

f2o_mean_between <- setNames(
  lapply(svy_between_weights, mean),
  names(ns_es_label_tree)
)

within_weights_list <- list(
  svy_within_prov_weights,
  svy_within_regu_weights,
  svy_within_cult_weights
) |> setNames(names(ns_es_label_tree))

f2o_mean_within <- Map(
  \(df, labels) setNames(lapply(df, mean), labels),
  within_weights_list,
  ns_es_label_tree
)

# Calculate original Scotland's NCAI:
scotncaiorig <- get_ncai(habitat_extent = ns_habitat_extent,
                         ci_scores = ns_ci_scores,
                         habitats_label_tree = ns_habitats_label_tree, 
                         es_label_tree = ns_es_label_tree,
                         year_list = ns_year_list,
                         provision_per_unit_scores = ns_provision_per_unit_scores,
                         between_importance_scores = ns_between_importance_scores,
                         within_importance_scores = ns_within_importance_scores,
                         ci_relevance_matrices = ns_ci_relevance_matrices,
                         indicator_directory = ns_indicator_directory) |> 
  tibble::rownames_to_column("year") |>
  mutate(year = as.integer(year))

# Calculate it using mean of the weights from the survey:
scotncaif2o <- get_ncai(habitat_extent = ns_habitat_extent,
                         ci_scores = ns_ci_scores,
                         habitats_label_tree = ns_habitats_label_tree, 
                         es_label_tree = ns_es_label_tree,
                         year_list = ns_year_list,
                         provision_per_unit_scores = ns_provision_per_unit_scores,
                         between_importance_scores = f2o_mean_between,
                         within_importance_scores = f2o_mean_within,
                         ci_relevance_matrices = ns_ci_relevance_matrices,
                         indicator_directory = ns_indicator_directory) |> 
  tibble::rownames_to_column("year") |>
  mutate(year = as.integer(year))

# Append the two sets:
both <- bind_rows(orig = scotncaiorig, f2o = scotncaif2o, .id = "series")

# And graph them:
ggplot(both, aes(x = year, y = smoothed_index, colour = series)) +
  geom_line()
# The two versions are quite close. 

# Next we could look at how similar the weights actually are. 