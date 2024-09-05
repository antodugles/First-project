<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"></xsl:output>
	
	<xsl:variable name="sort1">Status</xsl:variable>
	<xsl:variable name="sort1type">text</xsl:variable>
	<xsl:variable name="sort1order">ascending</xsl:variable>
	<xsl:variable name="sort2">DateTime</xsl:variable>
	<xsl:variable name="sort2type">number</xsl:variable>
	<xsl:variable name="sort2order">descending</xsl:variable>
 	<xsl:template match='tbody'>
 		<xsl:copy>
 			<xsl:apply-templates select="./tr">
 				<xsl:sort select="./*[contains(@class,$sort1)]" data-type="{$sort1type}" order="{$sort1order}"/>
 				<xsl:sort select="./*[contains(@class,$sort2)]" data-type="{$sort2type}" order="{$sort2order}"/>
 			</xsl:apply-templates>
 		</xsl:copy>
    </xsl:template>
    <xsl:template match="tr">
		<xsl:copy-of select="."/>
    </xsl:template>
</xsl:transform>