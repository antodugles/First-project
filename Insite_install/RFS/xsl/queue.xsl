<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" />

  <xsl:include href="dictionary.xsl"/>
  <!-- Choose the queue configuration with the specified queueID -->
  <!-- If a particular configuration element doesn't exist for the specifed queueID, -->
  <!-- the configuration element from the "Default" queueID will be used -->
  <xsl:param name="queueID">Default</xsl:param>

  <xsl:template match="/configRFS">
  	<!-- "settings/XMLpath" is the default xmlPath -->
    <xsl:variable name="xmlPath" select="translate((settings/XMLpath | Queue[@id=$queueID]/XMLpath)[last()],'\\','/')" />
    <xsl:variable name="useConnectToGE" select="SendOptions/ConnectToGE/@enable" />
    <xsl:variable name="forcepollperiod" select="SendOptions/ConnectToGE/ForcePollPeriod" />
    <xsl:variable name="forcepollduration" select="SendOptions/ConnectToGE/ForcePollDuration" />
    <xsl:variable name="Export" select="(Queue[@id=$queueID or @id='Default']/Export)[last()]"/>
    <xsl:variable name="Import" select="(Queue[@id=$queueID or @id='Default']/Import)[last()]"/>
    <xsl:variable name="exportPath" select="translate($Export[@enable='true']/@commandPath,'\\','/')" />
    <xsl:variable name="importPath" select="translate($Import[@enable='true']/@commandPath,'\\','/')" />
    <div id="root">
      <form>
        <script type="text/javascript">
          Queue.setPath("<xsl:value-of select="$xmlPath" />");
          APICalls.forcePollPeriod = <xsl:value-of select="$forcepollperiod" />;
          APICalls.forcePollDuration = <xsl:value-of select="$forcepollduration" />;
          APICalls.useConnectToGE = <xsl:value-of select="$useConnectToGE" />;
          Queue.setExportPath("<xsl:value-of select="$exportPath" />");
          Queue.setImportPath("<xsl:value-of select="$importPath" />");
        </script>
      </form>
      <div>
        <div class="scrolltable" id="oScrollTableDiv">
          <table id="oScrollTable" cellspacing="0" cellpadding="2">
            <xsl:variable name="Table" select="(Queue[@id=$queueID or @id='Default']/Table)[last()]"/>
            <colgroup>
              <col class="CheckBox"/>
              <xsl:apply-templates select="$Table/Column" mode="col">
                <xsl:sort select="@order" data-type="number"/>
              </xsl:apply-templates>
            </colgroup>
            <tr id="header">
              <th align="left" class="cbox">
                <input type="checkbox" id="checkall" onclick="Queue.OnCheckAll(this)"/>
              </th>
              <xsl:apply-templates select="$Table/Column" mode="th">
                <xsl:sort select="@order" data-type="number"/>
              </xsl:apply-templates>
            </tr>
            <tbody id="oTableBody">
            </tbody>
          </table>
        </div>
        <ul id="FilterList" onmouseover="Queue.ShowFilter()" onmouseout="Queue.HideFilter()"></ul>
      </div>
      <div class="buttons">
        <input type="button" class="button" onclick="Queue.Send()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
          <xsl:attribute name="value">
            <xsl:call-template name="String">
              <xsl:with-param name="Phrase" select="string('Send')"/>
            </xsl:call-template>
          </xsl:attribute>
        </input>
        <input type="button" class="button" onclick="Queue.Delete()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
          <xsl:attribute name="value">
            <xsl:call-template name="String">
              <xsl:with-param name="Phrase" select="string('Delete')"/>
            </xsl:call-template>
          </xsl:attribute>
        </input>
        <xsl:if test="$Export[@enable='true']">
          <input type="button" class="button" onclick="Queue.Export()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
            <xsl:attribute name="value">
              <xsl:call-template name="String">
                <xsl:with-param name="Phrase" select="string('Export')"/>
              </xsl:call-template>
            </xsl:attribute>
          </input>
        </xsl:if>
        <xsl:if test="$Import[@enable='true']">
          <input type="button" class="button" onclick="Queue.Import()" onmousedown="Queue.buttonDown(this)" onmouseup="Queue.buttonUp(this)" onmouseout="Queue.buttonUp(this)">
            <xsl:attribute name="value">
              <xsl:call-template name="String">
                <xsl:with-param name="Phrase" select="string('Import')"/>
              </xsl:call-template>
            </xsl:attribute>
          </input>
        </xsl:if>
      </div>
      <div id="oRFSView">
      </div>
      <xsl:if test="./page/QSTA[@show='true']">
        <div id="statusbar">
          <iframe src="javascript:false" scrolling="no" frameborder="0"></iframe>
          <div>
            <p id="connectionstatus" class="left">
              <span class="green">
                <xsl:value-of select="$strings[@phrase='Connected']" />
              </span>
            </p>
            <p id="queuestatus"></p>
            <p id="actionstatus" class="right">
              <xsl:value-of select="$strings[@phrase='Status']" />
            </p>
            <input type="button" onclick="StatusBar.hide();" value="X"/>
          </div>
        </div>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- Add <col> tags -->
  <xsl:template match="Column[@show='true']"  mode="col">
    <col class="{@id}"/>
  </xsl:template>

  <!-- Add <th> tags -->
  <xsl:template match="Column[@show='true']"  mode="th">
    <th>
      <xsl:if test="@enablefilter='true'">
        <xsl:attribute name="id">
          <xsl:value-of select="concat(@id,'Header')"/>
        </xsl:attribute>
        <xsl:attribute name="onmouseover">
          <xsl:value-of select="string('Queue.ShowFilterButton(this)')"/>
        </xsl:attribute>
        <xsl:attribute name="onmouseout">
          <xsl:value-of select="string('Queue.HideFilterButton(this)')"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:variable name="sortid">
        <xsl:choose>
          <xsl:when test="@id='Date'">
            <!-- Sort using the hidden "DateTime" column which is converted to milliseconds for sorting -->
            <xsl:value-of select="string('DateTime')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@id"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <a href="javascript:Queue.Sort('{$sortid}')">
        <xsl:call-template name="String">
          <xsl:with-param name="Phrase" select="@headertext"/>
        </xsl:call-template>
        <span id="{$sortid}" class="none">&#160;&#160;&#160;&#160;</span>
      </a>
      <xsl:if test="@enablefilter='true'">
        <input class="none" type="button" value="F" onclick="Queue.CreateFilter(this)" name="{@id}">
          <xsl:attribute name="title">
            <xsl:call-template name="String">
              <xsl:with-param name="Phrase" select="string('Filter')"/>
            </xsl:call-template>
          </xsl:attribute>
        </input>
      </xsl:if>
    </th>
  </xsl:template>
</xsl:transform>