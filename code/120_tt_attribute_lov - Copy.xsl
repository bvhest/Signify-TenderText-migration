<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
  <xsl:output method="text" indent="no"/>
   
  <!-- create headers and call tree-nodes to convert into lines: -->
  <xsl:template match="/">
    <xsl:apply-templates select="STEP-ProductInformation/ListsOfValues/ListOfValue[@ID='TenderText-lov']"/>
  </xsl:template>

  <xsl:template match="ListOfValue">
    <xsl:text>ID,Value</xsl:text>
    <xsl:apply-templates select="Value"/>
  </xsl:template>

  <!-- create lines with tree-node data: -->
  <xsl:template match="Value">
"<xsl:value-of select="@ID" />","<xsl:value-of select="fn:replace(text(), '&quot;','')" />"<xsl:text>&#xD;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
