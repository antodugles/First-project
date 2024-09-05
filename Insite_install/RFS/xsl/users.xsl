<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="UTF-8" indent="yes" />
	<xsl:template match="/configRFS">
	<xsl:variable name="datalang" select="settings/datalang" />
	<xsl:variable name="lang">
		<xsl:choose>
			<xsl:when test="settings/lang"><xsl:value-of select="settings/lang"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="document('../xml/dictionary.xml')/dictionary/lang"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="datastrings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($datalang)]/string" />
	<xsl:variable name="strings" select="document('../xml/dictionary.xml')/dictionary/strings[lang($lang)]/string" />
	<xsl:variable name="users" select="document('../xml/users.xml')/usersRFS/contact" />
	<xsl:variable name="recentusers" select="document('../xml/users_recent.xml')/recentRFS/contact" />
	<xsl:variable name="showExt" select="page/CDI/Ext[@show='true']" />
	<xsl:variable name="showEmail" select="page/CDI/Email[@show='true']" />
	<xsl:variable name="machineRFS" select="Menu/MachineQueue[@show='true']|settings/machineRFS[text()='true']"/>
	<xsl:variable name="colspan">
		<xsl:choose>
			<xsl:when test="not($showExt)">
				<xsl:choose>
					<xsl:when test="$showEmail">6</xsl:when>
					<xsl:otherwise>5</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="not($showEmail)">6</xsl:when>
			<xsl:otherwise>7</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="widthName">
		<xsl:choose>
			<xsl:when test="not($showExt)">
				<xsl:choose>
					<xsl:when test="$showEmail">twenty</xsl:when>
					<xsl:otherwise>thirtyfive</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="not($showEmail)">thirty</xsl:when>
			<xsl:otherwise>twenty</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="widthPhone">twenty</xsl:variable>
	<xsl:variable name="widthExt">ten</xsl:variable>
	<xsl:variable name="widthEmail">
		<xsl:choose>
			<xsl:when test="not($showExt)">thirty</xsl:when>
			<xsl:otherwise>twenty</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:for-each select="page">
		<div id="root">
			<form><script type="text/javascript">
				Users.removeString = "<xsl:value-of select="$strings[@phrase='RemoveSelectedUsersMsg']" />";
				Users.editString = "<xsl:value-of select="$strings[@phrase='Edit']" />";
				Users.cancelString = "<xsl:value-of select="$strings[@phrase='Cancel']" />";
				Users.saveString = "<xsl:value-of select="$strings[@phrase='Save']" />";
				<xsl:if test="$machineRFS">
					Users.machineRFS = true;
				</xsl:if>
			</script></form>
			<div id="users_table">
				<table cellspacing="0" cellpadding="0">
					<tbody>
						<tr class="header title">
							<th colspan="{$colspan}">
								<xsl:value-of select="$strings[@phrase='Permanent Users']" />
							</th>
						</tr>
						<tr class="header">
							<th class="cbox"><input id="users_checkbox" type="checkbox" onclick="Users.checkAll(this);"/></th>
							<th><xsl:value-of select="$strings[@phrase='Last']" /></th>
							<th><xsl:value-of select="$strings[@phrase='First']" /></th>
							<th><xsl:value-of select="$strings[@phrase='Phone']" /></th>
							<xsl:if test="$showExt"><th><xsl:value-of select="$strings[@phrase='Ext.']" /></th></xsl:if>
							<xsl:if test="$showEmail"><th><xsl:value-of select="$strings[@phrase='E-mail']" /></th></xsl:if>
							<th>&#160;</th>
						</tr>
						<xsl:for-each select="$users">
							<xsl:variable name="id">
								<xsl:choose>
									<xsl:when test="@default">
										<xsl:value-of select="string('default')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat('users',position())" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<tr id="{$id}">
								<xsl:attribute name="class">
									<xsl:choose>
										<xsl:when test="position() mod 2 = 1"></xsl:when>
										<xsl:otherwise>altrow</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<xsl:if test="$id='default'">
									<xsl:attribute name="title">
										<xsl:value-of select="$strings[@phrase='Default']"/>
									</xsl:attribute>
								</xsl:if>
								<td class="cbox"><input type="checkbox" onclick="Users.validateCheck(this);" /></td>
								<td class="last {$widthName}"><xsl:value-of select="./Last" /></td>
								<td class="first {$widthName}"><xsl:value-of select="./First" /></td>
								<td class="phone {$widthPhone}"><xsl:value-of select="./Phone" /></td>
								<xsl:if test="$showExt"><td class="ext {$widthExt}"><xsl:value-of select="./Ext" /></td></xsl:if>
								<xsl:if test="$showEmail"><td class="email {$widthEmail}"><xsl:value-of select="./Email" /></td></xsl:if>
								<td class="actions"><a href="javascript:Users.editRow('{$id}');" class="edit" title="{$strings[@phrase='Edit']}"><xsl:value-of select="$strings[@phrase='Edit']" /></a></td>
							</tr>
						</xsl:for-each>
						<tr class="actions">
							<td colspan="{$colspan}">
								<div>
									<a href="javascript:Users.toggleAddUserForm();"><xsl:value-of select="$strings[@phrase='Add User']" /></a>
								</div>
								<div>
									<a href="javascript:Users.removeUsers('users_table');"><xsl:value-of select="$strings[@phrase='Remove Selected Users']" /></a>
								</div>
								<div>
									<a>
										<xsl:choose>
											<xsl:when test="$machineRFS">
												<xsl:attribute name="href">javascript:Users.setDefaultUser('users_table');</xsl:attribute>
											</xsl:when>
											<xsl:otherwise>
												<xsl:attribute name="class">
													<xsl:value-of select="string('disabled')"/>
												</xsl:attribute>
											</xsl:otherwise>
										</xsl:choose>
										<xsl:value-of select="$strings[@phrase='SetDefault']" />
									</a>
								</div>
								<div id="adduser">
									<p><span><em>*</em><xsl:value-of select="$strings[@phrase='Last']" />:</span><input name="Last" class="text" type="text" maxlength="25" onchange="Users.capitalize(this); Users.validate(this,/^[A-Z-.]{{1,25}}$/);" onkeyup="Users.capitalize(this); if (this.value.length > 0) Users.validate(this,/^[A-Z-.]{{1,25}}$/);" /></p>
									<p><span><em>*</em><xsl:value-of select="$strings[@phrase='First']" />:</span><input name="First" class="text" type="text" maxlength="25" onchange="Users.capitalize(this); Users.validate(this,/^[A-Z-.]{{1,25}}$/);" onkeyup="Users.capitalize(this); if (this.value.length > 0) Users.validate(this,/^[A-Z-.]{{1,25}}$/);" /></p>
									<p><span><em>*</em><xsl:value-of select="$strings[@phrase='Phone']" />:</span><input name="Phone" class="text" type="text" maxlength="25" onchange="Users.validate(this,/^[0-9-*#.]{{1,25}}$/);" onkeyup="if (this.value.length > 0) Users.validate(this,/^[0-9-*#\.]{{1,25}}$/);" /></p>
									<xsl:if test="$showExt"><p><span><xsl:value-of select="$strings[@phrase='Ext.']" />:</span><input class="text" name="Ext" type="text" maxlength="25" onchange="Users.validate(this,/^[0-9-*#.]{{0,25}}$/);" onkeyup="if (this.value.length > 0) Users.validate(this,/^[0-9-*#]{{0,25}}$/);" /></p></xsl:if>
									<xsl:if test="$showEmail"><p><span><xsl:value-of select="$strings[@phrase='E-mail']" />:</span><input class="text" name="Email" type="text" maxlength="50" onchange="Users.validate(this,/^.{{0,50}}$/);" onkeyup="if (this.value.length > 0) Users.validate(this,/^.{{0,50}}$/);" /></p></xsl:if>
									<p class="buttons"><input id="addUserButton" name="addUserButton" class="button disabled" type="button" value="Add User" onmousedown="Users.buttonDown(this);" onmouseover="Users.buttonOver(this);" onmouseup="Users.buttonUp(this);" onmouseout="Users.buttonOut(this);" onclick="if (Users.validateAddUser()) Users.addUser();" /></p>
								</div>
							</td>
						</tr>
					</tbody>
				</table>
			</div>
			<div id="recent_table">
				<table cellspacing="0" cellpadding="0">
					<tbody>
						<tr class="header title">
							<th colspan="{$colspan}">
								<xsl:value-of select="$strings[@phrase='Recent Users']" />
							</th>
						</tr>
						<tr class="header">
							<th class="cbox"><input id="recent_checkbox" type="checkbox" onclick="Users.checkAll(this);"/></th>
							<th><xsl:value-of select="$strings[@phrase='Last']" /></th>
							<th><xsl:value-of select="$strings[@phrase='First']" /></th>
							<th><xsl:value-of select="$strings[@phrase='Phone']" /></th>
							<xsl:if test="$showExt"><th><xsl:value-of select="$strings[@phrase='Ext.']" /></th></xsl:if>
							<xsl:if test="$showEmail"><th><xsl:value-of select="$strings[@phrase='E-mail']" /></th></xsl:if>
							<th>&#160;</th>
						</tr>
						<xsl:for-each select="$recentusers">
							<tr>
								<xsl:attribute name="class">
									<xsl:choose>
										<xsl:when test="position() mod 2 = 1"></xsl:when>
										<xsl:otherwise>altrow</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<xsl:attribute name="id">
									<xsl:value-of select="concat('recentusers',position())" />
								</xsl:attribute>
								<td class="cbox"><input type="checkbox" onclick="Users.validateCheck(this);" /></td>
								<td class="last {$widthName}"><xsl:value-of select="./Last" /></td>
								<td class="first {$widthName}"><xsl:value-of select="./First" /></td>
								<td class="phone {$widthPhone}"><xsl:value-of select="./Phone" /></td>
								<xsl:if test="$showExt"><td class="ext {$widthExt}"><xsl:value-of select="./Ext" /></td></xsl:if>
								<xsl:if test="$showEmail"><td class="email {$widthEmail}"><xsl:value-of select="./Email" /></td></xsl:if>
								<td class="actions"><a href="javascript:Users.editRow('{concat('recentusers',position())}');" class="edit"><xsl:value-of select="$strings[@phrase='Edit']" /></a></td>
							</tr>
						</xsl:for-each>
						<tr class="actions">
							<td colspan="{$colspan}">
								<div><a href="javascript:Users.makePermanent();"><xsl:value-of select="$strings[@phrase='Make Selected Users Permanent']" /></a>
								</div>
								<div><a href="javascript:Users.removeUsers('recent_table');"><xsl:value-of select="$strings[@phrase='Remove Selected Users']" /></a>
								</div>
							</td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>
	</xsl:for-each>
	</xsl:template>
</xsl:transform>