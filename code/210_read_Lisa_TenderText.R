#
# Read and parse TenderText.
#
#
# BHE, 21-11-2018/10-01-2019
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

LisaTT2STEP_attribute_mapping.r <-
  readxl::read_xlsx(path = "./data/LiSA_Attributes_withEMCC-STEP_Mapping_JE20181212.xlsx",
                    sheet = 2, 
                    skip = 1)
StepFPs.r <-
  readr::read_csv(file="./data/prod_blue_tree.csv")

StepTTAttLov.r <-
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

StepTTAttLov.c <-
  StepTTAttLov.r %>%
  dplyr::left_join(StepAttributes.r, by = "ID")

remove(StepTTAttLov.r, StepAttributes.r, LisaTT.r, StepFPs.r)

###############################################################################
# validations
###############################################################################

# how many unique CF's do we have?
LisaTT.c %>%
  dplyr::distinct(CF_ID) %>%
  dplyr::count()
# answer = 140

# how many unique FP's do we have?
LisaTT.c %>%
  dplyr::distinct(FP_ID) %>%
  dplyr::count()
# answer = 2839


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
# Answer: in general its not possible to migrate to the CF, because most FP's have a unique TT.
#
# Note; based on STEP-data, some products can not be linked to a commercial-family...

LisaTT.c %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::summarise(unique_tt_count = n_distinct(BasicText)) %>%
  dplyr::filter(unique_tt_count > 1) %>%
  dplyr::arrange(desc(unique_tt_count))

# Answer: confirmed with the TextBrief.

# check which introductionText can be migrated to the family level:
LisaTT_introductionText.c <-
  LisaTT.c %>%
  dplyr::filter(!is.na(BasicText)) %>%
  dplyr::mutate(introductionText = stringr::str_replace_all(BasicText, pattern = "\r\r", replacement = " ")) %>% # remove newline characters
  dplyr::mutate(introductionText = stringr::str_remove_all(introductionText, pattern = "\r")) %>% # remove newline characters
  dplyr::mutate(introductionText = stringr::str_remove_all(introductionText, pattern = "\n")) %>% # remove newline characters
  dplyr::mutate(introductionText = stringr::str_trim(introductionText, side = "both")) %>% # remove newline characters
  dplyr::select(CF_ID, FP_ID, introductionText) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::mutate(FP_count = n(),                              # count number of products per family
                IT_count = n_distinct(introductionText)) %>% # count unique introduction texts per family
  dplyr::ungroup()

LisaTT_introductionText_per_CF.c <-
  LisaTT_introductionText.c %>%
  # and filter out those occurances where the number of unique texts = 1 (all products have same text)
  dplyr::filter(IT_count == 1) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::distinct(CF_ID, introductionText) %>%
  dplyr::arrange(CF_ID)

LisaTT_introductionText_per_FP.c <-
  LisaTT_introductionText.c %>%
  # and filter out those occurances where the number of products is equal to the number of unique texts
  dplyr::filter(IT_count > 1) %>%
  dplyr::arrange(CF_ID, FP_ID)

readr::write_excel_csv(LisaTT_introductionText_per_CF.c,
                       path = "./data/result/LisaTT_introductionText_per_CF.csv")

readr::write_excel_csv(LisaTT_introductionText_per_FP.c,
                       path = "./data/result/LisaTT_introductionText_per_FP.csv")

###############################################################################
# more munging 1: TT Attributes
###############################################################################

# 1. split the textBrief (listing of product TT-related attributes) into separate 
#    fields for which the LOV-id can be found.
#    note: probably a mapping of the separate fields to the LOV-values is required!
#

LOV_values.c <-
  LisaTT.c %>%
  dplyr::distinct(TextBrief, .keep_all = TRUE) %>% # from 2955 down to 1120 rows...
  tidyr::separate(col = TextBrief, 
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
                  sep = ",") %>%
  dplyr::select(FP_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) 

# merge with StepAttLov.c
LOV_values_with_STEP_IDs.c <-
  LOV_values.c %>%
  dplyr::inner_join(StepTTAttLov.c,
                   by = c("value" = "Name"))

# NOT A SINGLE MATCH !!!

