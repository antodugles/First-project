<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes" />
	
	<xsl:variable name="QueueConfig" select="document('../xml/rfs_config.xml')/configRFS/Queue"/>
</xsl:transform>