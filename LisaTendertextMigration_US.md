---
title: "TenderText_UserStory"
author: "BHE"
date: "2019 M01 10"
output: html_document
---

Note: text is in JIRA markdown !!



PO: Trea Vos
 Requester: Mike Bishoff
 Priority: medium
 Application(s): STEP
 Change request: -
h2. User need
h2. Dependencies
h2. Description
h3. Analysis

Germany has 1000+ already created tendertexts from LiSA, in similar format as the Generated Tendertexts will be. Define plan to migrate these.
 _Todo_: design migration plan + define rules to prevent migrated content to be overwritten with STEA generated Tender texts.

Analysis BHE:
 1. easy to split the Lisa texts
 2. provided for the 12NC (FP), should be migrated to the CF (possible) or directly to the FP.

Lisa TenderText-field mapping
||LISA field||STEP field||FP xUCDM||Mapping-rule||
|CD_ID|NA|NA|ignore|
|12NC|FP-ID|ObjectID| |
|CommercialDesignation| |default in xUCDM msg|ignore|
|TextBrief|TenderTextAttributes_FP|TenderTextAttributes_FP|needs to be split and mapped to STEP-attributes (based on values in TenderText-lov)|
|BasicText|Introduction_Tendertext_FP|Introduction_Tendertext_FP| |
|Certificates| |Approbation_Mark_Portal_Tendertext
 (check mapping in msg)|needs to be split and mapped to STEP-attributes |
|ApprobationMarks (Prüfzeichen)| |Approbation_Mark_Portal_Tendertext
 (check mapping in msg)|ignore|

Findings
 # The Lisa TT spreadsheet contains data for 140 Commercial Families and a total of 2839 Final Products.
 # The BasicText (Introduction_Tendertext_FP) is often unique for the FP, so cannot be migrated to the CF-level, but must be migrated to the FP.

 # 
 ## the BasicText can be migrated to 24 families,
 ## the BasicText must be migrated to 2864 products,
 # the are 32 unique approbation marks (including one empty value and a "NA' value)
 _*Note:*_ these are values that must be mapped to the STEP attribute. So these differ from the approbation marks assets that are also linked to products. Because different relations are used, its possible (and expected) that the assets and attribute for the approbation marks will differ!!!
 ## 4 types of approbation marks can be extracted from the LISA TT and automatically migrated. These are
 ### ENEC, IK, IP, SK,
 ## 92 approbation marks are common to all FP's in a CF and can be migrated to the CF,
 ## 1630 approbation marks must be migrated to the FP,
 # the product attributes cannot be automatically migrated unless a mapping is made between the values available in LISA TT and the values available in the STEP LOV for the STEP Tendertext attributes.

h3. Changes
 # Map the file "LisaTT_introductionText_per_CF.csv" to commercial families and the CF BasicText  attribute,
 # Map the file "LisaTT_introductionText_per_FP.csv" to final products and the FP BasicText  attribute,
 # Map the file "LisaTT_approbation_marks_per_CF.csv" to commercial families and the CF Approbation Mark attribute,
 # Map the file "LisaTT_approbation_marks_per_FP.csv" to final products and the FP Approbation Mark attribute,
 # Map the file "" to final products and the FP TT Attributes attribute,

h2. Acceptance criteria