remove(LOV_values_with_STEP_IDs.c, LOV_values.c)

# Possible migration strategy
#
# 1. add new values to the TT LOV which are only valid for the "de_XX" contexts.
# 2. create mapping table for the LOV-values
#

# Number of unique attributes (that can be migrated when a mapping table is created)
Unique_TT_attributes.c <-
  LOV_values.c %>%
  dplyr::select(value) %>%
  unique() %>%
  arrange(value)

remove(Unique_TT_attributes.c)

# Repeat, but this time split on all three separator-characters found in the dataset: ";", "-", "," 
# group into data-sets that can be migrated to CF- and FP-level:
LisaTT_attributes.c <-
  LisaTT.c %>%
  dplyr::mutate(attributes = TextBrief) %>%
  dplyr::select(CF_ID, FP_ID, attributes) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::mutate(FP_count = n(),                        # count number of products per family
                AM_count = n_distinct(attributes)) %>% # count unique attributes per family
  dplyr::ungroup()

#
# TEST-code
#
# LisaTT_attributes.c <-
#   LisaTT.c %>%
#   tidyr::separate(col = TextBrief, 
#                   into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
#                   sep = ";") %>%
#   dplyr::select(CF_ID, FP_ID, starts_with("tta")) %>%
#   # from wide to long format
#   tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
#   # remove attributes with na-values
#   dplyr::filter(!is.na(value)) %>%
#   tidyr::separate(col = value, 
#                   into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
#                   sep = "-") %>%
#   dplyr::select(CF_ID, FP_ID, starts_with("tta")) %>%
#   # from wide to long format
#   tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
#   # remove attributes with na-values
#   dplyr::filter(!is.na(value)) %>%
#   tidyr::separate(col = value, 
#                   into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
#                   sep = ",") %>%
#   dplyr::select(CF_ID, FP_ID, starts_with("tta")) %>%
#   # from wide to long format
#   tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
#   # remove attributes with na-values
#   dplyr::filter(!is.na(value)) 


LisaTT_attributes_per_CF.c <-
  LisaTT_attributes.c %>%
  # and filter out those occurances where the number of unique texts = 1 (all products have same text)
  dplyr::filter(AM_count == 1) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::distinct(CF_ID, attributes) %>%
  dplyr::arrange(CF_ID) %>%
  dplyr::ungroup() %>%
  tidyr::separate(col = attributes, 
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
                  sep = ";") %>%
  dplyr::select(CF_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) %>%
  #
  # !!! splitting by "-" results in incorrect splitup for some texts...use " - ". !!!
  #
  tidyr::separate(col = value,
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"),
                  sep = " - ") %>%
  dplyr::select(CF_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) %>%
  tidyr::separate(col = value,
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"),
                  sep = ", ") %>%
  dplyr::select(CF_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value))

# Example of expected attribute values:
# product : FP-910683000526
# family  : COMF-1023
# textbrief = attributes = 
#   "MAXOS Reflektorstirnwand, 1/2lampig für Facettenreflektor TL-D in Kunstoff, in Weiß (RAL9016) eingefärbt."
# 
# expected attributes:
#   1 : MAXOS Reflektorstirnwand
#   2 : 1/2lampig für Facettenreflektor TL-D in Kunstoff
#   3 : in Weiß (RAL9016) eingefärbt
#
# actual attributes:
LisaTT_attributes_per_CF.c %>%
  dplyr::filter(CF_ID == "COMF-1023")
# NOT OK!!!
# TODO: 
#  1) check text split-up ! DONE 11-01-2018
#  2) text clean-up: remove 
#     a. leading/trailing spaces, 
#     b. \r\r\n new-line characters
#     c. end-of-line punctuation mark

LisaTT_attributes_per_CF.c <-
  LisaTT_attributes_per_CF.c %>%
  dplyr::mutate(value = stringr::str_trim(value, side = "both")) %>% # remove leading/trailing spaces
  dplyr::mutate(value = stringr::str_remove(value, pattern = "\r\r\n")) %>% # remove new-line characters
  dplyr::mutate(value = stringr::str_remove(value, pattern = "\\.$")) # remove end-of-line punctuation mark

