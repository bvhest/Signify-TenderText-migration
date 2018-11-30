REM ##!/bin/bash
REM #
REM # Signify STEP product database
REM #
REM # script om datamodel op te zetten en data te laden in de Neo4j database
REM # create neo4j database with Signify Product tree and mandatory attributes from csv-data:
REM #
REM # BvH, 2018-11-15
REM #

REM # product blue tree to category-nodes, including category links :
REM java -Xmx4096m -cp C:\java\SaxonHE9-8-0-11J\saxon9he.jar net.sf.saxon.Transform -t -s:../data/prod_blue_tree.xml -xsl:110_prod_blue_tree_xml2csv.xsl -o:../data/prod_blue_tree.csv

REM # extract LOV-values :
REM java -Xmx4096m -cp C:\java\SaxonHE9-8-0-11J\saxon9he.jar net.sf.saxon.Transform -t -s:../data/TenderTextAttribute_de_DE.xml -xsl:120_tt_attribute_lov.xsl -o:../data/tt_attribute_lov.csv

REM # extract GERMAN atribute-values :
java -Xmx4096m -cp C:\java\SaxonHE9-8-0-11J\saxon9he.jar net.sf.saxon.Transform -t -s:../data/Attributes_de_DE.xml -xsl:130_de_DE_attribute_values.xsl -o:../data/attributes_de_DE.csv
