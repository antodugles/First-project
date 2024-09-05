<?xml version="1.0" encoding="UTF-8"?>
<!-- This trasformation is applied to a Machine RFS XML to create a standard RFS XML -->
<xsl:transform version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:variable name="QSAConfig" select="document('../Questra/GeHealthcare/Agent/etc/qsaconfig.xml')/ServiceAgent"/>
 	<xsl:variable name="Users" select="document('../RFS/xml/users.xml')/usersRFS"/>
 	<xsl:template match='MachineRFS'>
 		<xsl:variable name="SystemID" select="$QSAConfig/ContactInfo/ServiceAgentProfile/SerialNumber"/>
 		<createRFS machine='true'>
 			<SystemID>
 				<xsl:if test="not($SystemID='UNKNOWN' or $SystemID='Unknown')">
 					<xsl:value-of select="$SystemID"/>
 				</xsl:if>
 			</SystemID>
 			<OtherSystemID/>
 			<ProblemType>System</ProblemType>
 			<ProblemArea>MachineRFS</ProblemArea>
 			<xsl:apply-templates select="$Users/contact[@default]"/>
		 	<ExamNumber/>
			<SeriesNumber/>
			<ImageNumber/>
			<ProblemDescription>
       			<xsl:text>ProblemType=System;ProblemArea=MachineRFS;</xsl:text>
				<xsl:text>Sub System: </xsl:text><xsl:value-of select="SubSystem"/>
				<xsl:text>&#10;Error Code: </xsl:text><xsl:value-of select="ErrorCode"/>
				<xsl:text>&#10;Error Description: </xsl:text><xsl:value-of select="ErrorDesc"/>
				<xsl:text>&#10;Date/Time: </xsl:text><xsl:value-of select="DateTime"/>
			</ProblemDescription>
			<RequestSource>ContactGE</RequestSource>
			<Status>Not Sent</Status>
 		</createRFS>	
    </xsl:template>
    
    <xsl:template match="contact[@default]">
		<ContactDetail>
			<FirstName>
				<xsl:value-of select="First"/>
			</FirstName>
			<LastName>
				<xsl:value-of select="Last"/>
			</LastName>
			<ContactPhone>
				<xsl:value-of select="Phone"/>
				<xsl:if test="Ext">
					<xsl:text>;x</xsl:text>
					<xsl:value-of select="Ext"/>
				</xsl:if>
			</ContactPhone>
			<ContactEmail>
				<xsl:if test="Email">
					<xsl:value-of select="Email"/>
				</xsl:if>
			</ContactEmail>
		</ContactDetail>
    </xsl:template>
</xsl:transform>