LisaTT_attributes_per_CF.c %>%
  dplyr::filter(CF_ID == "COMF-1023")
# OK !!!

# check 2: COMF-4810 has attributes splitted by " - ". Five should be present!
# input is "ST740T - LED-Modul 1.500 lm - Elektronisches Betriebsgerät,schaltbar, gleichspannungsgeeignet für Notlichtbetrieb - Tiefstrahlend - Weiß und Schwarz"
LisaTT_attributes_per_CF.c %>%
  dplyr::filter(CF_ID == "COMF-4810")
# NOK !!! because one of the attributes has values separated by a comma ",".
#
# after splitting on ", " the result is better, but not good.
#
# ... Too many splitting characters are used in LISA. Shitty data maintenance... :(

LisaTT_attributes_per_FP.c <-
  LisaTT_attributes.c %>%
  # and filter out those occurances where the number of unique texts = 1 (all products have same text)
  dplyr::filter(AM_count > 1) %>%
  dplyr::group_by(FP_ID) %>%
  dplyr::distinct(FP_ID, attributes) %>%
  dplyr::arrange(FP_ID) %>%
  dplyr::ungroup() %>%
  tidyr::separate(col = attributes, 
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
                  sep = ";") %>%
  dplyr::select(FP_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) %>%
  tidyr::separate(col = value, 
                  into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
                  sep = "-") %>%
  dplyr::select(FP_ID, starts_with("tta")) %>%
  # from wide to long format
  tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) %>%
  # tidyr::separate(col = value, 
  #                 into = c("tta0", "tta1", "tta2", "tta3", "tta4", "tta5", "tta6", "tta7", "tta8", "tta9"), 
  #                 sep = ",") %>%
  # dplyr::select(FP_ID, starts_with("tta")) %>%
  # # from wide to long format
  # tidyr::gather(key = "attribute", value = "value", tta0:tta9) %>%
  # # remove attributes with na-values
  # dplyr::filter(!is.na(value)) %>%
  dplyr::mutate(value = stringr::str_trim(value, side = "both")) %>% # remove leading/trailing spaces
  dplyr::mutate(value = stringr::str_remove(value, pattern = "\r\r\n")) %>% # remove new-line characters
  dplyr::mutate(value = stringr::str_remove(value, pattern = "\\.$")) # remove end-of-line punctuation mark


readr::write_excel_csv(LisaTT_attributes_per_CF.c,
                       path = "./data/result/LisaTT_Attributes_per_CF.csv")

readr::write_excel_csv(LisaTT_attributes_per_FP.c,
                       path = "./data/result/LisaTT_Attributes_per_FP.csv")

###############################################################################
# more munging 2: TT Approbation Marks
###############################################################################

# 1. split the Certificates (listing of product TT-related approbation marks) 
#    into separate fields for which the LOV-id can be found.
#

Approbation_marks.c <-
  LisaTT.c %>%
  dplyr::distinct(Certificates, .keep_all = TRUE) %>% # from 2955 down to 121 rows...
  tidyr::separate(col = Certificates, 
                  into = c("ttam0", "ttam1", "ttam2", "ttam3", "ttam4", "ttam5", "ttam6", "ttam7", "ttam8", "ttam9"), 
                  sep = ";") %>%
  dplyr::select(FP_ID, starts_with("ttam")) %>%
  # from wide to long format
  tidyr::gather(key = "appmark", value = "value", ttam0:ttam9) %>%
  # remove attributes with na-values
  dplyr::filter(!is.na(value)) 

Unique_Approbation_marks.c <-
  Approbation_marks.c %>%
  dplyr::select(value) %>%
  unique() %>%
  arrange(value)

# 32 unique values (including one empty value and a "NA' value)


LisaTT_appmarks.c <-
  LisaTT.c %>%
  dplyr::mutate(appmarks = Certificates) %>%
  dplyr::select(CF_ID, FP_ID, appmarks) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::mutate(FP_count = n(),                              # count number of products per family
                AM_count = n_distinct(appmarks)) %>% # count unique introduction texts per family
  dplyr::ungroup()

