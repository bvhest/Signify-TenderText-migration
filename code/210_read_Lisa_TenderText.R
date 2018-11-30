#
# Read and parse TenderText.
#
#
# BHE, 21-11-2018
#

#library(XML)
library(tidyverse)
library(readxl)

###############################################################################
# read spreadsheet
###############################################################################

LisaTT.r <-
  readxl::read_xlsx(path = "./data/TenderText_DACH_2018-10-23.xlsx",
                    sheet = 1, 
                    skip = 0)

StepFPs.r <-
  readr::read_csv(file="./data/prod_blue_tree.csv")

StepAttLov.r <-
  readr::read_csv(file="./data/tt_attribute_lov.csv")
  
StepAttributes.r <-
  readr::read_csv(file="./data/attributes_de_DE.csv")

###############################################################################
# munge data
###############################################################################
#  add FP-id and merge CF
LisaTT.c <-
  LisaTT.r %>%
  dplyr::rename(Code_12NC = '12NC') %>%
  dplyr::mutate(FP_ID = paste("FP", Code_12NC, sep="-")) %>%
  dplyr::left_join(StepFPs.r, by = "FP_ID")

StepAttLov.c <-
  StepAttLov.r %>%
  dplyr::left_join(StepAttributes.r, by = "ID")

###############################################################################
# validations
###############################################################################

# how many unique CF's do we have?
LisaTT.c %>%
  dplyr::distinct(CF_ID) %>%
  dplyr::count()

# answer = 140


# 1. can TT be migrated to the CF?
#    (in other words; do all FP's in a CF have the same TT)?

LisaTT.c %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::summarise(unique_tt_count = n_distinct(BasicText)) %>%
  dplyr::filter(unique_tt_count > 1) %>%
  dplyr::arrange(desc(unique_tt_count))

# # A tibble: 107 x 2
# CF_ID        unique_tt_count
# <chr>                  <int>
#   1 COMF-3293                138
# 2 COMF-1280                129
# 3 COMF-1581                120
# 4 COMF-32617                98
# 5 COMF-4800                 81
# 6 COMF-5710018              81
# 7 COMF-3039427              78
# 8 COMF-5765544              75
# 9 NA                        72
# 10 COMF-3336                 59
# # ... with 97 more rows
# 
# Answer: in general its not possible to migrate to the CF, because most FP's have a unique TT.'

LisaTT.c %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::summarise(unique_tt_count = n_distinct(TextBrief)) %>%
  dplyr::filter(unique_tt_count > 1) %>%
  dplyr::arrange(desc(unique_tt_count))

# Answer: confirmed with the TextBrief.


###############################################################################
# more munging
###############################################################################

# 1. split the textBrief into separate fields for which the LOV-id can be found.
#    note: probably a mapping of the separate fields to the LOV-values is required!

LOV_values.c <-
  LisaTT.c %>%
  dplyr::distinct(TextBrief, .keep_all = TRUE) %>% # from 2955 down to 1120 rows...
  dplyr::mutate(attributes = stringr::str_split(TextBrief, pattern = ","),
                attributes = stringr::str_trim(attributes)) %>%
  dplyr::select(FP_ID, attributes)

glimpse(LOV_values.c)

# !!!!!
# ToDo:
# split attributes into long-form & merge with StepAttLov.c !
