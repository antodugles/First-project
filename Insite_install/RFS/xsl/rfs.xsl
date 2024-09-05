<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes" />
	<xsl:template match="/configRFS">
	<xsl:variable name="xmlPath" select="translate(settings/XMLpath,'\\','/')" />
	<xsl:variable name="MRFS" select="Menu/Queue/@show" />
	<xsl:variable name="datalang" select="settings/datalang" />
	<xsl:variable name="usetooltip" select="page/HELP/UseTooltip" />
	<xsl:variable name="useConnectToGE" select="SendOptions/ConnectToGE/@enable" />
	<xsl:variable name="forcepollperiod" select="SendOptions/ConnectToGE/ForcePollPeriod" />
	<xsl:variable name="forcepollduration" select="SendOptions/ConnectToGE/ForcePollDuration" />
	<xsl:variable name="lang">
		<xsl:choose>
			<xsl:when test="settings/lang"><xsl:value-of select="settings/lang"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="document('../xml/dictionary.xml')/dictionary/lang"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="datastrings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($datalang)]/string" />
	<xsl:variable name="strings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($lang)]/string" />
	<xsl:for-each select="page">
		<div id="root">
			<xsl:if test="HELP[@show='true']">
				<div id="tooltip">
					<iframe src="javascript:false" scrolling="no" frameborder="0"></iframe>
					<div>
						<p class="title">Some help title</p>
						<p class="text">This is a contextual help message.</p>
					</div>
				</div>
			</xsl:if>
			<form id="RFS">
				<script type="text/javascript">
					RFS.setTitle("<xsl:value-of select="$strings[@phrase='RFS']" />");
					RFS.xmlPath = FileIO.normalizePath("<xsl:value-of select="$xmlPath" />");
					RFS.mrfs = <xsl:value-of select="$MRFS" />;
					RFS.notSent = "<xsl:value-of select="$datastrings[@phrase='Not Sent']" />";
					RFS.useTooltip = <xsl:value-of select="$usetooltip" />;
					APICalls.forcePollPeriod = <xsl:value-of select="$forcepollperiod" />;
					APICalls.forcePollDuration = <xsl:value-of select="$forcepollduration" />;
					APICalls.useConnectToGE = <xsl:value-of select="$useConnectToGE" />;
				</script>
				<xsl:for-each select="CDI">
					<div id="CDI">
						<span class="title"><xsl:value-of select="$strings[@phrase='Contact Information']" /></span>
						<div>
							<p><span><em>*</em><xsl:value-of select="$strings[@phrase='Last']" />:</span><input name="Last" type="text" maxlength="25" onchange="RFS.capitalize(this); RFS.validate(this,/^[A-Z-.]{{1,25}}$/);" onkeyup="RFS.capitalize(this); if (this.value.length > 0) RFS.validate(this,/^[A-Z-.]{{1,25}}$/); RFS.suggest();" onkeydown="RFS.hideSuggest(event.keyCode);" onfocus="RFS.suggest(); RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Last']}','{$strings[@phrase='helpLast']}');" onblur="if (!RFS.suggestHover) RFS.hideSuggest();" onmouseover="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Last']}','{$strings[@phrase='helpLast']}', this);" /></p>
							<p><span><em>*</em><xsl:value-of select="$strings[@phrase='First']" />:</span><input name="First" type="text" maxlength="25" onchange="RFS.capitalize(this); RFS.validate(this,/^[A-Z-.]{{1,25}}$/);" onkeyup="RFS.capitalize(this); if (this.value.length > 0) RFS.validate(this,/^[A-Z-.]{{1,25}}$/);" onfocus="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='First']}','{$strings[@phrase='helpFirst']}');" onmouseover="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='First']}','{$strings[@phrase='helpFirst']}', this);" /></p>
							<p><span><em>*</em><xsl:value-of select="$strings[@phrase='Phone']" />:</span><input name="Phone" type="text" maxlength="25" onchange="RFS.validate(this,/^[0-9-*#.]{{1,25}}$/);" onkeyup="if (this.value.length > 0) RFS.validate(this,/^[0-9-*#\.]{{1,25}}$/);" onfocus="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Phone']}','{$strings[@phrase='helpPhone']}');" onmouseover="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Phone']}','{$strings[@phrase='helpPhone']}', this);" /></p>
							<xsl:if test="Ext[@show='true']"><p><span><xsl:value-of select="$strings[@phrase='Ext.']" />:</span><input name="Ext" type="text" maxlength="25" onchange="RFS.validate(this,/^[0-9-*#.]{{0,25}}$/);" onkeyup="if (this.value.length > 0) RFS.validate(this,/^[0-9-*#]{{0,25}}$/);" onfocus="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Extension']}','{$strings[@phrase='helpExt']}');" onmouseover="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='Extension']}','{$strings[@phrase='helpExt']}', this);" /></p></xsl:if>
							<xsl:if test="Email[@show='true']"><p><span><xsl:value-of select="$strings[@phrase='E-mail']" />:</span><input name="Email" type="text" maxlength="50" onchange="RFS.validate(this,/^.{{0,50}}$/);" onkeyup="if (this.value.length > 0) RFS.validate(this,/^.{{0,50}}$/);" onfocus="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='E-mail']}','{$strings[@phrase='helpEmail']}');" onmouseover="RFS.help('{$strings[@phrase='Contact Information']} &#187; {$strings[@phrase='E-mail']}','{$strings[@phrase='helpEmail']}', this);" /></p></xsl:if>
							<xsl:if test="SystemID[@show='true']"><p><span><xsl:value-of select="$strings[@phrase='System ID']" />: </span><input id="SystemID" name="SystemID" type="text" class="readonly" readonly="readonly" maxlength="50" onfocus="RFS.help('{$strings[@phrase='System ID']}','{$strings[@phrase='helpSystemID']}');" onmouseover="RFS.help('{$strings[@phrase='System ID']}','{$strings[@phrase='helpSystemID']}', this);" /></p></xsl:if>
							<xsl:if test="OtherSystemID[@show='true']"><p><span><xsl:value-of select="$strings[@phrase='Other System ID']" />: </span><input id="OtherSystemID" name="OtherSystemID" type="text" maxlength="50" onchange="RFS.capitalize(this); RFS.validate(this,/^.{{0,50}}$/);" onkeyup="RFS.capitalize(this); if (this.value.length > 0) RFS.validate(this,/^.{{0,50}}$/);" onfocus="RFS.help('{$strings[@phrase='Other System ID']}','{$strings[@phrase='helpOtherSystemID']}');" onmouseover="RFS.help('{$strings[@phrase='Other System ID']}','{$strings[@phrase='helpOtherSystemID']}', this);" /></p></xsl:if>
							<ul id="suggest" onmouseover="RFS.suggestHover = true;" onmouseout="RFS.suggestHover = false;"></ul>
						</div>
					</div>
				</xsl:for-each>
				<xsl:for-each select="SAI[@show='true']">
					<div id="SAI">
						<span class="title"><em>*</em><xsl:value-of select="$strings[@phrase='Problem Type']" /></span>
						<div>
							<label onclick="RFS.toggleCallmode(this);" onfocus="RFS.help('{$strings[@phrase='Problem Type']} &#187; {$strings[@phrase='Service']}','{$strings[@phrase='helpService']}', this);" onmouseover="RFS.help('{$strings[@phrase='Problem Type']} &#187; {$strings[@phrase='Service']}','{$strings[@phrase='helpService']}', this);" for="CallmodeService"><input id="CallmodeService" name="Callmode" type="radio" class="radio" value="{$datastrings[@phrase='System']}" /> <xsl:value-of select="$strings[@phrase='Service']" /></label>
							<label onclick="RFS.toggleCallmode(this);" onfocus="RFS.help('{$strings[@phrase='Problem Type']} &#187; {$strings[@phrase='Applications']}','{$strings[@phrase='helpApplications']}', this);" onmouseover="RFS.help('{$strings[@phrase='Problem Type']} &#187; {$strings[@phrase='Applications']}','{$strings[@phrase='helpApplications']}', this);" for="CallmodeApplications"><input id="CallmodeApplications" name="Callmode" type="radio" class="radio" value="{$datastrings[@phrase='Applications']}" /> <xsl:value-of select="$strings[@phrase='Applications']" /></label>
						</div>
					</div>
				</xsl:for-each>
				<xsl:for-each select="PTI[@show='true']">
					<xsl:variable name="PTIlangStrings" select="strings[lang('en-US') or lang($lang)][last()]"/>
					<xsl:variable name="PTIdatalangStrings" select="strings[lang('en-US') or lang($datalang)][last()]"/>
					<div id="PTI">
						<span class="title"><em>*</em><xsl:value-of select="$strings[@phrase='Problem Area']" /></span>
						<div>
							<xsl:choose>
								<xsl:when test="../SAI[@show='true']">
									<div><p class="left"><span><xsl:value-of select="$strings[@phrase='Service']" /></span><select name="CustomerIssueService" onchange="RFS.validateList(this); RFS.listHelp(this); RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Service']}');" onmouseover="RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Service']}');" multiple="multiple">
										<xsl:for-each select="$PTIlangStrings/ServiceList/item">
											<xsl:variable name="i" select="position()" />
											<option value="{$PTIdatalangStrings/ServiceList/item[$i]/@value}" onfocus="RFS.help('{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Service']} &#187; {@value}','{.}');"><xsl:value-of select="@value" /></option>
										</xsl:for-each>
									</select></p></div>
									<div><p class="right"><span><xsl:value-of select="$strings[@phrase='Applications']" /></span><select name="CustomerIssueApplications" onchange="RFS.validateList(this); RFS.listHelp(this); RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Applications']}');" onmouseover="RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Applications']}');" multiple="multiple">
										<xsl:for-each select="$PTIlangStrings/ApplicationsList/item">
											<xsl:variable name="i" select="position()" />
											<option value="{$PTIdatalangStrings/ApplicationsList/item[$i]/@value}" onfocus="RFS.help('{$strings[@phrase='Problem Area']} &#187; {$strings[@phrase='Applications']} &#187; {@value}','{.}');"><xsl:value-of select="@value" /></option>
										</xsl:for-each>
									</select></p></div>
								</xsl:when>
								<xsl:when test="../PTI[@show='true']">
									<div class="middle"><p><select name="CustomerIssueGeneric" onchange="RFS.validateList(this); RFS.listHelp(this); RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']}');" onmouseover="RFS.helpTooltip(false,false,this,'{$strings[@phrase='Problem Area']}');" multiple="multiple">
										<xsl:for-each select="$PTIlangStrings/GenericList/item">
											<xsl:variable name="i" select="position()" />
											<option value="{$PTIdatalangStrings/GenericList/item[$i]/@value}" onfocus="RFS.help('{$strings[@phrase='Problem Area']} &#187; {@value}','{.}');"><xsl:value-of select="@value" /></option>
										</xsl:for-each>
									</select></p></div>
								</xsl:when>
							</xsl:choose>
						</div>
					</div>
				</xsl:for-each>
				<xsl:for-each select="PDI">
					<div id="PDI">
						<span class="title"><em>*</em><xsl:value-of select="$strings[@phrase='Problem Description']" /></span>
						<div>
							<textarea name="CustomerDescription" onchange="RFS.maxlength(this,980); RFS.validate(this,/^[\s\S]{{1,980}}$/);" onkeydown="RFS.maxlength(this,980);" onkeyup="RFS.validate(this,/^[\s\S]{{1,980}}$/); RFS.maxlength(this,980);" onkeypress="RFS.maxlength(this,980);" onfocus="RFS.help('{$strings[@phrase='Problem Description']}','{$strings[@phrase='helpDescription']}');" onmouseover="RFS.help('{$strings[@phrase='Problem Description']}','{$strings[@phrase='helpDescription']}', this);"></textarea>
							<div>
								<p class="limit"><input id="CustomerDescriptionLimit" name="CustomerDescriptionLimit" type="text" value="980" class="readonly" readonly="readonly" /> <span class="lower"><xsl:value-of select="$strings[@phrase='Characters Left']" /></span></p>
								<xsl:for-each select="DateTime[@show='true']">
									<p><span class="systemid"><xsl:value-of select="$strings[@phrase='Date/Time of Problem']" />: </span><input id="CustomerDescriptionDateTime" name="CustomerDescriptionDateTime" type="text" maxlength="20" onchange="RFS.validate(this,/^.{{0,20}}$/);" onkeyup="if (this.value.length > 0) RFS.validate(this,/^.{{0,20}}$/);" onfocus="RFS.help('{$strings[@phrase='Problem Description']}','{$strings[@phrase='helpDateTime']}');" onmouseover="RFS.help('{$strings[@phrase='Date/Time of Problem']}','{$strings[@phrase='helpDateTime']}', this);" /><input class="button" type="button" value="{$strings[@phrase='Now']}" onclick="RFS.$('CustomerDescriptionDateTime').value = RFS.getDateTime();" onmousedown="RFS.buttonDown(this);" onmouseover="RFS.buttonOver(this); RFS.help('{$strings[@phrase='Now']}','{$strings[@phrase='helpDateTimeNow']}', this);" onmouseup="RFS.buttonUp(this);" onmouseout="RFS.buttonOut(this);" onfocus="RFS.help('{$strings[@phrase='Now']}','{$strings[@phrase='helpDateTimeNow']}');" /></p>
								</xsl:for-each>
							</div>
						</div>
					</div>
				</xsl:for-each>
				<xsl:for-each select="SCI">
					<div id="SCI">
						<div>
							<input id="Send" name="Send" class="button disabled" type="button" value="{$strings[@phrase='Send']}" onmousedown="RFS.buttonDown(this);" onmouseover="RFS.buttonOver(this); RFS.help('{$strings[@phrase='Send']}','{$strings[@phrase='helpSend']}', this);" onmouseup="RFS.buttonUp(this);" onmouseout="RFS.buttonOut(this);" onfocus="RFS.help('{$strings[@phrase='Send']}','{$strings[@phrase='helpSend']}');" onclick="if (RFS.validateAll()) RFS.process();" />
							<input id="Cancel" name="Cancel" class="button" type="button" value="{$strings[@phrase='Cancel']}" onmousedown="RFS.buttonDown(this);" onmouseover="RFS.buttonOver(this); RFS.help('{$strings[@phrase='Cancel']}','{$strings[@phrase='helpCancel']}', this);" onmouseup="RFS.buttonUp(this);" onmouseout="RFS.buttonOut(this);" onfocus="RFS.help('{$strings[@phrase='Cancel']}','{$strings[@phrase='helpCancel']}');" onclick="RFS.close();" />
						</div>
					</div>
				</xsl:for-each>
				<xsl:if test="HELP[@show='true']">
					<xsl:choose>
						<xsl:when test="$usetooltip!='true'">
							<xsl:for-each select="HELP">
								<div id="HELP">
									<span class="title"><xsl:value-of select="$strings[@phrase='Help']" /></span>
									<div>
										<div id="ContextHelp" class="readonly">
											<p class="title"></p>
											<p></p>
										</div>
										<p class="note"><em>*</em><xsl:value-of select="$strings[@phrase='Required Fields']" /></p>
									</div>
								</div>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="HELP">
								<div id="HELP">
									<div>
										<p class="note"><em>*</em><xsl:value-of select="$strings[@phrase='Required Fields']" /></p>
									</div>
								</div>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</form>
			<xsl:if test="QSTA[@show='true']">
				<div id="statusbar">
					<iframe src="javascript:false" scrolling="no" frameborder="0"></iframe>
					<div>
						<p id="connectionstatus" class="left"><span class="green"><xsl:value-of select="$strings[@phrase='Connected']" /></span></p>
						<p id="queuestatus"></p>
						<p id="actionstatus" class="right"><xsl:value-of select="$strings[@phrase='Status']" /></p>
						<input type="button" onclick="StatusBar.hide();" value="X"/>
					</div>
				</div>
			</xsl:if>
		</div>
	</xsl:for-each>
	</xsl:template>
</xsl:transform>