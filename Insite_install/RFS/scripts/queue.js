// This JavaScript file contains functions that are used on RFS Queue page.
// Date Added: 5/25/06
// Last Modified: 12/07/06
// Written by: Jung Oh
//	Mozilla compatibility by: Andy Kant
  
var Queue = {
	m_sQueueID: "Default",
	m_sQueueFolder: "",
	m_sQueuePath: false,
	m_oTBodyDoc: false,
	m_oTRXSLDoc: false,
	m_oViewXSLDoc: false,
	m_oSortXSLDoc: false,
	m_sCurrentSort: false,
	m_sCurrentSortOrder: false,
	m_oSelTRNode: false,
	m_oFilters: new Object(),
	m_oStringsNode: false,
	m_oConfigXMLDoc: false,
	m_firstTime: true,
	m_editMode: false,
	m_sendMode: false,
	m_exportPath: false,
	m_importPath: false,

	// Set the file path.
	setPath: function(path) {
		if (path.lastIndexOf("/") > -1)
			Queue.m_sQueueFolder = path.substr(0, path.lastIndexOf("/")+1);
		else
			Queue.m_sQueueFolder = path;
	},
	
	// Refresh or create the queue list
	RefreshList: function()
	{
		var oTBodyTag = CSSpp.$("oTableBody");
		// Don't start if the table is not ready! IE will crash otherwise.
		if (oTBodyTag && document.all)
		{
			if (oTBodyTag.readyState!="complete")
				return;
		}	
		
		Queue.m_oTBodyDoc = FileIO.getDOMDocument();
		//Queue.m_oTBodyDoc.setProperty("SelectionLanguage", "XPath");
		var oTBodyNode = Queue.m_oTBodyDoc.createElement("tbody");
		if (document.all)
			Queue.m_oTBodyDoc.documentElement = oTBodyNode;
		else
			Queue.m_oTBodyDoc.appendChild(oTBodyNode);
		
		var list = FileIO.listDirectory(Queue.m_sQueueFolder);
		Queue.m_sQueuePath = list.path.replace(/%20/g," ");
		if (list)
		{
			nTotal = 0;
			nNotSent = 0;
			for (var i = 0; i < list.files.length; i++)
			{
				if (/\.xml$/i.test(list.files[i]))
				{
					// Transform to a table row
					var oTRNode = Queue.GetTableRow(list.files[i]);
					if (oTRNode)
					{
						nTotal+=1;
						if (document.all)
						{
							if (oTRNode.selectSingleNode("td[@class='Status'][text()='" + Queue.getString("Not Sent") + "']"))
								nNotSent+=1;
						}
						else
						{
							// In Mozilla, oTRNode is tr HTML DOM element
							var re = new RegExp("<td class=\"Status\">" + Queue.getString("Not Sent") + "</td>");
							if (oTRNode.innerHTML.match(re))
								nNotSent+=1;
						}
						oTBodyNode.appendChild(oTRNode);
					}
				}
			}
			
			// Update the status bar with the queue statistics
			StatusBar.updateQueueStatus(Queue.getString("Total") + ": "+ nTotal + " (" + Queue.getString("Not Sent") + ": " + nNotSent + ")");
		}
		
		// Sort the rows in 'tbody' node and add to 'tbody' html tag
		if (Queue.m_sCurrentSort)
		{
			Queue.AddTable(oTBodyNode, Queue.m_sCurrentSort, Queue.m_sCurrentSortOrder);
		}
		else
		{
			// Get the default sort info. from the configuration XML
			var oTableConfig = Queue.getConfigXML().documentElement.selectSingleNode("(Queue[@id='" + Queue.m_sQueueID + "' or @id='Default']/Table)[last()]");
			var sort1 = oTableConfig.getAttribute("sort1");
			var sort1order = oTableConfig.getAttribute("sort1order");
			var sort2 = oTableConfig.getAttribute("sort2");
			var sort2order = oTableConfig.getAttribute("sort2order");
			
			Queue.AddTable(oTBodyNode, sort1, sort1order, sort2, sort2order);
			// Show the sort arrow on Status header
			var oSpan = CSSpp.$(sort1);
			oSpan.className = sort1order;	
			Queue.m_sCurrentSort=sort1;
			Queue.m_sCurrentSortOrder=sort1order;
		}
	},

	// Check if any column is disabled and disperse the width of the disabled column to other columns.
	AdjustColumnWidth: function()
	{
		var width = CSSpp.$("oScrollTable").offsetWidth;
		//alert(width);
		var oColGroup = document.getElementsByTagName("colgroup")[0];
		// Firefox doesn't allow colgroup styling, style the first row of each TBODY instead.
		var th = CSSpp.$("header").getElementsByTagName("TH");
		var td = false;
		if (CSSpp.$("oTableBody").getElementsByTagName("TR").length > 0)
			td = CSSpp.$("oTableBody").getElementsByTagName("TR")[0].getElementsByTagName("TD");
		var totalPercent = 0;
		var i;
		// Calculate the total percentage of the column widths
		for (i = 0; i < oColGroup.childNodes.length; i++)
		{
			var widthStyle = CSSpp.style(oColGroup.childNodes[i], "width").replace("%", "");
			th[i].style.width = CSSpp.style(oColGroup.childNodes[i], "width");
			if (td && td[i] && td.length > 1)
				td[i].style.width = (th[i].offsetWidth + 2) + "px";
			if (!isNaN(widthStyle) && !/px/.test(widthStyle))
				totalPercent += parseFloat(widthStyle);
		}

		var remainPercent = 100 - totalPercent;
		// Disperse the remain percentage to all the columns that are using percentage for the width
		if (remainPercent > 0 && remainPercent < 100)
		{
			for (i = 0; i < oColGroup.childNodes.length; i++)
			{
				var widthStyle = CSSpp.style(oColGroup.childNodes[i], "width").replace("%", "");
				if (!isNaN(widthStyle))
				{
					var nWidth = parseFloat(widthStyle);
					var nNewWidth = nWidth + (remainPercent * nWidth / totalPercent);
					oColGroup.childNodes[i].style.width = nNewWidth + "%";
					th[i].style.width = nNewWidth + "%";
					if (td && td[i] && td.length > 1)
						td[i].style.width = (th[i].offsetWidth + 2) + "px";
				}
			}
		}
		
		// Fix the header.
		Queue.fixHeader();
	},

	// Load the RFS XML and transform into a table row
	GetTableRow: function(sRFSName)
	{
		// Load RFS XML 
		var oXMLDoc = Queue.LoadRFSDom(sRFSName);
		// Load table transformation XSL if not loaded
		if (!Queue.m_oTRXSLDoc)
		{
			Queue.m_oTRXSLDoc = FileIO.loadXML("./xsl/tablerow.xsl");
		}
		
		// Set the queueID parameter of the transformation with m_sQueueID
		var oQueueuID= Queue.m_oTRXSLDoc.documentElement.selectSingleNode("./xsl:param[@name='queueID']");
		if (document.all)
			oQueueuID.text = Queue.m_sQueueID;
		else
			oQueueuID.textContent = Queue.m_sQueueID;

		var oResult = FileIO.transformXML(oXMLDoc, Queue.m_oTRXSLDoc).replace(/<\?.*?\?>/g, "");
		var oTRNode = false;
		if (document.all)
			oTRNode = FileIO.makeDOMDocument(oResult).documentElement;
		else
		{
			var div = document.createElement("TABLE");
			div.innerHTML = oResult;
			if (div.childNodes[0].childNodes[0])
				oTRNode = div.childNodes[0].childNodes[0];
		}
		if (oTRNode)
		{
			if (oTRNode.nodeName.match(/^tr$/i)) 
			{
				return oTRNode;
			}
			else
			{
				return false;
			}
		}
		else
			return false;
	},

	// Load the RFS XML and add the file info. as extra elements and return the DOM
	LoadRFSDom: function(sRFSName)
	{
		var sRFSPath = Queue.m_sQueuePath + "\\" + sRFSName;
		//alert(sRFSPath);
		var oXMLDoc = FileIO.loadXML(sRFSPath);
		
		// Create FileName element and add to the XML
		var oFileName = oXMLDoc.createElement("FileName");
		if (document.all)
			oFileName.text = sRFSName;
		else
			oFileName.textContent = sRFSName;
		oXMLDoc.documentElement.appendChild(oFileName);
		
		
		// Create Date element and add to the XML
		var oDateElement = oXMLDoc.createElement("DateTime");
		//var oFile = Queue.m_oFSO.GetFile(sRFSPath);
		var oDate = new Date(FileIO.Properties.lastModified(sRFSPath));
		if (document.all)
			oDateElement.text = oDate.getTime();
		else
			oDateElement.textContent = oDate.getTime();
		oXMLDoc.documentElement.appendChild(oDateElement);
		//alert(oXMLDoc.xml);
		return oXMLDoc;
	},

	// This function sorts the rows in 'tbody' xml node and replace the 'tbody' html tag with the sorted rows
	AddTable: function(oTBodyNode, SortBy1, SortOrder1, SortBy2, SortOrder2)
	{
		var oTableTag = CSSpp.$("oScrollTable");
		var oTBodyTag = CSSpp.$("oTableBody");
		
		// Remove old 'tbody' tag if exists
		if (oTBodyTag)
		{
			oTableTag.removeChild(oTBodyTag);
		}
		
		// Sort oTBodyNode
		// Load sort XSL if not loaded
		if (!Queue.m_oSortXSLDoc)
		{
			Queue.m_oSortXSLDoc = FileIO.loadXML("./xsl/sort.xsl");
		}
		
		// Modify the sort XSL with the sort parameters
		var oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort1']");
		if (document.all)
			oSortVar.text = SortBy1;
		else
			oSortVar.textContent = SortBy1;
		var sDataType = "text";
		if (SortBy1 == "DateTime")
		{
			sDataType = "number";
		}
		var oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort1type']");
		if (document.all)
			oSortVar.text = sDataType;
		else
			oSortVar.textContent = sDataType;
		var oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort1order']");
		if (SortOrder1)
		{
			if (SortOrder1.match(/descending/i))
			{
				if (document.all)
					oSortVar.text = "descending";
				else
					oSortVar.textContent = "descending";
			}
			else
			{
				if (document.all)
					oSortVar.text = "ascending";
				else
					oSortVar.textContent = "ascending";
			}
		}
			
		// Update the secondary sort only if it's specified
		if (SortBy2)
		{
			oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort2']");
			if (document.all)
				oSortVar.text = SortBy2;
			else
				oSortVar.textContent = SortBy2;
			sDataType = "text";
			if (SortBy2 == "DateTime")
			{
				sDataType = "number";
			}
			var oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort2type']");
			if (document.all)
				oSortVar.text = sDataType;
			else
				oSortVar.textContent = sDataType;
			var oSortVar = Queue.m_oSortXSLDoc.documentElement.selectSingleNode("./xsl:variable[@name='sort2order']");
			if (SortOrder2)
			{
				if (SortOrder2.match(/descending/i))
				{
					if (document.all)
						oSortVar.text = "descending";
					else
						oSortVar.textContent = "descending";
				}
				else
				{
					if (document.all)
						oSortVar.text = "ascending";
					else
						oSortVar.textContent = "ascending";
				}
			}
		}
		//alert(Queue.m_oSortXSLDoc.xml);
		
		var oResultDoc = FileIO.transformXML(oTBodyNode, Queue.m_oSortXSLDoc).replace(/<\?.*?\?>/g, "");
		if (document.all)
		{
			oResultDoc = FileIO.makeDOMDocument(oResultDoc);
			oTBodyNode = oResultDoc.documentElement;
		}
		else
		{
			var div = document.createElement("TABLE");
			div.innerHTML = oResultDoc;
			if (div.childNodes[0])
				oResultDoc = div.childNodes[0];
			var x = FileIO.getDOMDocument();
			x.appendChild(oResultDoc);
			oResultDoc = x.selectSingleNode("tbody");
			oTBodyNode = oResultDoc;
		}
		
		// for debugging
		//if (ViewXML)
		//	ViewXML.view(oResultDoc.xml);
		
		oTBodyTag = document.createElement("tbody");
		oTBodyTag.id = "oTableBody";
		// Create the XPath for the filter
		var sFilterXPath = "tr";
		for (var sFilterColumn in Queue.m_oFilters)
		{
			sFilterXPath+="[td[@class='"+sFilterColumn+"']"
			if (Queue.m_oFilters[sFilterColumn]=="&nbsp;")
				sFilterXPath+="[not(text())]]";  // empty column
			else
				sFilterXPath+="[text()='"+Queue.m_oFilters[sFilterColumn]+"']]";
		}
		var oTRNodeList = oTBodyNode.selectNodes(sFilterXPath);
		for (var i=0; i<oTRNodeList.length; i++) {
			// Add altrow class for alternating the row colors
			if (oTRNodeList[i].getAttribute("class") == "invalid") {
				if (i%2 == 1)
					oTRNodeList[i].setAttribute("class","invalid_altrow");
				else
					oTRNodeList[i].setAttribute("class","invalid");
			} else {
				if (i%2 == 1)
					oTRNodeList[i].setAttribute("class","altrow");
				else
					oTRNodeList[i].removeAttribute("class");
			}
			Queue.AddTableRow(oTBodyTag, oTRNodeList[i]);
		}
		
		// Append <tbody> into <table>
		oTableTag.appendChild(oTBodyTag);
		if (oTBodyTag.getElementsByTagName("TR").length == 0)
		{
			// There's no data. Add "No Data" row.
			var oTR = document.createElement("TR");
			var oTD = document.createElement("TD");
			//oTBodyTag.insertRow().insertCell();
			oTD.colSpan = 7;
			oTD.style.textAlign = "center";
			oTD.innerHTML = "No Data";
			oTR.appendChild(oTD);
			oTBodyTag.appendChild(oTR);
			// Remove RFS if it exists.
			var rfs = CSSpp.$("oRFSView");
			if (rfs)
				rfs.parentNode.removeChild(rfs);
			// Make sure the "check all" checkbox is unchecked.
			var cbox = CSSpp.$("checkall");
			if (cbox && cbox.checked)
				cbox.checked = false;
		}
		
		// Format data.
		Queue.format("oScrollTable");
		// Resize the table container
		Queue.OnTableResize();
		
		// Remove checks from checked rows that are filtered out
		// We don't want users to do anything with the ones that are not shown
		var oCheckedTRs = Queue.m_oTBodyDoc.documentElement.selectNodes("tr[td/input[@checked]]");
		for (var i=0; i<oCheckedTRs.length; i++)
		{
			if (!CSSpp.$(oCheckedTRs[i].getAttribute("id")))
			{
				oCheckedTRs[i].firstChild.firstChild.removeAttribute("checked");
			}
		}
		
		if (Queue.m_oSelTRNode)
		{
			// Let Queue.m_oSelTRNode point to the corresponding node in Queue.m_oTBodyDoc.
			// Queue.m_oTBodyDoc might have been replaced if this is called from RefreshList().
			// Make it false if it's filtered out
			var sID = Queue.m_oSelTRNode.getAttribute("id");
			if (CSSpp.$(sID))
				Queue.m_oSelTRNode = Queue.m_oTBodyDoc.documentElement.selectSingleNode("./tr[@id='"+sID+"']");
			else
				Queue.m_oSelTRNode = false;
		}
		
		if (!Queue.m_oSelTRNode)
		{
			// View the first one
			Queue.m_oSelTRNode = oTRNodeList[0];
		}
		
		if (Queue.m_oSelTRNode)
		{
			Queue.ViewRFS(Queue.m_oSelTRNode.getAttribute("id"));
		}
	},

	// Resize the table container
	OnTableResize: function()
	{
		Queue.AdjustColumnWidth();
		if (!Queue.m_maxScrollTableHeight)
		{
			var oTableConfig = Queue.getConfigXML().documentElement.selectSingleNode("(Queue[@id='" + Queue.m_sQueueID + "' or @id='Default']/Table)[last()]");
			Queue.m_maxScrollTableHeight = oTableConfig.getAttribute("maxheight");
			if (!Queue.m_maxScrollTableHeight)
				Queue.m_maxScrollTableHeight = 200;
		}
		var tr = CSSpp.$("oScrollTableDiv").getElementsByTagName("TR");
		var trheight = 0;
		for (var i = 0; i < tr.length; i++)
			trheight += tr[i].offsetHeight;
		var tableheight = CSSpp.$("oScrollTable").offsetHeight + CSSpp.$("header").offsetHeight;
		tableheight = (trheight < tableheight) ? trheight : tableheight;
		CSSpp.$("oScrollTableDiv").style.height = (tableheight < Queue.m_maxScrollTableHeight) ? tableheight + "px" : Queue.m_maxScrollTableHeight + "px";
	},

	// This function will add a new row defined in oTRNode xml node to the html tbody object defined in oTBody.
	AddTableRow: function(oTBodyTag, oTRNode)
	{
		if (!oTRNode.nodeName.match(/^tr$/i)) 
		{
			return;
		}
		
		// Since table rows cannot be created using innerHTML method, table object and it's methods have to be used create the rows and cells.
		var oTRTag = false;
		if (document.all)
			oTRTag = document.createElement(oTRNode.xml);
		else
		{
			oTRTag = document.createElement("TR");
			oTRTag.id = oTRNode.id;
			oTRTag.className = oTRNode.className;
			oTRTag.onclick = function(){ Queue.ViewRFS(this.id); }
		}
		var iTotalRows = oTRNode.childNodes.length;
		for(var i = 0; i < iTotalRows; i++) 
		{
			if (oTRNode.childNodes[i].nodeName.match(/^td$/i))
			{
				var oTDTag = false;
				if (document.all)
					oTDTag = document.createElement(oTRNode.childNodes[i].xml);
				else
				{
					oTDTag = document.createElement("TD");
					oTDTag.className = oTRNode.childNodes[i].className;
				}
				oTDTag.innerHTML = FileIO.makeDOMString(oTRNode.childNodes[i]).replace(/^<td>|^<td [^<]\">|<\/td>$/gi, "");
				if (oTDTag.innerHTML=="")
					oTDTag.innerHTML="&nbsp;";
				oTRTag.appendChild(oTDTag);	
			}
		}
		//alert(oTRTag.outerHTML);
		oTBodyTag.appendChild(oTRTag);
	},

	ViewRFS: function(sRFSName)
	{
		// Cancel the edit mode
		Queue.m_editMode = false;
		// Load RFS XML 
		var oXMLDoc = Queue.LoadRFSDom(sRFSName);
		
		// Load RFS view transformation XSL if not loaded
		if (!Queue.m_oViewXSLDoc)
		{
			Queue.m_oViewXSLDoc = FileIO.getDOMDocument();
			Queue.m_oViewXSLDoc.async = false;
			Queue.m_oViewXSLDoc.load(".\\xsl\\rfsview.xsl");
		}
		
		// Set the queueID parameter of the transformation with m_sQueueID
		var oQueueuID= Queue.m_oViewXSLDoc.documentElement.selectSingleNode("./xsl:param[@name='queueID']");
		if (document.all)
			oQueueuID.text = Queue.m_sQueueID;
		else
			oQueueuID.textContent = Queue.m_sQueueID;
			
		var oDivTag = false;
		var oDivTag = CSSpp.$("oRFSView");
		if (oDivTag)
			oDivTag.parentNode.removeChild(oDivTag);
		var div = document.createElement("DIV");
		div.innerHTML = FileIO.transformXML(oXMLDoc, Queue.m_oViewXSLDoc);
		CSSpp.$("root").appendChild(div.childNodes[0]);
		
		// Remove 'selected' class from the previously selected row and add to the newly selected row.
		var sNewClass;
		var oTRTag;
		if (Queue.m_oSelTRNode)
		{
			var sPrevId = Queue.m_oSelTRNode.getAttribute("id");
			// Remove 'selected' class
			oTRTag = CSSpp.$(sPrevId);
			sNewClass = Queue.RemoveClass(oTRTag.className, "selected");
			sNewClass = Queue.RemoveClass(sNewClass, "selected_invalid");
			oTRTag.className = sNewClass;
			Queue.m_oSelTRNode.setAttribute("class", oTRTag.className);
		}
		// Add 'selected' class to the tr object
		oTRTag = CSSpp.$(sRFSName);
		sNewClass = Queue.AddClass(oTRTag.className, oTRTag.className.indexOf('invalid') > -1 ? "selected_invalid" : "selected");
		oTRTag.className = sNewClass;
		Queue.m_oSelTRNode = Queue.m_oTBodyDoc.documentElement.selectSingleNode("./tr[@id='" + sRFSName + "']");
		Queue.m_oSelTRNode.setAttribute("class", oTRTag.className);
		Queue.format("oRFSView");
	},

	AddClass: function(sCurrentClass, sAddClass)
	{
		if (sCurrentClass.length)
			return sCurrentClass + " " + sAddClass;
		else
			return sAddClass;
	},

	RemoveClass: function(sCurrentClass, sRemoveClass)
	{
		var sNewClass;
		var re = new RegExp("\s*" + sRemoveClass);
		sNewClass = sCurrentClass.replace(re, "");
		re = new RegExp(sRemoveClass + "\s*");
		sNewClass = sNewClass.replace(re, "");
		re = new RegExp(sRemoveClass);
		return sNewClass.replace(re, "");
	},

	Sort: function(sSortBy)
	{
		var oTBodyTag = CSSpp.$("oTableBody");
		
		// Don't start if the table is not ready! IE will crash otherwise.
		if (oTBodyTag && document.all)
		{
			if (oTBodyTag.readyState!="complete")
				return;
		}	
		
		// Find out the current sort status of the column
		var oSpan = CSSpp.$(sSortBy);
		var sSortOrder = "ascending";
		if (oSpan.className=="ascending")
			sSortOrder = "descending";
		
		// Sort the table by calling AddTable()
		if (sSortBy == Queue.m_sCurrentSort)
			// If the current sort and requested sort are the same column, this is just sort order toggling
			// So, just keep the old secondary sort
			Queue.AddTable(Queue.m_oTBodyDoc.documentElement, sSortBy, sSortOrder);
		else
			Queue.AddTable(Queue.m_oTBodyDoc.documentElement, sSortBy, sSortOrder, Queue.m_sCurrentSort, Queue.m_sCurrentSortOrder);
		
		// Clear the header's sort arrow.
		var oSpans = CSSpp.$("header").getElementsByTagName("span");
		for (var i = 0; i < oSpans.length; i++)
		{
			oSpans[i].className="none";
		}

		// Update the SPAN object's class with the sort order 
		// This object is used to display the sort arrow
		oSpan.className = sSortOrder;
		Queue.m_sCurrentSort = sSortBy;
		Queue.m_sCurrentSortOrder = sSortOrder;
	},

	OnCheckClick: function(oCheckBox, sID)
	{
		var oCheckBoxNode = Queue.m_oTBodyDoc.documentElement.selectSingleNode("./tr[@id='"+sID+"']/td/input");
		if (oCheckBox.checked)
			oCheckBoxNode.setAttribute("checked", oCheckBox.checked);
		else
			oCheckBoxNode.removeAttribute("checked");
	},

	OnCheckAll: function(oCheckAll)
	{
		var rows = CSSpp.$("oTableBody").getElementsByTagName("TR");
		for (var i=0; i < rows.length; i++) 
		{
			var oInputs = rows[i].getElementsByTagName("input");
			if (oInputs.length > 0)
			{	
				var oCheckBox = oInputs[0];
				oCheckBox.checked = oCheckAll.checked;
				Queue.OnCheckClick(oCheckBox, rows[i].id);
			}
		}
	},

	Send: function()
	{
		if (Queue.m_sendMode)
			return;
			
		// Disable buttons and change the cursor
		Queue.SetSendMode(true);
		
		// Check if any sent item is selected
		var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]][td[@class='Status'][text()='" + Queue.getString("Sent") + "']]");
		if (oNodeList.length > 0)
		{
			alert(Queue.getString("AlreadySentMsg"));
			// Enable buttons and reset the cursor
			Queue.SetSendMode(false);
			return;
		}
		// Select the checked RFSs except for invalid ones that are not able to be sent (ie. ones without a SystemID attached).
		var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]][not(contains(@class,'invalid'))]");
		
		// Stores the out of service hour message
		var sNotCovered = "";
		var bAtLeastOneSucceeded = false;
		var bRunForcePoll = false;
		if (oNodeList.length > 0)
		{
			var i = 0;
			var attemptSendNext = function() {
				//*********************** Codes for Send************************
				var sRFSId = oNodeList[i].getAttribute("id");
				// Update the status of this RFS to Sending...
				Queue.UpdateTableCell(sRFSId, "Status", Queue.getString("Sending"));
				// Trigger "... effect" (animating the dots)
				Queue.UpdateTableCell(sRFSId, "Status", Queue.getString("Sending"), ".");
				
				// Update the status bar with the status of the entire sending operation
				var statusMsg = "<span class=\"red\">" + Queue.getString("Sending") + " " + (i + 1) + " <span class=\"lower\">" + Queue.getString("Of") + "</span> " + oNodeList.length + " " + Queue.getString("Item(s)") + "</span> ";
				StatusBar.updateActionStatus(statusMsg, true); 
				var sRFSPath = Queue.m_sQueuePath + "\\" + sRFSId;
				// Check for other system ID.
				var runProcessors = FileIO.loadXML(sRFSPath).getElementsByTagName('OtherSystemID');
				runProcessors = runProcessors.length > 0 ? (FileIO.textContent(runProcessors[0]).length > 0 ? false : true) : true;
				// Send RFS.
				var result = APICalls.send(sRFSPath, {postprocess: runProcessors}, function(result) {
					// Check result.
					if (result.bResult)
					{
						if (result.rfsNumber == "")
						{
							// It failed at the backoffice.  Show the "Request Failed" message and continue
							alert(result.errorMsg);
							// Change the RFS status back to Not Sent
							Queue.UpdateTableCell(sRFSId, "Status", Queue.getString("Not Sent"));
						}
						else
						{
							// Update the RFS status to Sent
							Queue.UpdateTableCell(sRFSId, "Status", Queue.getString("Sent"));
							// Update the Reference Number cell
							Queue.UpdateTableCell(sRFSId, "RfsNumber", result.rfsNumber);
							
							// Update the after hour message
							if (result.afterHourMsg != "")
								sNotCovered = result.afterHourMsg;
								
							bAtLeastOneSucceeded = true;
							// Run force polling if at least one successfully sent RFS is for this system
							bRunForcePoll = bRunForcePoll || runProcessors;
						}
					}
					else
					{
						// There was an error with the API (ex. connection errors).  Show the error message and exit.  Don't even try the rest of the selected items.
						alert(result.errorMsg);
						// Change the RFS status back to Not Sent
						Queue.UpdateTableCell(sRFSId, "Status", Queue.getString("Not Sent"));
						i = oNodeList.length - 1;  // Skip rest of the items
					}
					
					// Attempt next RFS if applicable.
					if (++i < oNodeList.length)
						attemptSendNext();
					// Otherwise finish up.
					else
					{
						if (bRunForcePoll)
						{
							// HACK: Fixes mysterious IE error by using a timeout.
							setTimeout(function(){
								// Since at least one request was a success, increase the polling rate using ConnectToGE.exe
								var forcePollResult = APICalls.forcePoll();
								// Show any error message
								if (forcePollResult)
									alert(forcePollResult);
							}, 50);
						}
						
						// Reset the sending status in the status bar
						StatusBar.updateActionStatus(Queue.getString("Status"));
						
						if (oNodeList.length > 0 && bAtLeastOneSucceeded)
							Queue.RefreshList();
						
						// Show the out of OnLine Center hours message if it's not empty
						if (sNotCovered != "")
							alert(sNotCovered);
							
						// Enable buttons and reset the cursor
						Queue.SetSendMode(false);
					}
				});
			}
			// Start processing.
			attemptSendNext();
		}
		else
		{
			// Enable buttons and reset the cursor
			Queue.SetSendMode(false);
		}
	},
	
	// Enable/Disable buttons and change the cursor
	SetSendMode: function(bSet)
	{
		Queue.m_sendMode = bSet;
		// Change the cursor to hourglass or normal depending on bSet
		var className = document.body.className;
		var newClass;
		if (bSet)
			newClass = Queue.AddClass(className, "wait");
		else
			newClass = Queue.RemoveClass(className, "wait");
		document.body.className = newClass;
		
		var divs = document.getElementsByTagName("div")
		for (var j=0; j<divs.length; j++)
		{
			if (divs[j].className.match(/buttons/))
			{
				// Disable or enable the buttons depending on bSet
				var inputs = divs[j].getElementsByTagName("input")
				for (var i=0; i<inputs.length; i++)
				{
					inputs[i].disabled = bSet;
					className = inputs[i].className;
					if (bSet)
						newClass = Queue.AddClass(className, "wait");
					else
						newClass = Queue.RemoveClass(className, "wait");
					inputs[i].className = newClass;
				}
			}
		}
	},
	
	// Updates the specified cell and add "... effect" if certain conditions meet
	// If sValue is the same as the current cell value and sAddedDots is ".", "... effect" runs until the value changes to something else.
	UpdateTableCell: function(sRFSId, sColumnClass, sValue, sAddedDots)
	{
		// Find the row
		oRow = CSSpp.$(sRFSId);
		
		if (oRow)  // Maybe this row is gone by now if the filter is set to Not Send or something, so prevent error by checking it.
		{
			// Find the cell
			var oCells = oRow.getElementsByTagName("td");
			for (var i=0; i<oCells.length; i++)
			{
				if (oCells[i].className == sColumnClass)
				{
					
					if (sAddedDots)
					{
						var re = new RegExp(">?"+sValue+"\.*<?");
						if (oCells[i].innerHTML.match(re))
						{
							oCells[i].innerHTML="<span class=\"red\">" + sValue + sAddedDots + "</span>";
							if (sAddedDots.length < 3)
								sAddedDots += ".";
							else
								sAddedDots = ".";
							window.setTimeout("Queue.UpdateTableCell(\""+sRFSId+"\",\""+sColumnClass+"\",\""+sValue+"\",\""+sAddedDots+"\")", 500);
						}
					}
					else
						oCells[i].innerHTML=sValue;
					
					return;
				}
			}
		}
	},
	
	Delete: function()
	{
		if (Queue.m_sendMode)
			return;
		// Check if any not-sent item is selected
		var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]][td[@class='Status'][text()='" + Queue.getString("Not Sent") + "']]");
		if (oNodeList.length > 0)
		{
			if (!confirm(Queue.getString("DeleteNotSentMsg")))
					return;
			else
				oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]]");
		}
		else
		{
			// Confirm multiple deletion
			oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]]");
			if (oNodeList.length > 1)
				if (!confirm(Queue.getString("DeleteAllMsg")))
					return;
		}
				
		var oNode;
		for (var i=0; i < oNodeList.length; i++) {
			var nodeid = oNodeList[i].getAttribute("id");
			FileIO.deleteFile(Queue.m_sQueuePath + "\\" + nodeid);
			FileIO.deleteDirectory(Queue.m_sQueuePath + "\\" + nodeid.substr(0, nodeid.lastIndexOf(".xml")));
			if (Queue.m_oSelTRNode && Queue.m_oSelTRNode == oNodeList[i])
			{
				Queue.m_oSelTRNode = false;
			}
		}		
		if (oNodeList.length > 0)
			Queue.RefreshList();
	},

	// Update button style while pushed.
	buttonDown: function(e) {
		e.className = Queue.AddClass(e.className, "pushed");
	},

	// Update button style while released.
	buttonUp: function(e) {
		e.className = Queue.RemoveClass(e.className, "pushed");
	},

	ShowFilterButton: function(oTH) {
		// Show the button in red if the filter is in effect
		if (Queue.m_oFilters[oTH.childNodes[1].name])
			oTH.childNodes[1].className = "red";
		else
			oTH.childNodes[1].className = "normal";
	},

	HideFilterButton: function(oTH) {
		// Don't hide if the filter is in effect
		if (!Queue.m_oFilters[oTH.childNodes[1].name])
			oTH.childNodes[1].className = "none";
	},

	// Create and show the dynamic filter for the column
	CreateFilter: function(oButton) {
		var oTableBody = CSSpp.$("oTableBody");
		var oFilterDict = new Object();
		var FilterArray = new Array();
		for (var i=0; i < oTableBody.rows.length; i++) 
		{
			for (var j=0; j < oTableBody.rows[i].cells.length; j++) 
			{
				var oTD = oTableBody.rows[i].cells[j];
				if (oTD.className == oButton.name)
					break;
			}
			
			if (!oFilterDict[oTD.innerHTML])
			{
				oFilterDict[oTD.innerHTML]=oTD.innerHTML;
				FilterArray.push(oTD.innerHTML);
			}
		}

		// Show FilterList
		var oFilterList = CSSpp.$("FilterList");
		if (oFilterList && FilterArray.length > 0)
		{
			// Sort the filter array
			FilterArray.sort();
			// Add "(All)" in the 0 index
			FilterArray.unshift(Queue.getString("(All)"));
			// Adjust position.
			var oTH = CSSpp.$(oButton.name + "Header");
			var table = CSSpp.$("oScrollTableDiv").getElementsByTagName("TABLE")[0];
			var div = CSSpp.$("oScrollTableDiv");
			var header = CSSpp.$("header");
			oFilterList.style.top = (div.offsetTop + header.offsetHeight) + "px";
			oFilterList.style.margin = "0px";
			oFilterList.style.left = oTH.offsetLeft + div.offsetLeft + "px";
			oFilterList.style.width = oTH.offsetWidth + "px";
			oFilterList.innerHTML = "";
			var lineheight = 0;
			// Add filter item.
			for (var i in FilterArray)
			{
				var li = document.createElement("LI");
				var a = document.createElement("A");
				a.href = "javascript:Queue.ApplyFilter('"+oButton.name+"','"+FilterArray[i]+"')";
				a.innerHTML = FilterArray[i];
				li.appendChild(a);
				// Show filter as long as the mouse is over this li
				li.onmouseover=function(){Queue.ShowFilter();};
				li.onmouseout=function(){Queue.HideFilter();};
				oFilterList.appendChild(li);
			}
			// Adjust position again.
			oFilterList.style.display = "block";
			lineheight = oFilterList.childNodes[0].offsetHeight;
			oFilterList.style.height = lineheight*((oFilterList.childNodes.length > 5)?5 : oFilterList.childNodes.length) + "px";
		}
	},

	HideFilter: function()
	{
		var oFilterList = CSSpp.$("FilterList");
		oFilterList.style.display = "none";
	},

	ShowFilter: function()
	{
		var oFilterList = CSSpp.$("FilterList");
		oFilterList.style.display = "block";
	},

	ApplyFilter: function(sFilterColumn, sFilterBy)
	{
		var oTBodyTag = CSSpp.$("oTableBody");
		
		// Don't start if the table is not ready! IE will crash otherwise.
		if (oTBodyTag && document.all)
		{
			if (oTBodyTag.readyState!="complete")
				return;
		}
		
		if (sFilterBy == Queue.getString("(All)"))
		{
			// Try removing the filter
			delete Queue.m_oFilters[sFilterColumn];
			
		}
		else
		{
			// Add or modify the filter
			Queue.m_oFilters[sFilterColumn]=sFilterBy;
		}

		// Call AddTable to apply the filter
		Queue.AddTable(Queue.m_oTBodyDoc.documentElement, Queue.m_sCurrentSort, Queue.m_sCurrentSortOrder);
		Queue.HideFilter();
		
		var oTH = CSSpp.$(sFilterColumn+"Header")
		if (sFilterBy==Queue.getString("(All)"))
		{
			// Hide the filter button since this filter is not in effect anymore
			Queue.HideFilterButton(oTH);
		}
		else
		{
			// Show the filter button to indicate that this filter is in effect
			Queue.ShowFilterButton(oTH);
		}
		
		// Fix scroll.
		CSSpp.$("oScrollTableDiv").scrollTop = 0;
	},
	
	// Returns translated string from dictionary.xml according to the language configuration
	getString: function(sString)
	{	
		if (!Queue.m_oStringsNode)
		{
			var dictXML = FileIO.loadXML("./xml/dictionary.xml");
			var configXML = Queue.getConfigXML();
			var lang = false;
			if (document.all)
				lang = configXML.selectSingleNode("//lang").text;
			else
				lang = configXML.selectSingleNode("//lang").textContent;
			Queue.m_oStringsNode = dictXML.selectSingleNode("//strings[lang('" + lang + "')]");
			if (!Queue.m_oStringsNode)
				return sString;
		}
		
		var oStringNode = Queue.m_oStringsNode.selectSingleNode("string[@phrase='" + sString + "']");
		if (oStringNode)
		{
			if (document.all)
				return oStringNode.text;
			else
				return oStringNode.textContent;
		}
		else
			return sString;
	},

	// Load the configuration XML and returns the document
	getConfigXML: function()
	{	
		if (!Queue.m_oConfigXMLDoc)
		{
			Queue.m_oConfigXMLDoc = FileIO.loadXML("./xml/rfs_config.xml");
		}
		return Queue.m_oConfigXMLDoc;
	},

	Test: function()
	{
		alert("hello");
	},

	fixHeader: function()
	{
		if (CSSpp.$("header") && CSSpp.$("oScrollTableDiv"))
		{
			var table = CSSpp.$("oScrollTableDiv").getElementsByTagName("TABLE")[0];
			var div = CSSpp.$("oScrollTableDiv");
			var header = CSSpp.$("header");
			table.style.marginTop = header.offsetHeight + "px";
			if (document.all)
				header.style.top = (div.scrollTop - header.offsetHeight) + "px";
			else
				header.style.top = div.scrollTop + "px";
		}
	},
	
	TrimDesc: function(desc, maxcharacters) {
		if (desc.length > maxcharacters)
			desc = desc.substr(0,maxcharacters)+"...";
		return desc;
	},
	
	FormatDateTime: function(datetime, format, dateformat, timeformat) {
		 var sDate = Queue.FormatDate(datetime, dateformat);
		 var sTime = Queue.FormatTime(datetime, timeformat);
		 
		 format=format.replace(/Date/i, sDate);
		 format=format.replace(/Time/i, sTime);
		 return format;
	},
	
	FormatDate: function(datetime, format) {
		var oDate = new Date(datetime);
		
		var sMonth = String(oDate.getMonth()+1);
		if (sMonth.length == 1)
			sMonth = "0" + sMonth;
			
		var sDate = String(oDate.getDate());
		if (sDate.length == 1)
			sDate = "0" + sDate;
		
		var sYear = String(oDate.getFullYear());
		
		// Format the date according to 'format' parameter.
		if (format.match(/yyyy/i))
			format = format.replace(/y+/i,sYear);
		else
			format = format.replace(/y+/i,sYear.substr(2));
		
		format = format.replace(/dd/i,sDate);
		format = format.replace(/mm/i,sMonth);
		return format;	
	},
	
	FormatTime: function(datetime, format) {
		var oDate = new Date(datetime);
		
		var ampm, hour, min;
		hour = oDate.getHours();
		min = String(oDate.getMinutes()+((oDate.getSeconds()<30)?0:1));
		if (min.length == 1)
			min = "0" + min;
		
		// Return military time if 'format' is military
		if (format.match(/military/i))
		{
			return hour+":"+min;
		}
		// Otherwise, format normal time
		ampm = "PM";
		if (hour < 12)
		{
			ampm = "AM";
			if (hour == 0)
				hour = 12;
		}
		else if (hour > 12)
		{
			hour -= 12;
		}

		return hour+":"+min+" "+ampm;
	},
	
	// Translate the content of body tag 
	translate: function()
	{
		var xml = Queue.getConfigXML();
		var xsl = FileIO.loadXML("./xsl/queue.xsl");
		
		// Set the queueID parameter of the transformation with m_sQueueID
		var oQueueuID= xsl.documentElement.selectSingleNode("./xsl:param[@name='queueID']");
		if (document.all)
			oQueueuID.text = Queue.m_sQueueID;
		else
			oQueueuID.textContent = Queue.m_sQueueID;
			
		document.body.innerHTML = FileIO.transformXML(xml, xsl);
		
		// Execute all transformed scripts. (They get ignored otherwise.)
		var s = document.body.getElementsByTagName("SCRIPT");
		for (var i = 0; i < s.length; i++)
			eval(s[i].text);
		
		// If a column is disabled in the configuration, the remaining columns' widths have to be adjusted.
		Queue.RefreshList();
		Queue.AdjustColumnWidth();
		
		// Fix the table header.
		Queue.fixHeader();
		CSSpp.addEvent(CSSpp.$("oScrollTableDiv"), "scroll", Queue.fixHeader);
	},
	
	format: function(e)
	{
		// Grab date/time cells.
		var table = CSSpp.$(e);
		if (table)
		{
			var td = table.getElementsByTagName("TD");
			var cells = new Array();
			for (var i = 0; i < td.length; i++)
			{
				if (/dtime/.test(td[i].className))
				{
					cells.push(td[i]);
				}
			}
			// Format the date/time cells.
			for (var i = 0; i < cells.length; i++)
			{
				if (/^.+?\sdtime\s.+?\s.+?\s.+$/.test(cells[i].className))
				{
					var m = cells[i].className.match(/^.+?\sdtime\s(.+?)\s(.+?)\s(.+)$/);
					if (m)
					{
						var dateformat = m[1];
						var timeformat = m[2];
						var format = m[3];
						var datetime = parseInt(cells[i].innerHTML,10);
						cells[i].innerHTML = Queue.FormatDateTime(datetime, format, dateformat, timeformat);
					}
				}
			}
			
			// Grab trim cells.
			cells = new Array();
			for (var i = 0; i < td.length; i++)
			{
				if (/trim/.test(td[i].className))
					cells.push(td[i]);
			}
			// Format the trim cells.
			for (var i = 0; i < cells.length; i++)
			{
				if (/^.+?\strim\s\d+$/.test(cells[i].className))
				{
					var m = cells[i].className.match(/^.+?\strim\s(\d+)$/);
					if (m)
					{
						var maxchars = parseInt(m[1],10);
						cells[i].innerHTML = Queue.TrimDesc(cells[i].innerHTML, maxchars);
					}
				}
			}
		}
	},
	
	// Edit the current RFS.
	Edit: function() {
		// Make sure a row is selected.
		if (Queue.m_oSelTRNode && !Queue.m_editMode && !Queue.m_sendMode)
		{
			// Grab node.
			var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[contains(@class,'selected')][td[text()='" + Queue.getString("Not Sent") + "']]");
			if (oNodeList.length == 0)
				return;
			if (oNodeList[0] == Queue.m_oSelTRNode)
			{
				// Grab input fields.
				var rfs = CSSpp.$("oRFSView");
				var fields1 = rfs.getElementsByTagName("INPUT");
				var fields2 = rfs.getElementsByTagName("TEXTAREA");
				var fields = new Array();
				for (var i = 0; i < fields1.length; i++)
					fields.push(fields1[i]);
				for (var i = 0; i < fields2.length; i++)
					fields.push(fields2[i]);
				// Enable fields.
				for (var i = 0; i < fields.length; i++)
				{
					fields[i].readOnly = false;
					fields[i].className = Queue.AddClass(fields[i].className, "editmode");
				}
				// Enable/disable buttons.
				if (CSSpp.$("Edit") && CSSpp.$("Save"))
				{
					CSSpp.$("Edit").className = Queue.AddClass(CSSpp.$("Edit").className,"disabled");
					CSSpp.$("Edit").className = Queue.RemoveClass(CSSpp.$("Edit").className,"enabled");
					CSSpp.$("Save").className = Queue.RemoveClass(CSSpp.$("Save").className,"disabled");
					CSSpp.$("Save").className = Queue.AddClass(CSSpp.$("Save").className,"enabled");
				}
				Queue.m_editMode = true;
			}
		}
	},
	
	// Save the current RFS.
	Save: function() {
		// Make sure a row is selected.
		if (Queue.m_oSelTRNode && Queue.m_editMode && !Queue.m_sendMode)
		{
			// Grab node.
			var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[contains(@class,'selected')][td[text()='" + Queue.getString("Not Sent") + "']]");
			if (oNodeList.length == 0)
				return;
			if (oNodeList[0] == Queue.m_oSelTRNode)
			{
				// Grab input fields.
				var rfs = CSSpp.$("oRFSView");
				var fields1 = rfs.getElementsByTagName("INPUT");
				var fields2 = rfs.getElementsByTagName("TEXTAREA");
				var fields = new Array();
				for (var i = 0; i < fields1.length; i++)
					fields.push(fields1[i]);
				for (var i = 0; i < fields2.length; i++)
					fields.push(fields2[i]);
				// Enable fields.
				for (var i = 0; i < fields.length; i++)
				{
					fields[i].readOnly = true;
					fields[i].className = Queue.RemoveClass(fields[i].className, "editmode");
				}
				// Enable/disable buttons.
				if (CSSpp.$("Edit") && CSSpp.$("Save"))
				{
					CSSpp.$("Edit").className = Queue.RemoveClass(CSSpp.$("Edit").className,"disabled");
					CSSpp.$("Edit").className = Queue.AddClass(CSSpp.$("Edit").className,"enabled");
					CSSpp.$("Save").className = Queue.AddClass(CSSpp.$("Save").className,"disabled");
					CSSpp.$("Save").className = Queue.RemoveClass(CSSpp.$("Save").className,"enabled");
				}
				
				// Process the changes.
				var sRFSPath = Queue.m_sQueuePath + "\\" + Queue.m_oSelTRNode.getAttribute("id");
				var xml = FileIO.loadXML(sRFSPath);
				// Update data.
				var phone = xml.selectSingleNode("createRFS/ContactDetail/ContactPhone");
				if (phone && CSSpp.$("ContactPhone"))
				{
					if (document.all)
						phone.text = CSSpp.$("ContactPhone").value;
					else
						phone.textContent = CSSpp.$("ContactPhone").value;
				}
				var email = xml.selectSingleNode("createRFS/ContactDetail/ContactEmail");
				if (email && CSSpp.$("ContactEmail"))
				{
					if (document.all)
						email.text = CSSpp.$("ContactEmail").value;
					else
						email.textContent = CSSpp.$("ContactEmail").value;
				}
				var osysid = xml.selectSingleNode("createRFS/OtherSystemID");
				if (osysid && CSSpp.$("OtherSystemID"))
				{
					if (document.all)
						osysid.text = CSSpp.$("OtherSystemID").value;
					else
						osysid.textContent = CSSpp.$("OtherSystemID").value;
				}
				var ptype = xml.selectSingleNode("createRFS/ProblemType");
				if (ptype && CSSpp.$("ProblemType"))
				{
					if (document.all)
						ptype.text = CSSpp.$("ProblemType").value;
					else
						ptype.textContent = CSSpp.$("ProblemType").value;
				}
				var parea = xml.selectSingleNode("createRFS/ProblemArea");
				if (parea && CSSpp.$("ProblemArea"))
				{
					if (document.all)
						parea.text = CSSpp.$("ProblemArea").value;
					else
						parea.textContent = CSSpp.$("ProblemArea").value;
				}
				var pdesc = xml.selectSingleNode("createRFS/ProblemDescription");
				if (pdesc && CSSpp.$("ProblemDescription"))
				{
					if (document.all)
						pdesc.text = CSSpp.$("ProblemDescription").value;
					else
						pdesc.textContent = CSSpp.$("ProblemDescription").value;
				}
				// Save the changes and update the list.
				FileIO.saveXML(sRFSPath, xml);				
				Queue.RefreshList();
				Queue.m_editMode = false;
			}
		}
	},
	
	// Export selected RFS's.
	Export: function() {
		// Disable buttons and change the cursor
		Queue.SetSendMode(true);
		StatusBar.updateActionStatus("<span class=\"red\">" + APICalls.getString("Export") + "</span>", true);
		
		// Grab selected notes.
		var oNodeList = Queue.m_oTBodyDoc.documentElement.selectNodes("./tr[td/input[@checked]]");
		
		// If nothing is selected, return.
		if (oNodeList.length == 0)
		{
			alert(Queue.getString("NothingSelectedToExport"));
			Queue.SetSendMode(false);
			StatusBar.updateActionStatus(Queue.getString("Status"));
		}
		// Otherwise iterate.
		else
		{
			// Parameter string.
			var paths = [];
			for (var i = 0; i < oNodeList.length; i++)
				paths.push(Queue.m_sQueuePath + oNodeList[i].getAttribute("id"));
			// Export.
			try
			{
				var result = FileIO.execute(Queue.m_exportPath, paths, false, true, {
					poll: 250, timeout: 60 * 1000,
					exitHandler:
						function(exitObj) {
							if (exitObj.failure)
								alert(Queue.getString("ExportFailure"));
							else
								alert(Queue.getString("ExportComplete"));
							// Enable buttons and reset the cursor
							Queue.SetSendMode(false);
							StatusBar.updateActionStatus(Queue.getString("Status"));
						},
					timeoutHandler:
						function(exitObj) {
							alert(Queue.getString("ExportFailure"));
							// Enable buttons and reset the cursor
							Queue.SetSendMode(false);
							StatusBar.updateActionStatus(Queue.getString("Status"));
						}
				});
				if (result.failure)
				{
					alert(Queue.getString("ExportFailure"));
					// Enable buttons and reset the cursor
					Queue.SetSendMode(false);
					StatusBar.updateActionStatus(Queue.getString("Status"));
				}
			}
			catch(e)
			{
				alert(Queue.getString("ExportFailure"));
				// Enable buttons and reset the cursor
				Queue.SetSendMode(false);
				StatusBar.updateActionStatus(Queue.getString("Status"));
			}
		}
	},
	
	// Import RFS's into the queue directory.
	Import: function() {
		// Disable buttons and change the cursor
		Queue.SetSendMode(true);
		StatusBar.updateActionStatus("<span class=\"red\">" + APICalls.getString("Import") + "</span>", true);
		try
		{
			var result = FileIO.execute(Queue.m_importPath, [Queue.m_sQueuePath], false, true, {
				poll: 250, timeout: 60 * 1000,
				exitHandler:
					function(exitObj) {
						if (exitObj.failure)
							alert(Queue.getString("ImportFailure"));
						else
							alert(Queue.getString("ImportComplete"));
						// Enable buttons and reset the cursor
						Queue.SetSendMode(false);
						StatusBar.updateActionStatus(Queue.getString("Status"));
						Queue.RefreshList();
					},
				timeoutHandler:
					function(exitObj) {
						alert(Queue.getString("ImportFailure"));
						// Enable buttons and reset the cursor
						Queue.SetSendMode(false);
						StatusBar.updateActionStatus(Queue.getString("Status"));
					}
			});
			if (result.failure)
			{
				alert(Queue.getString("ImportFailure"));
				// Enable buttons and reset the cursor
				Queue.SetSendMode(false);
				StatusBar.updateActionStatus(Queue.getString("Status"));
			}
		}
		catch(e)
		{
			alert(Queue.getString("ImportFailure"));
			// Enable buttons and reset the cursor
			Queue.SetSendMode(false);
			StatusBar.updateActionStatus(Queue.getString("Status"));
		}
	},
	
	// Set the export path.
	setExportPath: function(path) {
		Queue.m_exportPath = (path.length > 0) ? FileIO.normalizePath(path) : false;
	},
	
	// Set the import path.
	setImportPath: function(path) {
		Queue.m_importPath = (path.length > 0) ? FileIO.normalizePath(path) : false;
	}
}

// Load the body at onload event
CSSpp.addEvent(window, "load", Queue.translate);
CSSpp.addEvent(window, "resize", Queue.OnTableResize);
