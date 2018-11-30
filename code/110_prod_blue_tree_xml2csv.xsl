<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
  <xsl:output method="text" indent="no"/>
   
  <!-- create headers and call tree-nodes to convert into lines: -->
  <xsl:template match="/">
    <xsl:text>FP_ID,Name,CF_ID</xsl:text>
    <xsl:apply-templates select="//Product[@UserTypeID='Final Product']"/>
  </xsl:template>

  <!-- create lines with tree-node data: -->
  <xsl:template match="Product">
"<xsl:value-of select="@ID" />","<xsl:value-of select="fn:replace(Name, '&quot;','')" />","<xsl:value-of select="ProductCrossReference[@Type='Primary CF']/@ProductID" />"<xsl:text>&#xD;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
