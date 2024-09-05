<?xml version="1.0" encoding="UTF-8"?>
<!-- This trasformation is applied to an RFS XML to get the detail RFS view under the queue table -->
<xsl:transform version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:include href="queueconfig.xsl"/>
	<xsl:include href="dictionary.xsl"/>
 	<!-- Choose the queue configuration with the specified queueID -->
	<!-- If a particular configuration element doesn't exist for the specifed queueID, -->
	<!-- the configuration element from the "Default" queueID will be used -->
	<xsl:param name="queueID">Default</xsl:param>
	
 	<xsl:template match='createRFS'>
 		<xsl:variable name="RFSView" select="$QueueConfig[@id=$queueID or @id='Default']/RFSView"/>
		<div id="oRFSView">
			<hr/>
			<table>
				<xsl:apply-templates select="($RFSView/CustomerInfo)[last()]/Row">
					<xsl:sort select="@order" data-type="number"/>
					<xsl:with-param name="RFS" select="."/>
				</xsl:apply-templates>
			</table>
			<table>
				<xsl:apply-templates select="($RFSView/OtherInfo)[last()]/Row">
					<xsl:sort select="@order" data-type="number"/>
					<xsl:with-param name="RFS" select="."/>
				</xsl:apply-templates>
			</table>
			<xsl:apply-templates select="($RFSView/Description)[last()]">
				<xsl:with-param name="RFS" select="."/>
			</xsl:apply-templates>
			<xsl:if test="//Status='Not Sent' and ($RFSView/EditButton)[last()][@show='true']">
				<div class="buttons">
					<input id="Edit" type="button" class="button" onclick="Queue.Edit()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
						<xsl:attribute name="value">
							<xsl:call-template name="String">
								<xsl:with-param name="Phrase" select="string('Edit')"/>
							</xsl:call-template>
						</xsl:attribute>
					</input>
					<input id="Save" type="button" class="button disabled" onclick="Queue.Save()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
						<xsl:attribute name="value">
							<xsl:call-template name="String">
								<xsl:with-param name="Phrase" select="string('Save')"/>
							</xsl:call-template>
						</xsl:attribute>
					</input>
				</div>
			</xsl:if>
		</div>
    </xsl:template>
    
    <xsl:template match="Description[@show='true']">
    	<xsl:param name="RFS"/>
    	<div class="Description">
			<h5>
				<xsl:call-template name="String">
					<xsl:with-param name="Phrase" select="string(@labeltext)"/>
				</xsl:call-template>
				<xsl:text>:</xsl:text>
			</h5>
			<textarea readonly="true" id="ProblemDescription">
				<xsl:value-of select="$RFS//ProblemDescription"/>
			</textarea>
		</div>
    </xsl:template>
    
    <xsl:template match="Row[@show='true']">
    	<xsl:param name="RFS"/>
    	<xsl:variable name="id" select="@id"/>
    	<tr>
			<xsl:apply-templates select="@labeltext" mode="LabelCell"/>
			<td class="edit">
				<input id="{$id}" type="text" value="{$RFS//node()[name()=$id]}" readonly="true" />
			</td>
		</tr>
    </xsl:template>
    
    <xsl:template match="Row[@id='Name'][@show='true']">
    	<xsl:param name="RFS"/>
    	<tr>
			<xsl:apply-templates select="@labeltext" mode="LabelCell"/>
			<td>
	    	   	<xsl:value-of select="$RFS//LastName"/>
				<xsl:text>, </xsl:text>
				<xsl:value-of select="$RFS//FirstName"/>
			</td>
		</tr>
    </xsl:template>
    
    <xsl:template match="Row[@id='Date'][@show='true']">
    	<xsl:param name="RFS"/>
    	<xsl:variable name="DateTime" select="$RFS//DateTime"/>
    	<xsl:variable name="DateTimeFormat" select="($QueueConfig[@id=$queueID or @id='Default']/DateTimeFormat)[last()]"/>
    	<tr>
			<xsl:apply-templates select="@labeltext" mode="LabelCell"/>
			<td class="- dtime {$DateTimeFormat/@Date} {$DateTimeFormat/@Time} {$DateTimeFormat}">
				<xsl:value-of select="number($DateTime)"/>
			</td>
		</tr>
    </xsl:template>
    
    <xsl:template match="Row[@id='Status'][@show='true']">
    	<xsl:param name="RFS"/>
    	<tr>
			<xsl:apply-templates select="@labeltext" mode="LabelCell"/>
			<td>
		    	<xsl:choose>
		    		<xsl:when test="$RFS//Status">
		    			<xsl:call-template name="String">
							<xsl:with-param name="Phrase" select="string($RFS//Status)"/>
						</xsl:call-template>
		    		</xsl:when>
		    		<xsl:otherwise>
		    			<xsl:call-template name="String">
							<xsl:with-param name="Phrase" select="string('Not Sent')"/>
						</xsl:call-template>
		    		</xsl:otherwise>
		    	</xsl:choose>
			</td>
		</tr>
    </xsl:template>
    
    <xsl:template match="Row[@id='RfsNumber'][@show='true']">
    	<xsl:param name="RFS"/>
    	<tr>
			<xsl:apply-templates select="@labeltext" mode="LabelCell"/>
			<td>
		    	<xsl:choose>
		    		<xsl:when test="$RFS//RfsNumber">
		    			<xsl:value-of select="$RFS//RfsNumber"/>
		    		</xsl:when>
		    		<xsl:otherwise>
		    			&#160;
		    		</xsl:otherwise>
		    	</xsl:choose>
			</td>
		</tr>
    </xsl:template>
		
    <xsl:template match="Row[@id='SystemID'][@show='true']">
    	<xsl:param name="RFS"/>
    	<tr>
				<xsl:choose>
					<xsl:when test="$RFS//SystemID=''">
						<td class="label_invalid">
							<xsl:call-template name="String">
								<xsl:with-param name="Phrase" select="@labeltext"/>
							</xsl:call-template>
							<xsl:text>:</xsl:text>
						</td>
					</xsl:when>
					<xsl:otherwise>
						<td class="label">
							<xsl:call-template name="String">
								<xsl:with-param name="Phrase" select="@labeltext"/>
							</xsl:call-template>
							<xsl:text>:</xsl:text>
						</td>
					</xsl:otherwise>
				</xsl:choose>
				<td><xsl:value-of select="$RFS//SystemID"/></td>
			</tr>
    </xsl:template>
    
    <xsl:template match="@*" mode="LabelCell">
		<td class="label">
			<xsl:call-template name="String">
				<xsl:with-param name="Phrase" select="string(.)"/>
			</xsl:call-template>
			<xsl:text>:</xsl:text>
		</td>
    </xsl:template>
</xsl:transform>