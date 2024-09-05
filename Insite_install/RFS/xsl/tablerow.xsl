<?xml version="1.0" encoding="UTF-8"?>
<!-- This trasformation is applied to an RFS XML to get table row (tr) HTML -->
<xsl:transform version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	xmlns:user="http://mycompany.com/mynamespace"
	exclude-result-prefixes="msxsl user">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"></xsl:output>
	
	<xsl:include href="queueconfig.xsl"/>
	<xsl:include href="dictionary.xsl"/>
	<!-- Choose the queue configuration with the specified queueID -->
	<!-- If a particular configuration element doesn't exist for the specifed queueID, -->
	<!-- the configuration element from the "Default" queueID will be used -->
	<xsl:param name="queueID">Default</xsl:param>
	
 	<xsl:template match='createRFS'>
 		<xsl:variable name="FileName" select="//FileName"/>
 		<xsl:variable name="SystemID" select="//SystemID"/>
		<xsl:variable name="isInvalid">
			<xsl:choose>
				<xsl:when test="$SystemID!=''"><xsl:value-of select="string('')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="string('invalid')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<tr id="{$FileName}" class="{$isInvalid}" onclick="Queue.ViewRFS('{$FileName}')" >
			<td class="cbox">
				<input type="checkbox" class="checkbox" onclick="Queue.OnCheckClick(this,'{$FileName}')"/>
			</td>
			<xsl:apply-templates select="($QueueConfig[@id=$queueID or @id='Default']/Table)[last()]/Column">
				<xsl:sort select="@order" data-type="number"/>
				<xsl:with-param name="RFS" select="."/>
			</xsl:apply-templates>
		</tr>
    </xsl:template>

    <xsl:template match="Column[@show='true']">
		<xsl:param name="RFS"/>
		<xsl:variable name="id" select="@id"/>
		<xsl:variable name="value" select="$RFS//node()[name()=$id]"/>
		<td class="{$id}">
			<xsl:choose>
				<!-- Status values have to be translated -->
				<xsl:when test="$id='Status'">
					<xsl:call-template name="String">
						<xsl:with-param name="Phrase" select="string($value)"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$value"/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
    </xsl:template>
    
    <xsl:template match="Column[@id='Date'][@show='true']">
		<xsl:param name="RFS"/>
		<xsl:variable name="DateTime" select="$RFS//DateTime"/>
		<xsl:variable name="DateTimeFormat" select="($QueueConfig[@id=$queueID or @id='Default']/DateTimeFormat)[last()]"/>
		<td class="{@id} dtime {$DateTimeFormat/@Date} {$DateTimeFormat/@Time} {$DateTimeFormat}">
			<xsl:value-of select="number($DateTime)"/>
		</td>
		<!-- This one will be used for sorting -->
		<span class="DateTime" style="display: none;"><xsl:value-of select="$DateTime"/></span>
    </xsl:template>
    
    <xsl:template match="Column[@id='Description'][@show='true']">
    	<xsl:param name="RFS"/>
		<td class="{@id} trim {number(@maxcharacters)}">
			<xsl:value-of select="string($RFS//ProblemDescription)"/>
		</td>
    </xsl:template>
</xsl:transform>