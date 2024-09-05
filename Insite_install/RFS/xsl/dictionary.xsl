<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes" />
	
	<xsl:variable name="lang">
		<xsl:value-of select="document('../xml/rfs_config.xml')/configRFS/settings/lang"/>
		<xsl:if test="not(document('../xml/rfs_config.xml')/configRFS/settings/lang)">
			<xsl:value-of select="document('../xml/dictionary.xml')/dictionary/lang"/>
		</xsl:if>
	</xsl:variable>
	<xsl:variable name="datalang" select="settings/datalang" />
	<xsl:variable name="strings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($lang)]/string"/>
	<xsl:variable name="datastrings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($datalang)]/string" />

	<xsl:template name="String">
		<xsl:param name="Phrase"/>
		<xsl:value-of select="$strings[@phrase=$Phrase]"/>
		<xsl:if test="not($strings[@phrase=$Phrase])">
			<xsl:value-of select="$Phrase"/>
		</xsl:if>
	</xsl:template>
</xsl:transform>