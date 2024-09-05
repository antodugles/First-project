// RFS class: Contains functionality for the main RFS page.
//	Author:		Andy Kant (Andrew.Kant@ge.com)
//	Date:		Jun.06.2006
//	Modified:	Dec.07.2006
var RFS = {
	// VARIABLES
	// Button current pressed (if any).
	button: false,
	// Array of recent contacts (up to 15).
	recent: new Array(),
	recentUnsorted: new Array(),
	// Array of permanent contacts.
	permanent: new Array(),
	// Array of combined contacts.
	contacts: new Array(),
	// Suggest is being hovered.
	suggestHover: false,
	
	// SETTINGS (set from XSL transform)
	// XML save path.
	xmlPath: false,
	// Whether to transition to MRFS.
	mrfs: false,
	// Data string for an RFS not being sent.
	notSent: "Not Sent",
	// Use the help tooltip.
	useTooltip: true,
	
	// Mouse coordinates.
	mouseX: 0,
	mouseY: 0,
	
	// Dictionary  node
	m_oDictionaryNode: false,
	m_oLang: false,
	m_oDataLang: false,
	
	// Test SystemID="ILINQTEST1"
	// If set, this SystemID will be used instead of pulling the actual SystemID from qsaconfig.xml file 
	testSystemID: "",
	
	// Capitalize all letters.
	capitalize: function(e) {
		e.value = e.value.toUpperCase();
	},
	
	// Enforce maxlength on textarea.
	maxlength: function(e, length) {
		if (e.value.length > length)
		{
			e.value = e.value.substr(0, length);
		}
		if (e.form.CustomerDescriptionLimit)
			e.form.CustomerDescriptionLimit.value = length - e.value.length;
	},
	
	// Validate the form value according to the specified regular expression.
	validate: function(e, regex) {
		// Test the value.
		var is_valid = regex.test(e.value);
		// Update the class based on the result.
		is_valid ? e.className = "valid" : e.className = "invalid";
		RFS.validateSend();
		return is_valid;
	},
	
	// Validate a list selection.
	validateList: function(e) {
		// Grab the callmode.
		var callmode = false;
		if (RFS.$("SAI"))
		{
			for (var i = 0; i < document.forms["RFS"].Callmode.length; i++)
			{
				if (document.forms["RFS"].Callmode[i].checked)
				{
					callmode = document.forms["RFS"].Callmode[i].id.replace(/Callmode/,"");
					break;
				}
			}
		}
		
		// Test the value.
		var is_valid = false;
		if (callmode && eval("/"+callmode+"$/").test(e.name))
			is_valid = (e.selectedIndex > -1) ? true : false;
		else if (callmode)
			is_valid = true;
		else
			is_valid = (e.selectedIndex > -1) ? true : false;
		
		// Update the class based on the result.
		is_valid ? e.className = "valid" : e.className = "invalid";
		RFS.validateSend();
		return is_valid;
	},

	// Validate the entire form.
	validateAll: function() {
		// Grab all textual form elements.
		var input = document.getElementsByTagName("INPUT");
		var textarea = document.getElementsByTagName("TEXTAREA");
		var e = new Array();
		for (var i in input)
			e.push(input[i]);
		for (var i in textarea)
			e.push(textarea[i]);
		var result = true;
		
		// Run each validation.
		for (var i in e)
		{
			// Execute each onchange validation function.
			try
			{
				if (e[i].onchange && /validate\(this,(.+?)\)/.test(e[i].onchange))
				{
					e[i].onchange();
					result = eval(/validate\(this,(.+?)\)/.exec(e[i].onchange)[1]).test(e[i].value) ? result : false;
				}
			}
			catch (e) { }
		}
		
		// Validate SAI.
		var callmode = false;
		if (RFS.$("SAI"))
		{
			for (var i = 0; i < document.forms["RFS"].Callmode.length; i++)
			{
				if (document.forms["RFS"].Callmode[i].checked)
				{
					callmode = document.forms["RFS"].Callmode[i].id.replace(/Callmode/,"");
					break;
				}
			}
			if (!callmode)
			{
				// Mark elements as invalid.
				var radio = RFS.$("SAI").getElementsByTagName("INPUT");
				for (var i = 0; i < radio.length; i++)
				{
					if (radio[i].parentNode)
						radio[i].parentNode.className = "invalid";
				}
			}
			result = result && callmode;
		}
		
		// Validate PTI.
		if (RFS.$("PTI"))
		{
			if (callmode)
			{
				var list = eval("document.forms[\"RFS\"].CustomerIssue" + callmode);
				var listvalue = RFS.validateList(list);
				if (!listvalue)
				{
					// Mark elements as invalid.
					var lists = RFS.$("PTI").getElementsByTagName("SELECT");
					for (var i = 0; i < lists.length; i++)
					{
						if (lists[i] == list)
							lists[i].className = "invalid";
						else
							lists[i].className = "valid";
					}
				}
				// Mark elements as invalid.
				var lists = RFS.$("PTI").getElementsByTagName("SELECT");
				for (var i = 0; i < lists.length; i++)
				{
					if (lists[i] != list)
						lists[i].className = "valid";
				}
				result = result && listvalue;
			}
			else if (!RFS.$("SAI"))
			{
				var list = eval("document.forms[\"RFS\"].CustomerIssueGeneric");
				var listvalue = RFS.validateList(list);
				if (!listvalue)
				{
					// Mark elements as invalid.
					var lists = RFS.$("PTI").getElementsByTagName("SELECT");
					for (var i = 0; i < lists.length; i++)
					{
						if (lists[i] == list)
							lists[i].className = "invalid";
						else
							lists[i].className = "valid";
					}
				}
			}
			else
			{
				// Mark elements as invalid.
				var lists = RFS.$("PTI").getElementsByTagName("SELECT");
				for (var i = 0; i < lists.length; i++)
				{
					if (lists[i].selectedIndex == -1)
						lists[i].className = "invalid";
				}
				result = false;
			}
		}
		
		// Return result.
		return result;
	},
	
	// Validate the entire form. Updates the style of the send button.
	validateSend: function() {
		// Grab all textual form elements.
		var input = document.getElementsByTagName("INPUT");
		var textarea = document.getElementsByTagName("TEXTAREA");
		var e = new Array();
		for (var i in input)
			e.push(input[i]);
		for (var i in textarea)
			e.push(textarea[i]);
		var result = true;
		
		// Run each validation.
		for (var i in e)
		{
			// Execute each onchange validation function.
			try
			{
				if (e[i].onchange && /validate\(this,(.+?)\)/.test(e[i].onchange))
					result = eval(/validate\(this,(.+?)\)/.exec(e[i].onchange)[1]).test(e[i].value) ? result : false;
			}
			catch (e) { }
		}
		
		// Validate SAI.
		var callmode = false;
		if (RFS.$("SAI"))
		{
			for (var i = 0; i < document.forms["RFS"].Callmode.length; i++)
			{
				if (document.forms["RFS"].Callmode[i].checked)
				{
					callmode = document.forms["RFS"].Callmode[i].id.replace(/Callmode/,"");
					break;
				}
			}
			result = result && callmode;
		}
		
		// Validate PTI.
		if (RFS.$("PTI"))
		{
			if (callmode)
			{
				var list = eval("document.forms[\"RFS\"].CustomerIssue" + callmode);
				result = (list.selectedIndex > -1) ? result : false;
			}
			else if (!RFS.$("SAI"))
			{
				var list = eval("document.forms[\"RFS\"].CustomerIssueGeneric");
				result = (list.selectedIndex > -1) ? result : false;
			}
			else
				result = false;
		}
			
		// Update Send button style.
		var send = RFS.$("Send");
		if (result && /disabled/.test(send.className))
			send.className = send.className.replace("disabled", "enabled");
		else if (!result && /enabled/.test(send.className))
			send.className = send.className.replace("enabled", "disabled");
		
		// Return result.
		return result;
	},
	
	// Reset the form, clearing all data.
	reset: function() {
		// Reset all input fields.
		var input = document.getElementsByTagName("INPUT");
		for (var i = 0; i < input.length; i++)
		{
			if (input[i].type && input[i].type == "text" && input[i].onchange)
			{
				input[i].value = "";
				input[i].className = "valid";
			}
			else if (input[i].type && input[i].type == "radio")
			{
				input[i].checked = false;
				input[i].parentNode.className = "released";
			}
		}
		// Reset all textarea fields.
		var textarea = document.getElementsByTagName("TEXTAREA");
		for (var i = 0; i < textarea.length; i++)
		{
			textarea[i].value = "";
			textarea[i].className = "valid";
		}
		// Reset all select fields.
		var select = document.getElementsByTagName("SELECT");
		for (var i = 0; i < select.length; i++)
		{
			for (var j = 0; j < select[i].options.length; j++)
				select[i].options[j].selected = false;
			select[i].className = "valid";
			select[i].disabled = false;
		}
		// Preload System ID.
		if (RFS.$("SystemID"))
		{
			var systemID = RFS.testSystemID;
			if (systemID == "")
			{
				systemID = APICalls.getSystemID();
				if (systemID == "Agent Not Found" || systemID == "Agent Not Configured")
					systemID = "";
			}
			RFS.$("SystemID").value = systemID;
		}
		// Preload Date/Time of Problem
		if (RFS.$("CustomerDescriptionDateTime"))
			RFS.$("CustomerDescriptionDateTime").value = RFS.getDateTime();
		// Validate the form.
		RFS.validateSend();
	},
	
	// Update contextual help box.
	help: function(title, text, e, override) {
		// Enforce character limit.
		text = text.substr(0, 255);
		// Display help message.
		if (RFS.$("ContextHelp"))
			RFS.$("ContextHelp").innerHTML = "<p class=\"title\">" + title + "</p>\n<p>" + text + "</p>";
		if (override)
			RFS.helpTooltip(title, text, e, false, override);
		else
			RFS.helpTooltip(title, text, e);
	},
	
	// Update contextual help box (from a list). Only needed for IE.
	listHelp: function(e) {
		e.options[e.selectedIndex].onfocus();
	},

	// Update callmode styles.
	toggleCallmode: function(e) {
		for (var i in e.childNodes)
		{
			if (e.childNodes[i].nodeName == "INPUT")
			{
				if (/^Service|Applications$/.test(e.childNodes[i].id.replace(/Callmode/,"")))
				{
					e.className = "pushed";
					var labels = e.parentNode.parentNode.getElementsByTagName("LABEL");
					for (var j in labels)
					{
						if (labels[j] != e)
						{
							labels[j].className = "released";
							var lists = RFS.$("PTI").getElementsByTagName("SELECT");
							for (var k = 0; k < lists.length; k++)
							{
								if (lists[k].name.indexOf(e.childNodes[i].id.replace(/Callmode/,"")) == -1)
									lists[k].className = "valid";
							}
						}
						var lists = RFS.$("PTI").getElementsByTagName("SELECT");
						for (var k = 0; k < lists.length; k++)
						{
							if (lists[k].name.indexOf(e.childNodes[i].id.replace(/Callmode/,"")) > -1)
								lists[k].disabled = false;
							else
								lists[k].disabled = true;
						}
					}
					break;
				}
			}
		}
		RFS.validateSend();
	},
	
	// Update button style while pushed.
	buttonDown: function(e) {
		RFS.button = e;
		if (/disabled/.test(e.className))
			e.className = "button pushed disabled";
		else
			e.className = "button pushed enabled";
	},
	
	// Update button style while hovered and previously pushed.
	buttonOver: function(e) {
		if (RFS.button == e)
		{
			if (/disabled/.test(e.className))
				e.className = "button pushed disabled";
			else
				e.className = "button pushed enabled";
		}
	},
	
	// Update button style while released.
	buttonUp: function(e) {
		RFS.button = false;
		if (/disabled/.test(e.className))
			e.className = "button released disabled";
		else
			e.className = "button released enabled";
	},
	
	// Update button style while it the mouse is away.
	buttonOut: function(e) {
		if (RFS.button == e)
		{
			if (/disabled/.test(e.className))
				e.className = "button released disabled";
			else
				e.className = "button released enabled";
		}
	},
	
	// Force button reset.
	mouseUp: function(e) {
		RFS.button = false;
	},
	
	// Process form.
	process: function() {
		RFS.processMRFS();
	},
	
	// Process form to XML.
	processXML: function() {
		// Grab form.
		var f = document.forms["RFS"];
		var xml = new Array();
		
		// Start root node.
		xml.push("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
		xml.push("<RFS>\n");
		
		// Customer Demographics Interface.
		xml.push("\t<CDI>\n");
		xml.push("\t\t<Last>" + f.Last.value + "</Last>\n");
		xml.push("\t\t<First>" + f.First.value + "</First>\n");
		xml.push("\t\t<Phone>" + f.Phone.value + "</Phone>\n");
		if (f.Ext && f.Ext.value.length > 0)
			xml.push("\t\t<Ext>" + f.Ext.value + "</Ext>\n");
		if (f.Email && f.Email.value.length > 0)
			xml.push("\t\t<Email>" + f.Email.value + "</Email>\n");
		xml.push("\t</CDI>\n");
		
		// Service/Applications Interface.
		var callmode = false;
		if (RFS.$("SAI"))
		{
			xml.push("\t<SAI>\n");
			for (var i = 0; i < f.Callmode.length; i++)
			{
				if (f.Callmode[i].checked)
				{
					callmode = f.Callmode[i].id.replace(/Callmode/,"");
					xml.push("\t\t<Callmode>" + f.Callmode[i].value + "</Callmode>\n");
					break;
				}
			}
			xml.push("\t</SAI>\n");
		}
		
		// Problem Type Interface.
		if (RFS.$("PTI"))
		{
			xml.push("\t<PTI>\n");
			if (!RFS.$("SAI"))
				callmode = "Generic";
			var list = eval("f.CustomerIssue" + callmode);
			for (var i = 0; i < list.options.length; i++)
			{
				if (list.options[i].selected)
					xml.push("\t\t<CustomerIssue>" + list.options[i].value + "</CustomerIssue>\n");
			}
			xml.push("\t</PTI>\n");
		}
		
		// Problem Description Interface.
		if (RFS.$("PDI"))
		{
			var description = f.CustomerDescription.value.replace(/</g,"&lt;").replace(/>/g,"&gt;");
			if (RFS.$("CustomerDescriptionDateTime"))
				description += /^.+$/.test(f.CustomerDescriptionDateTime.value) 
					? "\n\r" + RFS.getString("Date/Time", true) + ": " + f.CustomerDescriptionDateTime.value
					: "";
			xml.push("\t<PDI>\n");
			xml.push("\t\t<CustomerDescription>" + description  + "</CustomerDescription>\n");
			xml.push("\t</PDI>\n");
		}
		
		// Finish up.
		xml.push("</RFS>\n");
		// Debug if ViewXML is present.
		//if (ViewXML)
		//	ViewXML.view(xml.join(""));
		
		// Save document.
		var doc = FileIO.makeDOMDocument(xml.join(""));
		var path = RFS.getSavePath();
		if (path)
		{
			FileIO.saveXML(path, doc);
			alert("RFS saved.");
		}
		else
			alert("Save path does not exist!");
		
		// Update recent contacts.
		RFS.saveRecent({
			last: f.Last.value,
			first: f.First.value,
			phone: f.Phone.value,
			ext: (f.Ext && f.Ext.value.length > 0) ? f.Ext.value : false,
			email: (f.Email && f.Email.value.length > 0) ? f.Email.value : false
		});
		if (path)
			RFS.reset();
	},
	
	// Process form to MRFS.
	processMRFS: function() {
		// Lock interface.
		RFS.setSendMode(true);
		
		// Grab form.
		var f = document.forms["RFS"];
		var xml = new Array();
		
		// Update recent contacts.
		RFS.saveRecent({
			last: f.Last.value,
			first: f.First.value,
			phone: f.Phone.value,
			ext: (f.Ext && f.Ext.value.length > 0) ? f.Ext.value : false,
			email: (f.Email && f.Email.value.length > 0) ? f.Email.value : false
		});
		
		// Start root node.
		xml.push("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
		xml.push("<createRFS>\n");
		
		// System ID.
		var systemID = RFS.testSystemID;
		var agentFailure = false;
		if (systemID == "")
		{
			systemID = APICalls.getSystemID();
			if (systemID == "Agent Not Found" || systemID == "Agent Not Configured")
				agentFailure = true;
		}
		if (/^.+$/.test(systemID) && !agentFailure)
			xml.push("\t<SystemID>" + systemID + "</SystemID>\n");
		else
			xml.push("\t<SystemID />\n");
		var hasOtherSystemID = false;
		if (RFS.$("OtherSystemID") && /^.+$/.test(f.OtherSystemID.value))
		{
			xml.push("\t<OtherSystemID>" + f.OtherSystemID.value + "</OtherSystemID>\n");
			hasOtherSystemID = true;
		}
		else
			xml.push("\t<OtherSystemID />\n");
		// No preprocessing and force polling if the RFS is for another system
		var runProcessors = hasOtherSystemID ? false : true;
		var runForcePoll = runProcessors;
				
		// Service/Applications Interface.
		var callmode = false;
		var MSA="";// SA variable is added to track prolem area. This field will be prepend with description.SPR#
		if (RFS.$("SAI"))
		{
			xml.push("\t<ProblemType>");
			for (var i = 0; i < f.Callmode.length; i++)
			{
				if (f.Callmode[i].checked)
				{
					callmode = f.Callmode[i].id.replace(/Callmode/,"");
					xml.push(f.Callmode[i].value);
			        MSA=f.Callmode[i].value;		
					break;
				}
			}
			xml.push("</ProblemType>\n");
		}
		else
			xml.push("\t<ProblemType />\n");
		
		// Problem Type Interface.
		if (RFS.$("PTI"))
		{
			if (!RFS.$("SAI"))
				callmode = "Generic";
			var list = eval("f.CustomerIssue" + callmode);
			xml.push("\t<ProblemArea>");
			var listinc = 0;
			var	MPA="";  // PA variable is added to track prolem area. This field will be prepend with description.SPR#
			for (var i = 0; i < list.options.length; i++)
			{
				if (list.options[i].selected) 
				{
					if (listinc) xml.push(";");
					xml.push(list.options[i].value);
				    if(MPA!="")   // This Loop added for multi problem area SPR#
				    	MPA=MPA + "," + list.options[i].value;
				    else
				    	MPA=list.options[i].value;
				    
					listinc++;
				}
			}
			xml.push("</ProblemArea>\n");
		}
		else
			xml.push("\t<ProblemArea />\n");
		
		// Customer Demographics Interface.
		xml.push("\t<ContactDetail>\n");
		xml.push("\t\t<FirstName>" + f.First.value + "</FirstName>\n");
		xml.push("\t\t<LastName>" + f.Last.value + "</LastName>\n");
		xml.push("\t\t<ContactPhone>" + f.Phone.value);
		if (f.Ext && f.Ext.value.length > 0)
			xml.push(";x" + f.Ext.value);
		xml.push("</ContactPhone>\n");
		if (f.Email && f.Email.value.length > 0)
			xml.push("\t\t<ContactEmail>" + f.Email.value + "</ContactEmail>\n");
		else
			xml.push("\t\t<ContactEmail />\n");
		xml.push("\t</ContactDetail>\n");
		
		// Fill in some stuff.
		xml.push("\t<ExamNumber />\n");
		xml.push("\t<SeriesNumber />\n");
		xml.push("\t<ImageNumber />\n");
		
		// Problem Description Interface.
		//Problem Description changed as per SPR#
		if (RFS.$("PDI"))
		{
			var description = f.CustomerDescription.value.replace(/</g,"&lt;").replace(/>/g,"&gt;");
			if (RFS.$("CustomerDescriptionDateTime"))
				description += /^.+$/.test(f.CustomerDescriptionDateTime.value) 
					? "\n\r" + RFS.getString("Date/Time", true) + ": " + f.CustomerDescriptionDateTime.value
					: "";
			xml.push("\t<ProblemDescription>" +"ProblemType=" + MSA + ";" + "ProblemArea=" + MPA + ";" +"ProblemDescription=" + description  + "</ProblemDescription>\n");
		}
		else
			xml.push("\t<ProblemDescription />\n");
		
		// Fill in some more stuff.
		xml.push("\t<RequestSource>ContactGE</RequestSource>\n");
		xml.push("\t<Status>" + RFS.notSent + "</Status>\n");
		
		// Finish up.
		xml.push("</createRFS>");
		//if (!/^undefined$/.test(typeof ViewXML))
		//	ViewXML.view(xml.join(""));
		
		// Save document.
		var doc = FileIO.makeDOMDocument(xml.join(""));
		var path = RFS.getSavePath();
		var reset = true;
		if (path)
		{
			FileIO.saveXML(path, doc);
			APICalls.send(path, {preprocess: runProcessors, postprocess: runProcessors, send: !agentFailure}, function(result) {
				if (!agentFailure) {
					var sMsg = "";
					if (result.rfsNumber != "")
					{
						// Show the Reference Number
						sMsg = RFS.getString("Request Submitted") + ".\n";
						sMsg += RFS.getString("Reference Number") + ": " +  result.rfsNumber + "\n\n";
						// Add the after hour message
						if (result.afterHourMsg != "")
							sMsg += result.afterHourMsg;
						else
							sMsg += RFS.getString("OLCWillCall");
						
						if (runForcePoll)
						{
							// HACK: Fixes mysterious IE error by using a timeout.
							setTimeout(function(){
								// Since the request was a success, increase the polling rate using ConnectToGE.exe
								var forcePollResult = APICalls.forcePoll();
								// Show any error message
								if (forcePollResult)
									alert(forcePollResult);
							}, 50);
						}
					}
					else
					{
						// There was an error.  Show the error message
						sMsg = result.errorMsg;
					}

					// If Queue is enabled, show extra message saying that the RFS is saved
					if (RFS.mrfs)
					{
						sMsg += "\n\n" + RFS.getString("SavedMsg");
					}
					else
					{
						// Just delete the RFS
						FileIO.deleteFile(path);
						FileIO.deleteDirectory(path.substr(0, path.lastIndexOf(".xml")));
						// Do not reset at the end, so the user can retry.
						reset = false;
					}
					
					// Reset page.
					if (reset)
						RFS.reset();
					StatusBar.updateActionStatus(RFS.getString("Status"));
					// Unlock interface.
					RFS.setSendMode(false);
					alert(sMsg);
				}
				else
				{
					// Reset page.
					if (reset)
						RFS.reset();
					StatusBar.updateActionStatus(RFS.getString("Status"));
					// Unlock interface.
					RFS.setSendMode(false);
					// Agent failure.
					alert(RFS.getString("Error") + ": " + RFS.getString(systemID) + "\n\n" + RFS.getString("SavedMsg"));
				}
			});
		}
		else
		{
			alert("Save path does not exist!");
			// Unlock interface.
			RFS.setSendMode(false);
			return;
		}
	},
	
	// Find the save path.
	getSavePath: function() {
		// Set shared variables.
		var file = RFS.xmlPath.replace(/\\/g,"/").substr(RFS.xmlPath.replace(/\\/g,"/").lastIndexOf("/")+1);
		var fileRE = eval("/^" + file.replace("*", "(\\d+)").replace(/\./g,"\\.") + "$/i");
		var list = FileIO.listDirectory(RFS.xmlPath.replace(/\\/g,"/").substr(0,RFS.xmlPath.replace(/\\/g,"/").lastIndexOf("/")+1));
		
		// Generate save path.
		if (list)
		{
			var files = new Array();
			for (var i = 0; i < list.files.length; i++)
			{
				var f = list.files[i];
				if (fileRE.test(f))
						files.push(parseInt(f.match(fileRE)[1]));
			}
			files.sort(function(a,b) { return a == b ? 0 : a > b ? 1 : -1; });
			if (files.length == 0)
				files.push(0);
			return list.path + file.replace("*", ""+(++files[files.length-1]));
		}
		else
			return false;
	},
	
	// Load last 15 contacts.
	loadRecent: function() {
		// Load the XML.
		var xml = FileIO.loadXML("./xml/users_recent.xml");
		RFS.recent = new Array();
		if (xml)
		{
			// Grab contacts.
			var contacts = xml.getElementsByTagName("contact");
			for (var i = 0; i < contacts.length && i < 15; i++)
			{
				var last = false;
				var first = false;
				var phone = false;
				var ext = false;
				var email = false;
				for (var j = 0; j < contacts[i].childNodes.length; j++)
				{
					if (/^Last|First|Phone|Ext|Email$/.test(contacts[i].childNodes[j].nodeName))
						eval(contacts[i].childNodes[j].nodeName.toLowerCase() + " = \"" + ((contacts[i].childNodes[j].textContent) ? contacts[i].childNodes[j].textContent : contacts[i].childNodes[j].text) + "\";");
				}
				// Only add the recent contact if they are unique.
				var new_contact = {
					last: last,
					first: first,
					phone: phone,
					ext: ext,
					email: email
				};
				if (!RFS.contactExists(RFS.recent, new_contact))
					RFS.recent.push(new_contact);
			}
		}
		RFS.recentUnsorted = new Array().concat(RFS.recent);
		
		// Bubble sort the contacts.
		for (var i = 0; i < RFS.recent.length; i++)
		{
			for (var j = 0; j < RFS.recent.length; j++)
			{
				if (RFS.bubbleCompare(RFS.recent[i], RFS.recent[j]))
				{
					var tmp = RFS.recent[i];
					RFS.recent[i] = RFS.recent[j];
					RFS.recent[j] = tmp;
				}
			}
		}
	},
	
	// Load permanent contacts.
	loadPermanent: function() {
		// Load the XML.
		var xml = false;
		xml = FileIO.loadXML("./xml/users.xml");
		RFS.permanent = new Array();
		if (xml)
		{
			// Grab contacts.
			var contacts = xml.getElementsByTagName("contact");
			for (var i = 0; i < contacts.length && i < 15; i++)
			{
				var last = false;
				var first = false;
				var phone = false;
				var ext = false;
				var email = false;
				for (var j = 0; j < contacts[i].childNodes.length; j++)
				{
					if (/^Last|First|Phone|Ext|Email$/.test(contacts[i].childNodes[j].nodeName))
						eval(contacts[i].childNodes[j].nodeName.toLowerCase() + " = \"" + ((contacts[i].childNodes[j].textContent) ? contacts[i].childNodes[j].textContent : contacts[i].childNodes[j].text) + "\";");
				}
				// Only add the permanent contact if they are unique.
				var new_contact = {
					last: last,
					first: first,
					phone: phone,
					ext: ext,
					email: email
				};
				if (!RFS.contactExists(RFS.permanent, new_contact))
					RFS.permanent.push(new_contact);
			}
		}
		
		// Bubble sort the contacts.
		for (var i = 0; i < RFS.permanent.length; i++)
		{
			for (var j = 0; j < RFS.permanent.length; j++)
			{
				if (RFS.bubbleCompare(RFS.permanent[i], RFS.permanent[j]))
				{
					var tmp = RFS.permanent[i];
					RFS.permanent[i] = RFS.permanent[j];
					RFS.permanent[j] = tmp;
				}
			}
		}
	},
	
	// Combine contact lists and sort them.
	loadContacts: function() {
		// Load contacts.
		RFS.loadRecent();
		RFS.loadPermanent();
		RFS.contacts = new Array();
		RFS.contacts = RFS.recent.concat(RFS.permanent);
		
		// Bubble sort the contacts.
		for (var i = 0; i < RFS.contacts.length; i++)
		{
			for (var j = 0; j < RFS.contacts.length; j++)
			{
				if (RFS.bubbleCompare(RFS.contacts[i], RFS.contacts[j]))
				{
					var tmp = RFS.contacts[i];
					RFS.contacts[i] = RFS.contacts[j];
					RFS.contacts[j] = tmp;
				}
			}
		};
	},
	
	// Load last 15 contacts.
	saveRecent: function(new_contact) {
		// Fix the unsorted contacts array.
		RFS.loadContacts();
		// Make sure that the contact is not already in the list.
		var contacts = new Array();
		var doSave = false;
		// Is it a new contact?
		if (!RFS.contactExists(RFS.contacts, new_contact))
		{
			var c = new Array(new_contact);
			contacts = c.concat(RFS.recentUnsorted);
			while (contacts.length > 15)
				contacts.pop();
			doSave = true;
		}
		// No, but put them at the top of the list if they're not permanent.
		else if (!RFS.contactExists(RFS.permanent, new_contact))
		{
			var idx = 0;
			for (var i = 0; i < RFS.recentUnsorted.length; i++)
			{
				if ((new_contact.last == RFS.recentUnsorted[i].last) && (new_contact.first == RFS.recentUnsorted[i].first) 
					&& (new_contact.phone == RFS.recentUnsorted[i].phone) && (new_contact.ext == RFS.recentUnsorted[i].ext) 
					&& (new_contact.email == RFS.recentUnsorted[i].email))
					idx = i;
			}
			contacts.push(RFS.recentUnsorted[idx]);
			for (var i = 0; i < RFS.recentUnsorted.length; i++)
			{
				if (i != idx)
					contacts.push(RFS.recentUnsorted[i]);
			}
			doSave = true;
		}
		// Generate and save XML if there is a new recent contact.
		if (doSave)
		{
			var newline = "\r\n";
			var xml = new Array();
			xml.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"+newline);
			xml.push("<recentRFS>"+newline);
			for (var i = 0; i < contacts.length; i++)
			{
				xml.push("\t<contact>"+newline);
				xml.push("\t\t<Last>"+contacts[i].last+"</Last>"+newline);
				xml.push("\t\t<First>"+contacts[i].first+"</First>"+newline);
				xml.push("\t\t<Phone>"+contacts[i].phone+"</Phone>"+newline);
				if (contacts[i].ext) xml.push("\t\t<Ext>"+contacts[i].ext+"</Ext>"+newline);
				if (contacts[i].email) xml.push("\t\t<Email>"+contacts[i].email+"</Email>"+newline);
				xml.push("\t</contact>"+newline);
			}		
			xml.push("</recentRFS>");
			FileIO.saveXML("./xml/users_recent.xml", FileIO.makeDOMDocument(xml.join("")));
		}
	},
	
	// Check if recent contact is already in the contacts list.
	contactExists: function(list, contact) {
		for (var i = 0; i < list.length; i++)
		{
			if ((contact.last == list[i].last) && (contact.first == list[i].first) 
				&& (contact.phone == list[i].phone) && (contact.ext == list[i].ext) 
				&& (contact.email == list[i].email))
				return true;
		}
		return false;
	},
	
	// Bubble sort compare function.
	bubbleCompare: function(one, two) {
		if (one.last != two.last)
			return one.last < two.last;
		else
		{
			if (one.first != two.first)
				return one.first < two.first;
			else
			{
				if (one.phone != two.phone)
					return one.phone < two.phone;
				else
				{
					if (one.ext != two.ext)
						return one.ext < two.ext;
					else
						return one.email < two.email;
				}
			}
		}
	},
	
	// Hide suggest
	hideSuggest: function(keyCode) {
		if (keyCode && keyCode == 9)
		{
			var suggest = RFS.$("suggest");
			if (suggest)
				suggest.style.display = "none";
		}
		else
		{
			var suggest = RFS.$("suggest");
			if (suggest)
				suggest.style.display = "none";
		}
	},
	
	// Delay the launch of the suggestion list.
	suggest: function() {
		if (/^[A-Z-.]*$/i.test(document.forms["RFS"].Last.value))
			setTimeout("RFS.suggestRecent()", 10);
	},
	
	// Suggest recent contact based on last 15 contacts.
	suggestRecent: function() {
		// Find matches.
		RFS.loadContacts();
		var re = eval("/^" + document.forms["RFS"].Last.value + "/i");
		var matches = new Array();
		for (var i in RFS.contacts)
		{
			if (re.test(RFS.contacts[i].last))
			{
				var contact = RFS.contacts[i].last + ", " + RFS.contacts[i].first + " [" + RFS.contacts[i].phone;
				if (RFS.contacts[i].ext)
					contact += "; " + RFS.contacts[i].ext;
				if (RFS.contacts[i].email)
					contact += "; " + RFS.contacts[i].email;
				contact += "]";			
				matches.push({
					id: i,
					contact: contact
				});
			}
		}
		// Show matches.
		var suggest = RFS.$("suggest");
		if (suggest && matches.length > 0)
		{
			// Grab title height.
			var theight = 0;
			var span = RFS.$("CDI").getElementsByTagName("SPAN");
			for (var i = 0; i < span.length; i++)
			{
				if (span[i].className == "title")
				{
					theight = span[i].offsetHeight;
					break;
				}
			}
			// Adjust position.
			if (document.forms["RFS"].Last.className.indexOf("invalid") > -1)
				suggest.style.top = (document.forms["RFS"].Last.offsetTop + document.forms["RFS"].Last.clientHeight + (document.all ? 0 : theight) + 4) + "px";
			else
				suggest.style.top = (document.forms["RFS"].Last.offsetTop + document.forms["RFS"].Last.clientHeight + (document.all ? 0 : theight) + 2) + "px";
			suggest.style.left = (document.forms["RFS"].Last.offsetLeft + 25) + "px";
			if (document.forms["RFS"].Last.className.indexOf("invalid") > -1)
				suggest.style.width = (document.forms["RFS"].Last.offsetWidth - 25 - (document.forms["RFS"].Last.offsetWidth - document.forms["RFS"].Last.clientWidth)/2) + "px";
			else
				suggest.style.width = (document.forms["RFS"].Last.offsetWidth - 25 - (document.forms["RFS"].Last.offsetWidth - document.forms["RFS"].Last.clientWidth)) + "px";
			suggest.innerHTML = "";
			var lineheight = 0;
			// Add contacts.
			for (var i in matches)
			{
				var li = document.createElement("LI");
				var a = document.createElement("A");
				a.href = "javascript:RFS.loadContact(" + matches[i].id + ");";
				a.innerHTML = matches[i].contact;
				li.appendChild(a);
				suggest.appendChild(li);
				lineheight = li.offsetHeight;
			}
			// Adjust position again.
			suggest.style.display = "block";
			for (var i = 0; i < suggest.childNodes.length && i < 1; i++)
				lineheight = suggest.childNodes[i].offsetHeight;
			suggest.style.height = ((matches.length > 5) ? lineheight*5 : lineheight*matches.length) + "px";
		}
	},
	
	// Load contact with specified ID.
	loadContact: function(id) {
		var f = document.forms["RFS"];
		if (RFS.contacts[id])
		{
			f.Last.value = RFS.contacts[id].last;
			f.Last.onchange();
			f.First.value = RFS.contacts[id].first;
			f.First.onchange();
			f.Phone.value = RFS.contacts[id].phone;
			f.Phone.onchange();
			if (f.Ext && RFS.contacts[id].ext)
			{
				f.Ext.value = RFS.contacts[id].ext;
				f.Ext.onchange();
			}
			else if (f.Ext)
			{
				f.Ext.value = "";
				f.Ext.onchange();
			}
			if (f.Email && RFS.contacts[id].email)
			{
				f.Email.value = RFS.contacts[id].email;
				f.Email.onchange();
			}
			else if (f.Email)
			{
				f.Email.value = "";
				f.Email.onchange();
			}
		}
		RFS.hideSuggest();
		RFS.suggestHover = false;
	},
	
	// Update form on load.
	doLoad: function() {
		// Replace body.
		var xml = FileIO.loadXML("./xml/rfs_config.xml");
		var xsl = FileIO.loadXML("./xsl/rfs.xsl");
		document.body.innerHTML = FileIO.transformXML(xml, xsl);
		
		// Update Callmode pushbuttons.
		var e = RFS.$("SAI");
		if (e)
		{
			var callmode = false;
			for (var i = 0; i < document.forms["RFS"].Callmode.length; i++)
			{
				if (document.forms["RFS"].Callmode[i].checked)
				{
					callmode = document.forms["RFS"].Callmode[i].id.replace(/Callmode/,"");
					break;
				}
			}
			if (callmode)
			{
				var radio = e.getElementsByTagName("INPUT");
				for (var i = 0; i < radio.length; i++)
				{
					if (radio[i].id.replace(/Callmode/,"") == callmode)
					{
						radio[i].parentNode.className = "pushed";
						for (var j in radio)
						{
							if (radio[j] != radio[i] && radio[j].parentNode)
								radio[j].parentNode.className = "released";
						}
						break;
					}
				}
			}
		}
		
		// Execute all transformed scripts. (They get ignored otherwise.)
		var s = document.body.getElementsByTagName("SCRIPT");
		for (var i = 0; i < s.length; i++)
			eval(s[i].text);
			
		var tooltipObj = RFS.$("tooltip");
		if (tooltipObj)
		{
			var tooltip = RFS.$("root").removeChild(tooltipObj);
			document.body.appendChild(tooltip);
		}
		
		// Preload System ID.
		if (RFS.$("SystemID"))
		{
			var systemID = RFS.testSystemID;
			if (systemID == "")
			{
				systemID = APICalls.getSystemID();
				if (systemID == "Agent Not Found" || systemID == "Agent Not Configured")
					systemID = "";
			}
			RFS.$("SystemID").value = systemID;
		}
		
		// Preload Date/Time of Problem
		if (RFS.$("CustomerDescriptionDateTime"))
			RFS.$("CustomerDescriptionDateTime").value = RFS.getDateTime();
		
		// Update Send button style.
		RFS.validateSend();
		// Load recent contacts.
		RFS.loadContacts();
	},
	
	// Close the window.
	close: function() {
		// Fool Mozilla/Firefox into thinking this is a popup.
		if (!document.all)
			top.window.open('','_parent','');
		// Close the window.
		top.window.close();
	},
	
	// Update the page title.
	setTitle: function(text) {
		document.title = text;
	},
	
	// Element selector.
	$: function(e) {
		if (typeof e == "string")
			e = document.getElementById(e);
		if (e)
			return e;
		else
			return false;
	},
	
	// Update mouse move coordinates.
	mouseMove: function(e) {
		if (!e)
			e = window.event;
		if (e.pageX && e.pageY)
		{
			RFS.mouseX = e.pageX;
			RFS.mouseY = e.pageY;
		}
		else if (e.clientX && e.clientY)
		{
			if (document.documentElement && document.documentElement.scrollTop)
			{
				RFS.mouseX = e.clientX + document.documentElement.scrollLeft;
				RFS.mouseY = e.clientY + document.documentElement.scrollTop;
			}
			else
			{
				RFS.mouseX = e.clientX + document.body.scrollLeft;
				RFS.mouseY = e.clientY + document.body.scrollTop;
			}
		}		
		if (RFS.$("tooltip"))
		{
			// Grab tooltip.
			var tooltip = RFS.$("tooltip");
			
			// Adjust horizontal position.
			var winwidth = document.documentElement.clientWidth + document.documentElement.scrollLeft;
			var width = RFS.$("tooltip").offsetWidth;
			var left = (RFS.mouseX + 20);
			if (((left + width) > winwidth) && ((width+10) < winwidth))
			{
				tooltip.style.left = "auto";
				tooltip.style.right = 5 + "px";
			}
			else if ((width+10) >= winwidth)
			{
				tooltip.style.left = 5 + "px";
				tooltip.style.right = "auto";
			}
			else
			{
				tooltip.style.left = left + "px";
				tooltip.style.right = "auto";
			}
			
			// Adjust vertical position.
			var winheight = document.documentElement.clientHeight + document.documentElement.scrollTop;
			var height = RFS.$("tooltip").offsetHeight + 5;
			var top = (RFS.mouseY + 5);
			if (((top + height) > winheight) && ((height+10) < winheight))
			{
				tooltip.style.top = "auto";
				tooltip.style.bottom = 5 + height + "px";
			}
			else if ((height+10) >= winheight)
			{
				tooltip.style.top = 5 + "px";
				tooltip.style.bottom = "auto";
			}
			else
			{
				tooltip.style.top = top + "px";
				tooltip.style.bottom = "auto";
			}
		}
	},
	
	// Update the help tooltip.
	helpTooltip: function(title, text, e, problemarea, override) {
		if (RFS.useTooltip || override)
		{
			var tooltip = RFS.$("tooltip");
			if (tooltip) {
				if (title && text)
				{
					var p = tooltip.getElementsByTagName("P");
					for (var i = 0; i < p.length; i++)
					{
						if (p[i].className == "title")
							p[i].innerHTML = title;
						else if (p[i].className == "text")
							p[i].innerHTML = text;
					}
				}
				if (e)
				{
					// If this is a call from the problem areas,
					// make sure that the tooltip matches.
					var check = false;
					if (problemarea)
					{
						var p = tooltip.getElementsByTagName("P");
						for (var i = 0; i < p.length; i++)
						{
							if (p[i].className == "title")
							{
								if (p[i].innerHTML.indexOf(problemarea) > -1)
									check = true;
							}
						}
					}
					// Make sure the title matches or this isn't called from a list.
					if (!problemarea || check)
					{
						// Add event listener.
						tooltip.style.display = "block";
						CSSpp.addEvent(e, "mouseout", RFS.hideTooltip);
					}
				}
			}
		}
	},
	
	// Hide the tooltip.
	hideTooltip: function(e) {
		if (!e)
			e = window.event;
		var ele = false;
		if (e.target)
			ele = e.target;
		else if (e.srcElement)
			ele = e.srcElement;
		// Hide the tooltip.
		RFS.$("tooltip").style.display = "none";
		// Remove event listener.
		if (ele.removeEventListener)
			ele.removeEventListener("mouseout", RFS.hideTooltip, true);
		else if (ele.detachEvent)
			ele.detachEvent("onmouseout", RFS.hideTooltip);
	},
	
	// Returns translated string from dictionary.xml according to the language configuration
	getString: function(sString, datalang)
	{
		datalang = datalang || false;
		if (!RFS.m_oLang || !RFS.m_oDataLang)
		{
			var configXML = FileIO.loadXML("./xml/rfs_config.xml");
			RFS.m_oLang = FileIO.textContent(configXML.selectSingleNode("//lang"));
			RFS.m_oDataLang = FileIO.textContent(configXML.selectSingleNode("//datalang"))
		}		
		
		if (!RFS.m_oDictionaryNode)
		{
			RFS.m_oDictionaryNode = FileIO.loadXML("./xml/dictionary.xml");
		}
		
		var lang = false;
		lang = datalang ? RFS.m_oDataLang : RFS.m_oLang;
		
		var oStringsNode = false;
		oStringsNode = RFS.m_oDictionaryNode.selectSingleNode("//strings[lang('" + lang + "')]");
		if (!oStringsNode)
			return sString;
		
		var oStringNode = oStringsNode.selectSingleNode("string[@phrase='" + sString + "']");
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
	
	// Set the sending mode of the page (i.e. disable everything).
	setSendMode: function(is_sending)
	{
		// Disable the form.
		var input = document.getElementsByTagName("INPUT");
		var textarea = document.getElementsByTagName("TEXTAREA");
		var select = document.getElementsByTagName("SELECT");
		var label = document.getElementsByTagName("LABEL");
		var el = new Array();
		for (var i = 0; i < input.length; i++)
			el.push(input[i]);
		for (var i = 0; i < textarea.length; i++)
			el.push(textarea[i]);
		for (var i = 0; i < select.length; i++)
			el.push(select[i]);
		for (var i = 0; i < label.length; i++)
			el.push(label[i]);
		for (var i in el)
		{
			if (/^label$/i.test(el[i].nodeName))
			{
				if (/^undefined$/i.test(typeof el[i].onclick_backup))
					el[i].onclick_backup = el[i].onclick;
				el[i].onclick = is_sending ? function() { return false; } : el[i].onclick_backup;
			}
			else
			{
				el[i].disabled = is_sending;
			}
			if (/^undefined$/i.test(typeof el[i].backup_cursor))
				el[i].backup_cursor = CSSpp.style(el[i], "cursor") != "auto" ? CSSpp.style(el[i], "cursor") : false;
			if (el[i].backup_cursor)
				el[i].style.cursor = is_sending ? "wait" : el[i].backup_cursor;
		}
		// Update cursor.
		document.body.style.cursor = is_sending ? "wait" : "auto";
	},
	
	// Generate date/time.
	getDateTime: function() {
		var today = new Date();
		var Year = today.getFullYear();
		var leadingZero = function(num) { return num < 10 ? "0" + num : num.toString(); };
		var Month = leadingZero(today.getMonth()+1);
		var Day = leadingZero(today.getDate());
		var Hours = leadingZero(today.getHours());
		var Minutes = leadingZero(today.getMinutes());
		return Month + "/" + Day + "/" + Year + " " + Hours + ":" + Minutes;
	}
}


// Add events (requires CSSpp library).
CSSpp.addEvent(window, "load", RFS.doLoad);
CSSpp.addEvent(document, "mouseup", RFS.mouseUp);
CSSpp.addEvent(document, "mousemove", RFS.mouseMove);