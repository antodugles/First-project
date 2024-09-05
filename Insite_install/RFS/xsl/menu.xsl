<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes" />
	<xsl:template match="/configRFS">
	<xsl:variable name="lang">
		<xsl:choose>
			<xsl:when test="settings/lang"><xsl:value-of select="settings/lang"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="document('../xml/dictionary.xml')/dictionary/lang"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="strings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($lang)]/string" />
	<xsl:for-each select="Menu">
		<ul class="menu">
			<li><a class="rfs" target="contentframe" href="rfs.html"><xsl:value-of select="$strings[@phrase='RFS']" /></a></li>
			<xsl:if test="Queue[@show='true']">
				<li><a target="contentframe" href="queue.html"><xsl:value-of select="$strings[@phrase='Queue']" /></a></li>
			</xsl:if>
			<li>
				<a target="contentframe">
					<xsl:choose>
						<xsl:when test="MachineQueue[@show='true']">
							<xsl:attribute name="href">
								<xsl:value-of select="string('queue.html?id=Machine')"/>
							</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="class">
								<xsl:value-of select="string('disabled')"/>
							</xsl:attribute>
						</xsl:otherwise>	
					</xsl:choose>	
					<xsl:value-of select="$strings[@phrase='Machine']"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="$strings[@phrase='Queue']"/>
				</a></li>
			<xsl:if test="Users[@show='true']">
				<li><a target="contentframe" href="users.html"><xsl:value-of select="$strings[@phrase='Users']" /></a></li>
			</xsl:if>
		</ul>
		<hr id="oBaseLine" />
	</xsl:for-each>
	</xsl:template>
</xsl:transform>