LisaTT_appmarks_per_CF.c <-
  LisaTT_appmarks.c %>%
  # and filter out those occurances where the number of unique texts = 1 (all products have same text)
  dplyr::filter(AM_count == 1) %>%
  dplyr::group_by(CF_ID) %>%
  dplyr::distinct(CF_ID, appmarks) %>%
  dplyr::arrange(CF_ID)

LisaTT_appmarks_per_FP.c <-
  LisaTT_appmarks.c %>%
  # and filter out those occurances where the number of products is equal to the number of unique texts
  dplyr::filter(AM_count > 1) %>%
  dplyr::arrange(CF_ID, FP_ID)

readr::write_excel_csv(LisaTT_appmarks_per_CF.c,
                       path = "./data/result/LisaTT_approbation_marks_per_CF.csv")

readr::write_excel_csv(LisaTT_appmarks_per_FP.c,
                       path = "./data/result/LisaTT_approbation_marks_per_FP.csv")


# 
# <TendertextAttributes>
#   <Introduction_Tendertext_FP>
#   <?Target ?>
#   </Introduction_Tendertext_FP>
#   <TenderTextAttributes_FP>
#   <?Target ?>
#   </TenderTextAttributes_FP>
#   <Approbation_Mark_Portal_Tendertext>
#   <CE-MARK>
#   <?Target ?>
#   </CE-MARK>
#   <ENEC-MARK>
#   <?Target ?>
#   </ENEC-MARK>
#   <FLAM-MARK>
#   <?Target ?>
#   </FLAM-MARK>
#   <GLWRTEST>
#   <?Target ?>
#   </GLWRTEST>
#   <IPV>
#   <?Target ?>
#   </IPV> 
#   <IKC>
#   <?Target ?>
#   </IKC>
#   <CLS>
#   <?Target ?>
#   </CLS>
#   </Approbation_Mark_Portal_Tendertext>  
#   <Footer_Tendertext_FP>
#   <?Target ?>
#   </Footer_Tendertext_FP>
#   <TenderText_FP>
#   <?Target ?>
#   </TenderText_FP>
#   </TendertextAttributes>
#   


###############################################################################
#
# TEST-data in STEP QA (18-01-2019), "de_DE" context
#
# COMF-1217  &  FP-910505016065
# FP-910400184612
#
###############################################################################
# 2018-01-18 run 1
# 
# FP-910505016065: 
# 
# STEP-msg in STEA
#   
# <TendertextAttributes>
#   <Introduction_Tendertext_FP/>
#   <TenderTextAttributes_FP/>
#   <Approbation_Mark_Portal_Tendertext>
#   <CE-MARK>ja</CE-MARK>
#   <ENEC-MARK>ENEC Zeichen</ENEC-MARK>
#   <FLAM-MARK>NO | nein</FLAM-MARK>
#   <GLWRTEST/>
#   <IPV>IP66 | Schutz gegen Eindringen von Staub, strahlwassergeschützt</IPV>
#   <IKC>IK08 | 5 J vandal-geprüft</IKC>
#   <CLS>Schutzklasse II</CLS>
#   </Approbation_Mark_Portal_Tendertext>
#   <Footer_Tendertext_FP>Signify, http://www.lighting.philips.de</Footer_Tendertext_FP>
#   <TenderText_FP/>
# </TendertextAttributes>
#   
# FP-910400184612
# 
# <TendertextAttributes>
#   <Introduction_Tendertext_FP/>
#   <TenderTextAttributes_FP/>
#   <Approbation_Mark_Portal_Tendertext>
#   <CE-MARK>ja</CE-MARK>
#   <ENEC-MARK>Nein</ENEC-MARK>
#   <FLAM-MARK/>
#   <GLWRTEST/>
#   <IPV>IP65 | Schutz gegen Eindringen von Staub, strahlwassergeschützt</IPV>
#   <IKC>IK08 | 5 J vandal-geprüft</IKC>
#   <CLS>Schutzklasse I</CLS>
#   </Approbation_Mark_Portal_Tendertext>
#   <Footer_Tendertext_FP>Signify, http://www.lighting.philips.de</Footer_Tendertext_FP>
#   <TenderText_FP>Lamp power: 2000 W</TenderText_FP>
# </TendertextAttributes>



