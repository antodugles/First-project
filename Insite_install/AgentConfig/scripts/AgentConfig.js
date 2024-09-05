// This JavaScript file contains functions that are used on AgentConfig.html 
// to control the functionality of the standalone Agent Configuration Tool.
// Date Added: 7/02/07
// Written by: Jung Oh
// Modified by: Jason Malmstadt
  
var AgentConfig = {
	// Static Constants
	agentConfigMap: new AgentConfigMap(),
	directives: new Array(fwEnableText, proxyEnableText, authEnableText),
	sitemapPath: "../Questra/GeHealthcare/Agent/etc/sitemap.xml",
	agentProxyPath: "data/agentProxy.xml",
	metaDataPath: "../Questra/AgentConfigMetaData.xml",
	
	// Fields
	sitemap: false,
	agentProxy: false,
	m_metaDataDoc: false,
	m_oForm: false,	
	changedInputs: false,
	
	// <select> tag for State
	m_stateSelectElem: false,
	
	// <select> tag for ProxyName
	m_proxyNameSelectElem: false,
	
	// Array for Proxy Controls
	proxyControls: false,
	
	// Array for all Proxy Elements
	proxyElements: false,	

	// Array for previously entered proxy values during new proxy creation
	prevProxyValues: new Array(),
	
	// Place holder for current proxy, used to prevent deletion of current proxy.
	currentProxy: false,
	
	// Flags set when new/edit proxy needs to be saved
	unsavedNewProxy: false,
	unsavedEditProxy: false,
	
	// used for debugging
	out: false,
	
	// Initialize the form
	initForm: function() {	
		// Init m_oForm
		this.m_oForm = document.getElementById("oform");
		
		// Load the sitemap xml
		this.sitemap = FileIO.loadRemoteXML(this.sitemapPath);
		
		// If sitemap is not found at default path, try alternate from InstallOptions.xml
		// and try loading using FileIO.loadXML (for local, absolute path).
		if(!this.sitemap){
		  this.sitemapPath = this.getNewSitemapPath();
			this.sitemap = FileIO.loadXML(this.sitemapPath);
		}
		
		// If sitemap is still not found, error and return.
		if (!this.sitemap){
		if (!this.sitemap)
			alert("Error Loading sitemap.xml");
			return;
		}
		
		
		this.changedInputs = new Array();

		// Load the metadata xml
		AgentConfig.m_metaDataDoc = FileIO.loadRemoteXML(this.metaDataPath);
    if (!AgentConfig.m_metaDataDoc)
			alert("Error Loading AgentConfigMetaData.xml");
			
		this.proxyControls = new Array("ProxyName", "ProxyButton1", 
											 	 		 			 "ProxyButton2", "ProxyButton3");

    this.proxyElements = new Array("ProxyIP", "ProxyPort", "AuthEnable", 
											   		  		 "AuthScheme", "AuthUser", "AuthPassword"); 
		
		// Add the continent options
 		AgentConfig.loadContinent();		
		// Add the country options
		AgentConfig.loadCountry();
		// Add the enterprise server options
		AgentConfig.loadEntServer();
		// Add the service center options
		AgentConfig.loadSvcCenter();
		// Add the log level options
		AgentConfig.loadLogLevels();
		
		// Auto format input texts for all letter capitalization.
		// "State" is a special field that it dynamically changes back and forth 
		// between "input" and "select" mode that it's handled in loadState().
		var formatInputs = new Array();
		formatInputs.push(AgentConfig.m_oForm["City"]);
		formatInputs.push(AgentConfig.m_oForm["Institution"]);
		formatInputs.push(AgentConfig.m_oForm["PostalCode"]);
		formatInputs.push(AgentConfig.m_oForm["Department"]);
		formatInputs.push(AgentConfig.m_oForm["Building"]);
		formatInputs.push(AgentConfig.m_oForm["Floor"]);
		formatInputs.push(AgentConfig.m_oForm["Room"]);
		for(var i = 0; i < formatInputs.length; i++)
			AgentConfig.capitalAllCharsInput(formatInputs[i]);

		// Load values from sitemap.xml into form.
		this.loadValues();

		// Once the URL fields are populated, set the correct option in the drop-down.
		this.loadEntServer();

		// Load the proxy name options and select the correct one, if any.
		AgentConfig.loadProxyNames();

		// Switch proxy controls on or off, depending on proxyEnable selector
		this.switchProxyControls(this.m_oForm["ProxyEnable"].value);

		// Lock Proxy Elements
		this.lockProxyElements(true);

		// Reset Proxy Buttons
		this.resetProxyButtons();

		// File Repository and File Watcher folders may be too big for the input fields.
		//  So add a ToolTip message to display the complete folder.
		this.setToolTipFileRepos();
		this.setToolTipFileWatcher();
	},
	
	loadContinent: function() {
  	var oContinentElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("Continent");
		var oContinent = AgentConfig.m_oForm["Continent"];
		
		// Remove the previous selection and keep it for comparison later on
		var oSelections = oContinent.getElementsByTagName("option");
		var oSelection = oSelections[0] || false;
		if (oSelection)
			oContinent.removeChild(oSelection);
			
		// Clear the old continent option list
		while (oContinent.childNodes.length > 0)
			oContinent.removeChild(oContinent.childNodes[0]);
		
		// Add the "<Select Continent>" option
		var oOption = document.createElement("option");
		var textContent = "&lt;Select Continent&gt;";
		oOption.innerHTML = textContent;
		oOption.setAttribute("value", textContent);
		oOption.setAttribute("id", textContent);
		oContinent.appendChild(oOption);

		// Add the continent options
		for (var i=0; i<oContinentElems.length; i++)
		{
			oOption = document.createElement("option");
			textContent = FileIO.textContent(oContinentElems[i]);
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			
		  // Mark the previous selection as selected
			if (oSelection && oSelection.innerHTML == textContent)
				oOption.setAttribute("selected", "true");
			oContinent.appendChild(oOption);
		}	
  },
	
	loadCountry: function() {
		var oContinent = AgentConfig.m_oForm["Continent"];
		var contSelection = oContinent.value;
		
		// Select all the countries of the selected continent
		var oCountryElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("Country[@continent='" + contSelection + "']/Ct");
		
		// Keep the previous selection for comparison later on
		var oCountry = AgentConfig.m_oForm["Country"];
		var oSelections = oCountry.getElementsByTagName("option");
		var oSelection = oSelections[0] || false;
		
		// Clear the old country option list
		while (oCountry.childNodes.length > 0)
			oCountry.removeChild(oCountry.childNodes[0]);
			
		var oOption = document.createElement("option");
		var textContent = "&lt;Select Country&gt;";
		oOption.innerHTML = textContent;
		oOption.setAttribute("value", textContent);
		oOption.setAttribute("id", textContent);
		oCountry.appendChild(oOption);
		
		// Add the country options
		for (var i=0; i<oCountryElems.length; i++)
		{
			oOption = document.createElement("option");
			textContent = FileIO.textContent(oCountryElems[i]);
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			// Mark the previous selection as selected
			if (oSelection && oSelection.innerHTML == textContent)
				oOption.setAttribute("selected", "true");
			oCountry.appendChild(oOption);
		}
		
		// Add the state options
		AgentConfig.loadState();
	},
	
	loadState: function() {
		var oCountry = AgentConfig.m_oForm["Country"];
		var countrySelection = oCountry.value;
		
		// Select all the states of the selected country
		var oStateElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("State[@country='" + countrySelection + "']/St");
		// AgentConfig.m_oForm["State"] didn't work in IE because <select> and <input> elements are swapped dynamically.  Thereform getElementById("State") is used.
		var oState = document.getElementById("State");
		
		// If states for the selected country are defined in the metadata xml,
		if (oStateElems.length > 0)
		{
			// If the "State" element is not "select" element currently, replace the element with the stored "select" element.
			if (oState.tagName != "SELECT")
			{
				oState.parentNode.replaceChild(AgentConfig.m_stateSelectElem, oState);
				oState = AgentConfig.m_stateSelectElem;
			}
			
			// Keep the previous selection for comparison later on
			var oSelections = oState.getElementsByTagName("option");
			var oSelection = oSelections[0] || false;
			
			// Clear the old option list
			while (oState.childNodes.length > 0)
				oState.removeChild(oState.childNodes[0]);
				
			var oOption = document.createElement("option");
			var textContent = "&lt;Select State&gt;";
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			oState.appendChild(oOption);
			
			// Add the state options
			for (var i=0; i<oStateElems.length; i++)
			{
				oOption = document.createElement("option");
				textContent = FileIO.textContent(oStateElems[i]);
				oOption.innerHTML = textContent;
				oOption.setAttribute("value", textContent);
				oOption.setAttribute("id", textContent);
				// Mark the previous selection as selected
				if (oSelection && oSelection.innerHTML == textContent)
					oOption.setAttribute("selected", "true");
				oState.appendChild(oOption);
			}
		}
		else
		{
			// If the "State" element is not "input" element currently, 
			if (oState.tagName != "INPUT")
			{
				// Store the "select" element for later use
				AgentConfig.m_stateSelectElem = oState;
				// Create the input text element and replace with the "select" element
				oState = document.createElement("input");
				oState.type = "text";
				oState.name = "State";
				oState.id = "State";
				oState.size = 20;
				oState.onchange = function(){AgentConfig.valueChanged('state');AgentConfig.capitalAllCharsInput(this);};
				oState.onkeyup = function(){AgentConfig.valueChanged('state');AgentConfig.capitalAllCharsInput(this);};
				// Copy the selected state to the input text
				var oSelections = AgentConfig.m_stateSelectElem.getElementsByTagName("option");
				var oSelection = oSelections[0] || false;
				if (oSelection && oSelection.innerHTML != "&lt;Select State&gt;")
					oState.setAttribute("value", AgentConfig.capitalAllChars(oSelection.innerHTML));
				AgentConfig.m_stateSelectElem.parentNode.replaceChild(oState, AgentConfig.m_stateSelectElem);
			}
		}
	},
	
	loadEntServer: function() {
		// Select all the enterprise servers in the metadata xml
		var oEntServerElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("EntServers/Server");
		// Keep the previous selection for comparison later on
		var oEntURL = AgentConfig.m_oForm["UserEntURL"];
		var oEntServer = AgentConfig.m_oForm["EntServer"];
		
		// Clear any existing options
		while (oEntServer.childNodes.length > 0)
			oEntServer.removeChild(oEntServer.childNodes[0]);
			
		// Add the server options
		var bSelectionFound = false;
		for (var i=0; i<oEntServerElems.length; i++)
		{
			var oOption = document.createElement("option");
			var name = oEntServerElems[i].getAttribute("name");
			oOption.setAttribute("value", name);
			oOption.setAttribute("id", name);
   		oOption.setAttribute("id", name);
			oOption.innerHTML = name;
			if (name != "OTHER")
			{
				var entURL = FileIO.textContent(oEntServerElems[i].selectSingleNode("EntURL"));
				// Mark the previous selection as selected
				if (oEntURL && oEntURL.value == entURL)
				{
					oOption.setAttribute("selected", "true");
					bSelectionFound = true;
				}
			}
			else
			{
				// If the previous selection is not one of the server options, just select OTHER
				if (!bSelectionFound)
				{
					oOption.setAttribute("selected", "true");
					var oTunURL = AgentConfig.m_oForm["UserTunURL"];
					// Save the current user URLs, so they can be restored if the selection is changed back to OTHER later. 
					AgentConfig.m_oForm["LocalUserEntURL"].value = oEntURL.value;
					AgentConfig.m_oForm["LocalUserTunURL"].value = oTunURL.value;
					// Writable only if the user level is "M"
					//if (AgentConfig.m_oForm["UserLevel"].value == "M")
					//{
						oEntURL.readOnly = false;
						oTunURL.readOnly = false;
					//}
				}
			}
			oEntServer.appendChild(oOption);
		}
	},
	
	// Fill the server URL fields when Enterprise Server selection is changed.
	fillURLFields: function() {
		var sel = AgentConfig.m_oForm["EntServer"];
		var entURL = AgentConfig.m_oForm["UserEntURL"];
		var tunURL = AgentConfig.m_oForm["UserTunURL"];
		if (sel.value != "OTHER")
		{
			var oServer = AgentConfig.m_metaDataDoc.documentElement.selectSingleNode("EntServers/Server[@name='" + sel.value + "']");
			entURL.value = FileIO.textContent(oServer.selectSingleNode("EntURL"));
			tunURL.value = FileIO.textContent(oServer.selectSingleNode("TunURL"));
			entURL.readOnly = true;
			tunURL.readOnly = true;
		}
		else
		{
			entURL.value = AgentConfig.m_oForm["LocalUserEntURL"].value;
			tunURL.value = AgentConfig.m_oForm["LocalUserTunURL"].value;
			entURL.readOnly = false;
			tunURL.readOnly = false;
		}
	},
	
	loadSvcCenter: function() {
		var oContinent = AgentConfig.m_oForm["Continent"];
		contSelection = oContinent.value;
		
		// Select all the service centers of the selected continent
		var oSvcCenterElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("SvcCenter[contains(@continent, '" + contSelection + "')]/Svc");
		
		// Keep the previous selection for comparison later on
		var oSvcCenter = AgentConfig.m_oForm["SvcCenter"];
		var oSelections = oSvcCenter.getElementsByTagName("option");
		var oSelection = oSelections[0] || false;
		// Clear the old option list
		while (oSvcCenter.childNodes.length > 0)
			oSvcCenter.removeChild(oSvcCenter.childNodes[0]);
			
		// If there are no choices for the selected continent, add "OTHERS".  
		if (oSvcCenterElems.length == 0)
		{
			oSvcCenterElems = AgentConfig.m_metaDataDoc.documentElement.selectNodes("SvcCenter[contains(@continent, 'OTHERS')]/Svc");
		}

		var oOption, textContent;
		
		// Add "<Select>" option only when there are more than one choice.
		if (oSvcCenterElems.length > 1)
		{
			// Add "<Select>" option
			oOption = document.createElement("option");
			textContent = "&lt;Select&gt;";
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			oSvcCenter.appendChild(oOption);
		}
		
		// Add the options
		for (var i=0; i<oSvcCenterElems.length; i++)
		{
			oOption = document.createElement("option");
			textContent = FileIO.textContent(oSvcCenterElems[i]);
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			// Mark the previous selection as selected
			if (oSelection && oSelection.innerHTML == textContent)
				oOption.setAttribute("selected", "true");
			oSvcCenter.appendChild(oOption);
		}
	},
	
	loadLogLevels: function() {
	
		// Select all the log level options
		var oLogLevelOptions = AgentConfig.m_metaDataDoc.documentElement.selectNodes("LogLevels/Level");
		
		// Keep the previous selection for comparison later on
		var oLogLevel = AgentConfig.m_oForm["LogLevel"];
		var oSelections = oLogLevel.getElementsByTagName("option");
		var oSelection = oSelections[0] || false;
		
		// Clear the old country option list
		while (oLogLevel.childNodes.length > 0)
			oLogLevel.removeChild(oLogLevel.childNodes[0]);
			
		// Add the country options
		for (var i=0; i<oLogLevelOptions.length; i++)
		{
			oOption = document.createElement("option");
			textContent = FileIO.textContent(oLogLevelOptions[i]);
			oOption.innerHTML = textContent;
			oOption.setAttribute("value", textContent);
			oOption.setAttribute("id", textContent);
			// Mark the previous selection as selected
			if (oSelection && oSelection.innerHTML == textContent)
				oOption.setAttribute("selected", "true");
			oLogLevel.appendChild(oOption);
		}
	},
	
  // Load the proxy names from agentProxy.xml to the drop-down
	loadProxyNames: function() {	  	
		// Load the saved proxy configurations xml
		this.agentProxy = FileIO.loadRemoteXML(this.agentProxyPath);
		if (!this.agentProxy)
			alert("Error Loading agentProxy.xml");
			
		// ProxyName is either a <select> or <input> element, swapped dynamically.  
		// Therefore, getElementById("ProxyName") is used instead m_oForm["ProxyName"] 
		var proxyName = document.getElementById("ProxyName");		
		
		// If the "ProxyName" element is not "select" element currently, 
  	if (proxyName.tagName != "SELECT"){ 
			// Replace the element with the stored proxy name select element
			proxyName.parentNode.replaceChild(this.m_proxyNameSelectElem, proxyName);
  		proxyName = this.m_proxyNameSelectElem;
  	}
		
		// Remove all existing options from the list, if any.
		while (proxyName.childNodes.length > 0)
			proxyName.removeChild(proxyName.childNodes[0]);
		
		// Select all the proxy names in AgentProxy
		var proxyNames = this.agentProxy.documentElement.selectNodes("proxy/name");
		
		// Get all proxy configuiration values currently in the form
		var ip = this.m_oForm["ProxyIP"].value;
		var port = this.m_oForm["ProxyPort"].value;
		var authEnable = (this.m_oForm["AuthEnable"].value == 1 ? "true" : "false");
		var authScheme = this.m_oForm["AuthScheme"].value;
		var authUser = this.m_oForm["AuthUser"].value;
		var authPassword = this.m_oForm["AuthPassword"].value;
		
		var noProxyInForm = (ip == "");
		
		// If no values exist for ip & port, add a "Create/Select Proxy" Element
		if (noProxyInForm){
		  option = document.createElement("option");
			textContent = "Create/Select Proxy";
  		option.innerHTML = textContent;
  		option.setAttribute("value", textContent);
  		option.setAttribute("id", textContent);
			option.setAttribute("selected", "true");
			proxyName.appendChild(option);
		} 
		
		var found = false;
		
		// If there are proxy values in the form, and proxies in agentProxy
		if (proxyNames && proxyNames.length>0){
		
			// For each stored proxy...
  		for (i=0; i<proxyNames.length; i++){
			  
				// Add each proxy name options to the select element.
    		option = document.createElement("option");
    		textContent = FileIO.textContent(proxyNames[i]);
    		option.innerHTML = textContent;
    		option.setAttribute("value", textContent);
    		option.setAttribute("id", textContent);
				
  			// Compare saved proxy values to proxy values in form 
				var proxy = proxyNames[i].parentNode;
  
        // Get all proxy configuration values
  			var savedIP = FileIO.textContent(proxy.selectSingleNode("ip"));
        var savedPort = FileIO.textContent(proxy.selectSingleNode("port"));
        var savedEnable = FileIO.textContent(proxy.selectSingleNode("auth/enabled"));
        var savedScheme = FileIO.textContent(proxy.selectSingleNode("auth/scheme"));
  			var savedUser = FileIO.textContent(proxy.selectSingleNode("auth/user"));	
  			var savedPassword = FileIO.textContent(proxy.selectSingleNode("auth/password"));
  
  			// Compare form values to saved values
				var b = (ip == savedIP && port == savedPort && authEnable == savedEnable
				          && authScheme == savedScheme && authUser == savedUser);
  			
  			// If all fields match...
				if(b){
					found = true;
					this.currentProxy = proxy;
					option.setAttribute("selected", true);
				} 
    		
  			// Append the option to select element
  			proxyName.appendChild(option);
    	}
		}	
					
		// If no match was found in agentProxy, but there *is* a configuration 
		// in the form, name the current configuration AUTOSAVEx, create an entry 
		// in proxy name the drop-down, and save it to agentProxy
		if(!found && !noProxyInForm){
			// Get autosave number from agentProxy
			var autosave = this.agentProxy.selectSingleNode("//autosave");
			var i;
			if (!autosave){
				autosave = this.agentProxy.createElement('autosave');
				this.agentProxy.documentElement.appendChild(autosave);
				i = this.agentProxy.selectNodes("//proxy[contains(name, 'AUTOSAVE')]").length+1;
 			} else {
			  i = FileIO.textContent(autosave);
				while(autosave.childNodes.length>0)
				  autosave.removeChild(autosave.childNodes[0]);
				i++;
			}
			
			autosave.appendChild(this.agentProxy.createTextNode(i));
			
			// Add "AUTOSAVEx" option to proxyName list 
			option = document.createElement("option");
			textContent = "AUTOSAVE"+i;
			option.innerHTML = textContent;
			option.setAttribute("value", textContent);
			option.setAttribute("id", textContent);
			option.setAttribute("selected", "true");
			proxyName.appendChild(option);
			
			this.setProxyMessage('The current proxy settings have been automatically <br />' +
			                     'saved to the saved proxy list as "' + textContent +'".'); 
			
			// Save AUTOSAVEx proxy to agentProxy
			this.saveProxy(true);
		}
		
		this.resetProxyButtons();
	},
		
	capitalFirstChars: function (text) {
		// LowerCase everything first
		text = text.toLowerCase();
		// UpperCase only the first character of each word
		return text.replace(/\b([a-z])/g, function(firstchar){return firstchar.toUpperCase();});
	},
	
	capitalFirstCharsInput: function (input) {
		input.value = AgentConfig.capitalFirstChars(input.value);
	},
	
	capitalAllChars: function (text) {
		return text.toUpperCase();
	},
	
	capitalAllCharsInput: function (input) {
		input.value = input.value.toUpperCase();
	},
	 
	valueChanged: function(i){
		this.changedInputs[i] = this.agentConfigMap[i];
		
		// If the hidden proxyServer field has changed,
		if (i == "proxyServer"){
		  
			// If ProxyIP and ProxyPort are empty, make ProxyServer empty.
			if(this.m_oForm["ProxyIP"].value == "" && this.m_oForm["ProxyPort"].value == ""){
			  this.m_oForm[this.agentConfigMap.proxyServer.htmlName].value = "";
			} else {			
  			// otherwise, update its value to "<ProxyIP>:<ProxyPort>"
  			this.m_oForm[this.agentConfigMap.proxyServer.htmlName].value = 
  			  this.m_oForm["ProxyIP"].value + ":" + this.m_oForm["ProxyPort"].value;
			}
		}
	},

	// Update tooltip contents for File Repository input field.
	setToolTipFileRepos: function(){
		this.m_oForm["FileRepository"].title = this.m_oForm["FileRepository"].value;
	},

	// Update tooltip contents for File Watcher input field.
	setToolTipFileWatcher: function(){
		this.m_oForm["WatchDir"].title = this.m_oForm["WatchDir"].value;
	},

	continentChanged: function(){
    this.loadCountry();
		AgentConfig.loadSvcCenter();
		AgentConfig.valueChanged('continent');
		AgentConfig.valueChanged('serviceCenter');
	},
	
	submitForm: function(){
	  
		if (AgentConfig.validate()){
		  AgentConfig.save();
			location.reload(true);
		}	  
	},
	
	validate: function() {
	
		var bSubmit = true;
		var checkInputs = new Array();
		
		// Add all the inputs to validate in the array
		checkInputs.push(AgentConfig.m_oForm["DeviceName"]);
		var oCRMNum = AgentConfig.m_oForm["SerialNumber"];
		
		if (oCRMNum.length > 0)
			checkInputs.push(oCRMNum[0]);
		else
			checkInputs.push(oCRMNum);
		
		checkInputs.push(AgentConfig.m_oForm["Continent"]);
		checkInputs.push(AgentConfig.m_oForm["Country"]);
		checkInputs.push(AgentConfig.m_oForm["State"]);
		checkInputs.push(AgentConfig.m_oForm["City"]);
		checkInputs.push(AgentConfig.m_oForm["Institution"]);
		checkInputs.push(AgentConfig.m_oForm["SvcCenter"]);
		checkInputs.push(AgentConfig.m_oForm["UserEntURL"]);
		checkInputs.push(AgentConfig.m_oForm["UserTunURL"]);
		checkInputs.push(AgentConfig.m_oForm["ProxyIP"]);
		checkInputs.push(AgentConfig.m_oForm["ProxyPort"]);
		
		// First, reset all the invalidated (red) labels
		for (var i = 0; i < checkInputs.length; i++)
			checkInputs[i].parentNode.previousSibling.className = "";
			
		// Remove proxy checks if it's disabled
		if (AgentConfig.m_oForm["ProxyEnable"].value == "0")
		{
			checkInputs.pop();
			checkInputs.pop();
		}
		
		for (var i = 0; i < checkInputs.length; i++)
		{
			if (checkInputs[i].value == "" || checkInputs[i].value.match(/^unknown|^default/i) || checkInputs[i].value.match(/^&lt;Select/))
			{
				bSubmit = false;
				// This will change the label to red
				checkInputs[i].parentNode.previousSibling.className = "invalid";
			}
		}
		
		// Validate all the fields that require additional messages if validation fails.
		checkInputs = new Array();
		var additionalMsgs = new Array();
		checkInputs.push(function() {return AgentConfig.checkLatitude();});
		checkInputs.push(function() {return AgentConfig.checkLongitude();});
		for (var i = 0; i < checkInputs.length; i++)
		{
			var result = checkInputs[i]();
			if (result)
			{
				bSubmit = false;
				additionalMsgs.push("\n" + result);
			}
		}
			
		if (!bSubmit)
			alert("Please enter or fix the required fields and try again." + ((additionalMsgs.length > 0) ? additionalMsgs.join() : ""));
		else
			document.body.style.cursor='wait';
		return bSubmit;
	},
	
	checkLatitude: function () {
		var input = AgentConfig.m_oForm["Latitude"];
		// Reset the label color
		input.parentNode.previousSibling.className = "";
		
		// Empty is OK
		if (input.value == "")
			return;
		
		//  -90 to 90 is OK
		if (!isNaN(input.value))
		{
			var value = parseFloat(input.value);
			input.value = value.toFixed(2);  // Format to 2 decimal points.
			if (input.value >= -90 && input.value <= 90)
				return;
		}

		// If an invalid value is entered,
		// This will change the label to red
		input.parentNode.previousSibling.className = "invalid";
		// Return the invalidated message
		return "Latitude has to be a decimal number between -90 and 90.";
	},
	
	checkLongitude: function () {
		var input = AgentConfig.m_oForm["Longitude"];
		// Reset the label color
		input.parentNode.previousSibling.className = "";
		
		// Empty is OK
		if (input.value == "")
			return;
		
		//  -180 to 180 is OK
		if (!isNaN(input.value))
		{
			var value = parseFloat(input.value);
			input.value = value.toFixed(2);  // Format to 2 decimal points.
			if (input.value >= -180 && input.value <= 180)
				return;
		}
		
		// If an invalid value is entered,
		// This will change the label to red
		input.parentNode.previousSibling.className = "invalid";
		// Return the invalidated message
		return "Longitude has to be a decimal number between -180 and 180.";
	},
	
	save: function(){
		
		// Save Proxy information, if necessary.
		if(this.unsavedNewProxy){this.saveProxy(true);}
		if(this.unsavedEditProxy){this.saveProxy(false);} 
		
		// Iterate through changed inputs
		for (i in this.changedInputs){
			var x = this.changedInputs[i];
			
			// Get the element in the xml dom
			var element = this.sitemap.documentElement.selectNodes("replace/text[@symbol='" + x.xmlName + "']")[0];
			
  		// If element does not exist in sitemap.xml, create it.
			if (element == null){
				element = this.sitemap.createElement('text');
  			element.setAttribute("symbol", x.xmlName);
				element.setAttribute("userconfig", "true");
				this.sitemap.documentElement.selectNodes("replace")[0].appendChild(element);
 			} 

			// Remove all child nodes
      while (element.childNodes.length > 0)
			  element.removeChild(element.childNodes[0]);
			
			// Get the value from the HTML form and store it as a text node.
			var value = this.sitemap.createTextNode(this.m_oForm[x.htmlName].value);

 			// Add value as a child text node
			element.appendChild(value);
		}
		
		// Enable/Disable Filewatcher		
		this.saveEnableDisable(this.m_oForm["WatchEnable"].value, fwEnableText);
		
		// Enable/Disable Proxy
		this.saveEnableDisable(this.m_oForm["ProxyEnable"].value, proxyEnableText);
		
		// Enable/Disable Proxy Authentication
		var authEnable = this.m_oForm["AuthEnable"].value;
		this.saveEnableDisable(authEnable, authEnableText);
		
		// If Authentication is disbaled (0/uncommented), AuthScheme MUST BE ENABLED (1/commented out)
		// Otherwise, AuthScheme is disabled (0/uncommented) iff AuthScheme==NONE
		var authSchemeEnable = (authEnable==0 ? 1 : (this.m_oForm["AuthScheme"].value=="NONE" ? 0 : 1));	
		this.saveEnableDisable(authSchemeEnable, authSchemeText);
		
		//Save changes and alert user.
		var saved = FileIO.saveXML(this.sitemapPath, this.sitemap);
		if(!saved){
		  alert("Unknown Error while saving to sitemap.xml. Configuration not saved.");
			return;
		}
		
		var scriptsRun = this.saveScripts();
		if(!scriptsRun)
		  alert("Sitemap.xml updated, but config scripts failed. Configuration not saved.");
    
    if(saved && scriptsRun)
		  alert("Configuration Saved.");
  },
	
	/**
	 * Comments or uncomments nodes in the sitemap based on the value of an
	 * Enable/Disable drop-down selector in the form.
	 *
	 * @param enabled 0 if disabled, 1 if enabled
	 * @param nodeValues An array containing the node values of the nodes to be 
	 *                   commented/uncommented
	 */
	saveEnableDisable: function(enabled, nodeValues) {
		// If selection is "Disable"
		if (enabled == 0){
			// Uncomment the commented-out delete directive(s), if any
			for(i=0; i<nodeValues.length; i++){
				var comment = this.sitemap.selectSingleNode("//delete/comment()[contains(.,'>"+nodeValues[i]+"<')]");
				if (comment)
				  this.uncommentNode(comment);
			}		
		// Otherwise, if selection is "Enable"
		} else if (enabled == 1){
			// Comment out the Delete directive(s), if any
			for(i=0; i<nodeValues.length; i++){
			  var node = this.sitemap.selectSingleNode("//delete/*[./text()='"+nodeValues[i]+"']");
				if (node)
				  this.commentOutNode(node);
			} 
		}	
	},
	
	/**
	 * Reads site map delete directives. Returns true if all directives exist 
	 * as xml nodes (that is, not commented out)  
	 *
	 * @param nodeValues An array containing the node values of the nodes to be 
	 *                   checked
	 * @return enabled Boolean that is true if all directives indicate fetaure is 
	 *                 enabled, false otherwise.
	 */
	isEnabled: function(nodeValues) {
		for(i=0; i<nodeValues.length; i++){
			// If node (not comment) is found with matching string, the feature is disabled 
			var node = this.sitemap.selectSingleNode("//delete/*[./text()='"+nodeValues[i]+"']");
			if (node){
				return false;
			}
		}
		// Otherwise, the feature is enabled.
		return true;	
	},
	
	// Replaces an XML DOM node with an XML comment Node whose value is the 
	// XML of the node to be replaced.
	commentOutNode: function(node){	
		var str = this.nodeToString(node);
		str = str.replace(/^<|>$/g, '');
		var comment = node.ownerDocument.createComment(str);
		node.parentNode.replaceChild(comment, node);
	},
	
	// This function is based on FileIO.makeDOMString(). The original truncated
	// the last two characters in IE to truncate a newline. This modified version 
	// uses regular expressions to truncate leading and trailing whitespace.
	nodeToString: function(xml_doc) {
		if (document.implementation && document.implementation.createDocument)
		{
			var serialize = new XMLSerializer();
			var str = serialize.serializeToString(xml_doc);
		  return str.replace(/^\s+|\s+$/g, '');
		}
		else if (window.ActiveXObject)
		{			
			var str = xml_doc.xml;
			return str.replace(/^\s+|\s+$/g, '');
		}
		return false;
	},
	
	// Uncomments an XML DOM node that has been commented out.
	// Node should have no attributes and a single text node child.
	uncommentNode: function(comment){		
		var node = FileIO.textContent(comment);
		var openTag = node.match(/^.+?>/).toString();
		var closeTag = node.match(/<\/.+?$/).toString();
		var tagName = openTag.substring(0, openTag.length-1);	
		
		var text = node.replace(openTag, "");
		text = text.replace(closeTag, "");

		newNode = comment.ownerDocument.createElement(tagName);
    newText = comment.ownerDocument.createTextNode(text);
    newNode.appendChild(newText);
    comment.parentNode.replaceChild(newNode, comment);
	},
	
	loadValues: function(){
	  
		var docElem = AgentConfig.sitemap.documentElement;
		var x, node, xmlValue, field;
		
		// Iterate through the objects in agentConfigMap
		for (i in this.agentConfigMap) {
	
		  // Skip the state, country, and serviceCenter objects. 
			// They are handled immediately following the continent object.
			if (i == "state" || i == "country" || i == "serviceCenter") {continue;}
			
			// Use the key (i) to get the input object in the agentConfigMap 
			x = this.agentConfigMap[i];
			
			// Get the xml node
			node = docElem.selectNodes("replace/text[@symbol='" + x.xmlName + "']")[0];
			
			// Store the value of the node's userconfig attribute, if any, in the agentConfigMap 
			var userconfigAtt = node.selectSingleNode("@userconfig");
		  if (userconfigAtt){
			  x.userconfig = (FileIO.textContent(userconfigAtt) == "true" ? true : false);
			}
			
			// Set the field to disabled unless userconfig is true
			this.m_oForm[x.htmlName].disabled = !x.userconfig;
			
			// Set xmlValue to the node value if the node exists, or an empty string if not.
			xmlValue = FileIO.textContent(node);
				
			// If the current object is the continent...
			if (x == this.agentConfigMap.continent){
				
				// ...set the continent and all dependent inputs (country, state, service center) all at once.
				this.loadContinentValue(xmlValue);
 				
			} else {
			  
				// Otherwise, simply set the value...
				var formInput = this.m_oForm[x.htmlName];				
				
				// For text input fields, set the value attribute
				if (formInput.tagName == "INPUT"){
				  formInput.value = xmlValue;
				
				// For select fields, get the correct option and set the selected attribute to true 
				} else if (formInput.tagName == "SELECT"){
				  field = document.getElementById(xmlValue);
					if(field)
					  field.setAttribute("selected", "true");
				}
			}
		}
		
		// Get value from hidden ProxyServer field. 
		var pValue = this.m_oForm[this.agentConfigMap.proxyServer.htmlName].value;
		
		var splitResult = new Array ("","");
		
		// Split proxyServer into IP and Port
		if (pValue.match(":") != null){
		  splitResult = pValue.split(":");
		}

		// Load ProxyIP and ProxyPort fields with values from hidden ProxyServer field.		
		this.m_oForm["ProxyIP"].value = splitResult[0];
		this.m_oForm["ProxyPort"].value = splitResult[1];
		
		// Load File Watcher Enable/Disable
		var i = (this.isEnabled(fwEnableText)) ? 1 : 0;
		this.m_oForm["WatchEnable"].options[i].selected=true;
		this.switchWatcher(i);
		
		// Load Proxy Authentication Enable/Disable
	  i = (this.isEnabled(authEnableText)) ? 1 : 0;
		this.m_oForm["AuthEnable"].options[i].selected=true;
		//this.switchAuth(i);
		
		// Load Proxy Enable/Disable
	  i = (this.isEnabled(proxyEnableText)) ? 1 : 0;
		this.m_oForm["ProxyEnable"].options[i].selected=true;
		//this.switchProxy(i);
		
		// Calling the onchange block of each form input adds unchanged values to 
		// the changedInputs array. Replace with a new Array to clear it.
		this.changedInputs = new Array();
	},
	
	// This funciton  loads all the values of continent-dependent items
	// including country, state, and service center.
	loadContinentValue: function(continent){
	
	  var x, formInput;
					
	  // Set the continent value
    var field = document.getElementById(continent);
		if(field)
		  field.setAttribute("selected", "true");
		
		// Load the country values for this continent
		this.loadCountry();
		
		// Get the stored country value
		x = this.agentConfigMap['country'];
		formInput = this.m_oForm[x.htmlName];
		var country = FileIO.textContent(this.sitemap.documentElement.selectSingleNode("replace/text[@symbol='" + x.xmlName + "']"));
		
		// Set the Country
		field = document.getElementById(country);
		this.out = field;
		if(field)
			field.setAttribute("selected", "true");
		
		// Load state options for this country, if any.
		this.loadState();
		
		// Get the stored state value
		x = this.agentConfigMap['state'];
		formInput = this.m_oForm[x.htmlName];
		var state = FileIO.textContent(this.sitemap.documentElement.selectSingleNode("replace/text[@symbol='" + x.xmlName + "']"));
		
		// Set the state input/drop-down value
		if (formInput.tagName == "INPUT"){
		  formInput.value = state;
		} else if (formInput.tagName == "SELECT"){
		  field = document.getElementById(state);
			if(field)
			  field.setAttribute("selected", "true");
		}
		
		// Load service center options
		this.loadSvcCenter();
		
		// Get the stored value
		x = this.agentConfigMap['serviceCenter'];
		formInput = this.m_oForm[x.htmlName];
		var svcCenter = FileIO.textContent(this.sitemap.documentElement.selectSingleNode("replace/text[@symbol='" + x.xmlName + "']"));
		
		// Set the drop-down value
		field = document.getElementById(svcCenter)
		if(field)
			field.setAttribute("selected", "true");
	},
	
	loadSavedProxy: function(value){
		// Clear all current values
		this.clearProxyValues();
		
		if(value == ("Create/Select Proxy" || "Proxy Disabled")){
		  this.resetProxyButtons();
			return;
		}
		
		// Set constants for this function		
		var docElem = this.agentProxy.documentElement;
		var proxyPath = "proxy[name='" + value + "']/";		
		
		var ip 				= FileIO.textContent(docElem.selectSingleNode(proxyPath + "ip"));
	  var port 			= FileIO.textContent(docElem.selectSingleNode(proxyPath + "port"));
		var enabled 	= FileIO.textContent(docElem.selectSingleNode(proxyPath + "auth/enabled"));
		var scheme 		= FileIO.textContent(docElem.selectSingleNode(proxyPath + "auth/scheme"));
		var user 			= FileIO.textContent(docElem.selectSingleNode(proxyPath + "auth/user"));
		var pass 			= FileIO.textContent(docElem.selectSingleNode(proxyPath + "auth/password"));
		
		// Set the text input fields
		if(ip)  {this.m_oForm["ProxyIP"].value = ip;}
		if(port){this.m_oForm["ProxyPort"].value = port;}
		if(user){this.m_oForm["AuthUser"].value = user;} 
		if(pass){this.m_oForm["AuthPassword"].value = pass;}
				
		// Set Auth Enable selector
		var i = (enabled == "true") ? 1 : 0;
		this.m_oForm["AuthEnable"].options[i].selected=true;
		
		// Set Auth Scheme selector
		var field = document.getElementById(scheme);
		if(field)
			field.setAttribute("selected", "true");
		
		// Add the proxy fields to the changed inputs array.		
		this.valueChanged('proxyServer');
		this.valueChanged('authScheme');
		this.valueChanged('authUsername');
		this.valueChanged('authPassword');
		
		this.resetProxyButtons();
	},
	
	newProxyName: function(){
		// Store the "select" element for later use
    this.m_proxyNameSelectElem = this.m_oForm["ProxyName"];
		
		// Create the input text element and replace with the "select" element
		proxyInput = document.createElement("input");
		proxyInput.type = "text";
		proxyInput.name = "ProxyName";
		proxyInput.id = "ProxyName";
		proxyInput.size = 20;
		//proxyInput.onchange = function(){  };
		
		// Replace select element with a blank text input element. 
		this.m_proxyNameSelectElem.parentNode.replaceChild(proxyInput, this.m_proxyNameSelectElem);
	},
	
	newProxy: function(){
		// Set flag to save proxy if "Submit" is selected before proxy "Save"
		this.unsavedNewProxy = true;
		
		// Change Proxy Name select element to a text input element.
		this.newProxyName();
		
		// Clear the proxy values.
		this.clearProxyValues();
		
		// Change "New" button to "Save"
		this.m_oForm["ProxyButton1"].value = "Save";
		this.m_oForm["ProxyButton1"].disabled = false;
		
		// Disable "Edit" button
		this.m_oForm["ProxyButton2"].disabled = true;
		
		// Change "Delete" button to "Cancel" button
		this.m_oForm["ProxyButton3"].value = "Cancel";
		this.m_oForm["ProxyButton3"].disabled = false;
		
		// Unlock proxy elements for editing
		this.lockProxyElements(false);
	},
	
	clearProxyValues: function(){
		
		for (i=0; i<this.proxyElements.length; i++){
		  var x = this.proxyElements[i];
			
			if (this.m_oForm[x].tagName == "INPUT"){
			  this.prevProxyValues[x] = this.m_oForm[x].value;
				this.m_oForm[x].value = "";
			}
			else if (this.m_oForm[x].tagName == "SELECT") {
				this.prevProxyValues[x] = this.m_oForm[x].selectedIndex;
			  this.m_oForm[x].options[0].setAttribute("selected", "true");
			}	 
		}
	},
	
	cancelProxy: function(){
	  // Replace the proxy name text input with the saved select (drop-down) element 
		this.m_oForm["ProxyName"].parentNode.replaceChild(this.m_proxyNameSelectElem, this.m_oForm["ProxyName"]);
		
		// Restore previous proxy values
		for (i in this.prevProxyValues) {
  	  if (this.m_oForm[i].tagName == "INPUT"){
  			this.m_oForm[i].value = this.prevProxyValues[i];
			}
  		else if (this.m_oForm[i].tagName == "SELECT") {
  			var selIndex = this.prevProxyValues[i];
  			if (selIndex)
  			  this.m_oForm[i].options[selIndex].selected = true;
  		}
		}
			
		this.resetProxyButtons();
		
		// Reset proxy labels in case they were marked invalid
		var labels = document.getElementsByTagName('label');
 		for (j in labels)
   	  labels[j].className = "";
		 
		this.lockProxyElements(true);
		
		// Clear Proxy Message
		this.setProxyMessage(false);
		
		// Reset unsaved proxy flags
		this.unsavedNewProxy = false;
		this.unsavedEditProxy = false;
	},
	
	proxyButton1: function(value){
		this.setProxyMessage(false);
	
	  if (value == "New")
		  this.newProxy();
		else if (value == "Save")
		  this.saveProxy(true);
	},
	
	proxyButton2: function(value){
	  this.setProxyMessage(false);
	
    if (value == "Edit")
      this.editProxy();
		else if (value == "Save")
		  this.saveProxy(false);
	},
	
	proxyButton3: function(value){
	  this.setProxyMessage(false);
	
	  if (value == "Cancel")
		  this.cancelProxy();
		else if (value == "Delete")
		  this.deleteProxy();
	},
	 
	validateProxy: function(newProxy){
	  var pass = true;
		var message = new Array();
		var labels = document.getElementsByTagName('label');
		
		// Reset any labels that are set to invalid
		for (j in labels){
		  labels[j].className = "";
		}
		
		// Skip validation on AuthUser & AuthPassword if Auth is disabled.
		if(this.m_oForm["AuthEnable"].value==0){
		  this.proxyElements.pop();
			this.proxyElements.pop();
		}
		
		// Temporarily add ProxyName to proxyElements for validation purposes
		this.proxyElements.push("ProxyName");
		
		// For each element in proxyElements
		for (i in this.proxyElements){
		  var elementName = this.proxyElements[i];
			
			// If the value is blank, fail validation and make "invalid" style 
			if (this.m_oForm[elementName].value == ""){		
				pass = false;
				for (j in labels){
				  if(labels[j].htmlFor == elementName)
					  labels[j].className = "invalid";
				}
			}	
		}
		
		// If any fields are blank, add a message
		if (!pass){
		  this.setProxyMessage("Please fill in all required proxy fields.");
		}
		
	  // Remove Proxy Name from proxyElements
		this.proxyElements.pop();
		
		// Return Popped values to proxyElements
		if(this.m_oForm["AuthEnable"].value==0){
		  this.proxyElements.push("AuthUser");
			this.proxyElements.push("AuthPassword");
		}
		
		// Check proxy name
		var proxyName = this.m_oForm["ProxyName"].value;
		
		// Do not allow "Create/Select Proxy" or "Proxy Disabled" for proxy name
		if (proxyName == ("Create/Select Proxy" || "Proxy Disabled")){
		  pass = false;
			
			// Add a message
			var currentMessage = document.getElementById('ProxyMessage').innerHTML;
			this.setProxyMessage('Invalid Proxy Name. Please choose a different proxy name.<br />' + currentMessage);
			
			// Turn the "Name:" label red
			for (j in labels){
				if(labels[j].htmlFor == "ProxyName")
			    labels[j].className = "invalid";
		  }
		}
		
		// Ensure ProxyName is unique
		var nameInUse = this.agentProxy.documentElement.selectSingleNode("//proxy[name='"+proxyName+"']");
		
		// If a proxy by this name already exists
		if(nameInUse && newProxy){
		  // Fail validation
			pass = false;
			
			// Add a message
			var currentMessage = document.getElementById('ProxyMessage').innerHTML;
			this.setProxyMessage('Proxy name must be unique. Please choose a different proxy name.<br />' + currentMessage);
			
			// Turn the "Name:" label red
			for (j in labels){
				if(labels[j].htmlFor == "ProxyName")
			    labels[j].className = "invalid";
		  }
		}
	
		return pass;
	},
	
	saveProxy: function(newProxy){
		// If the new proxy doesn't pass validation, alert user and cancel the save.
		if(!this.validateProxy(newProxy)){return;}

	  // Add the proxy fields to the changed inputs array.		
		this.valueChanged('proxyServer');
		this.valueChanged('authScheme');
		this.valueChanged('authUsername');
		this.valueChanged('authPassword');
		
		var newName = this.m_oForm["ProxyName"].value;
		var newIP = this.m_oForm["ProxyIP"].value;
		var newPort = this.m_oForm["ProxyPort"].value;
		var newEnable = (this.m_oForm["AuthEnable"].value == 1) ? "true" : "false";
		var newScheme = this.m_oForm["AuthScheme"].value;
		var newUser = this.m_oForm["AuthUser"].value;
		var newPassword = this.m_oForm["AuthPassword"].value;
		
		// If this is a new proxy configuration,
		if(newProxy){
  		// Create proxy element and append it to agentProxy.
  		var proxy = this.agentProxy.createElement('proxy');
  		this.agentProxy.documentElement.appendChild(proxy);
		
		// If this is editing an existing proxy,			
		} else {			
			// Get the proxy to be edited by its previous name (in the drop-down).
			var prevName = this.m_proxyNameSelectElem.value;
			var proxy = this.agentProxy.documentElement.selectSingleNode("proxy[name='"+prevName+"']");
			
			// Remove all child nodes of proxy
			while (proxy.childNodes.length>0){
			  proxy.removeChild(proxy.childNodes[0]);
			}
		}
		
		// Create xml elements for saved proxy.
		var name = this.agentProxy.createElement('name');
		var ip = this.agentProxy.createElement('ip');
		var port = this.agentProxy.createElement('port');
		var auth = this.agentProxy.createElement('auth');
		var enabled = this.agentProxy.createElement('enabled');
		var scheme = this.agentProxy.createElement('scheme');
		var user = this.agentProxy.createElement('user');
		var password = this.agentProxy.createElement('password');
		
		// Organize elements into structure
		proxy.appendChild(name);
		proxy.appendChild(ip);
		proxy.appendChild(port);
		proxy.appendChild(auth);
		  auth.appendChild(enabled);
		  auth.appendChild(scheme);
		  auth.appendChild(user);
		  auth.appendChild(password);
		
		// Append values to each node
    name.appendChild(this.agentProxy.createTextNode(newName));
		ip.appendChild(this.agentProxy.createTextNode(newIP));
		port.appendChild(this.agentProxy.createTextNode(newPort)); 
		enabled.appendChild(this.agentProxy.createTextNode(newEnable));
		scheme.appendChild(this.agentProxy.createTextNode(newScheme));
		user.appendChild(this.agentProxy.createTextNode(newUser));
		password.appendChild(this.agentProxy.createTextNode(newPassword));
		
		//Save changes and alert user.
		var saved = FileIO.saveXML(this.agentProxyPath, this.agentProxy);
		
		if(!saved){
		  alert('An unknown error occurred while saving proxy configuration.');
			return;
		}
			
		this.resetProxyButtons();
		
		// re-initialize the Proxy name drop-down
		this.loadProxyNames();
		
		// Reset proxy labels in case they were marked invalid
		var labels = document.getElementsByTagName('label');
 		for (j in labels)
   	  labels[j].className = "";
		
		// Lock proxy elements
		this.lockProxyElements(true);
		
		// Reset unsaved proxy flags
		this.unsavedNewProxy = false;
		this.unsavedEditProxy = false;
	},
	
	editProxy: function(){
	  // Set flag to save proxy if "Submit" is selected before proxy "Save"
		this.unsavedEditProxy = true;
		
		// Change Proxy Name select element to a text input element.
		this.newProxyName();
		
		// Place selected Proxy Name in text input for editing.
		this.m_oForm["ProxyName"].value = this.m_proxyNameSelectElem.value;  
		
		// Store all proxy values in case of cancellation
		for (i=0; i<this.proxyElements.length; i++){
		  var x = this.proxyElements[i];
			
			if (this.m_oForm[x].tagName == "INPUT"){
			  this.prevProxyValues[x] = this.m_oForm[x].value;
			}
			else if (this.m_oForm[x].tagName == "SELECT") {
				this.prevProxyValues[x] = this.m_oForm[x].selectedIndex;
			}	 
		}
			
		// Disable "New" button
		this.m_oForm["ProxyButton1"].disabled = true;

		// Change "Edit" button to "Save"
		this.m_oForm["ProxyButton2"].value = "Save";
		
		// Change "Delete" button to "Cancel" button
		this.m_oForm["ProxyButton3"].value = "Cancel";
		
		// Unlock proxy elements for editing
		this.lockProxyElements(false);
	},

	deleteProxy: function(){
		var name = this.m_oForm["ProxyName"].value;
		var sel = this.m_oForm["ProxyName"].selectedIndex;
		
		// Get the proxy.
		var proxylist = this.agentProxy.documentElement;
		var proxy = proxylist.selectSingleNode("proxy[name='"+name+"']");
		
		// Ensure user is not deleting the current proxy in use.
		if(proxy == this.currentProxy){
		  alert('You are attempting to delete the ' +
						'saved proxy configuration currently in use.\n\n' +
						
						'You must first select an alternate proxy configuration or ' + 
						'and save your selection by pressing the "' + 
						this.m_oForm["SubmitButton"].value + '" button before ' +
						'deleting this proxy configuration.');
		  return;
		}
		
		var q = "Are you sure you want to delete proxy configuration:\n\n \"" + name + "\"?";
		
		// If the user does not confirm the deletion, return.  
		if(!confirm(q)){return;}
		
		// Remove the selected proxy from agentProxy.
		proxylist.removeChild(proxy);
		
		// Remove element from proxy name list.
		var selectedOption = this.m_oForm["ProxyName"].options[sel];
		this.m_oForm["ProxyName"].removeChild(selectedOption);
		
		// Save changes and alert user.
		var saved = FileIO.saveXML(this.agentProxyPath, this.agentProxy);
		if(saved)
		  alert('Proxy Deleted.');
		
		// Selects proxy currently in use.
		name = FileIO.textContent(this.currentProxy.selectSingleNode("name"));
		var field = document.getElementById(name)
		if(field)
			field.setAttribute("selected", "true");
		this.loadSavedProxy(this.m_oForm["ProxyName"].value);
	},
	
	setProxyMessage: function(message){
	  var messageCell = document.getElementById("ProxyMessage");
		
		if(!message){
		  messageCell.className = "invisible";
			messageCell.innerHTML = "";
		} else {
		  messageCell.className = "warning";
			messageCell.innerHTML = message;
		}
	},
	
	resetProxyButtons: function(){
		var proxyDisabled = this.m_oForm["ProxyEnable"].value != 1;
		var emptyList = this.m_oForm["ProxyName"].value == ("Create/Select Proxy" || "Proxy Disabled");
		
		
		// Enable button 1, change text to "New"
		this.m_oForm["ProxyButton1"].disabled = proxyDisabled;
		this.m_oForm["ProxyButton1"].value = "New";
		
		// Enable button 2, change text to "Edit"
		this.m_oForm["ProxyButton2"].disabled = emptyList || proxyDisabled;
		this.m_oForm["ProxyButton2"].value = "Edit";
		
		// Change "Cancel" button back to "Delete" button
		this.m_oForm["ProxyButton3"].disabled = emptyList || proxyDisabled;
		this.m_oForm["ProxyButton3"].value = "Delete";
		
	},
   
  changedURL: function(){
    var enturl = this.m_oForm["UserEntURL"];
    var tunurl = this.m_oForm["UserTunURL"];
    var userenturl = this.m_oForm["LocalUserEntURL"];
    var usertunurl = this.m_oForm["LocalUserTunURL"];
    userenturl.value = enturl.value;
    usertunurl.value = tunurl.value;
  },
  
  switchWatcher: function(x) {
    var watchdir = this.m_oForm["WatchDir"];
    var watchfilt = this.m_oForm["WatchFilter"];
    var watchen = parseInt(x,10);
    if (watchen == 1)
    {
      // Only enable the fields if userconfig==true
			watchdir.disabled=false || !this.agentConfigMap.watcherDir.userconfig;
      watchfilt.disabled=false || !this.agentConfigMap.watcherFilter.userconfig;
    }
    else
    {
      watchdir.disabled=true;
      watchfilt.disabled=true;
    }
  },
  
  switchProxyControls: function(x) {    
		var proxen = parseInt(x,10);
		var disabled = (proxen == 1) ? false : true;  
    var proxyName = this.m_oForm["ProxyName"];
		
		// If disabling proxy...			
		if(disabled){
		  
			// If an unsaved proxy exists, cancelProxy
			if(this.unsavedNewProxy || this.unsavedEditProxy)
			  this.cancelProxy();
			
			proxyName = this.m_oForm["ProxyName"];
			
			// Clear Proxy Name list			
			while(proxyName.childNodes.length > 0)
			  proxyName.removeChild(proxyName.childNodes[0]);
				
			// Create "Proxy Disabled" option
		  var option = document.createElement("option");
			textContent = "Proxy Disabled";
  		option.innerHTML = textContent;
  		option.setAttribute("value", textContent);
  		option.setAttribute("id", textContent);
			option.selected = true;
			proxyName.appendChild(option);
			
			// Call valueChanged() on proxyServer
			this.valueChanged('proxyServer');
			
			// Clear Proxy Values
			this.clearProxyValues();
			
			// Disable Messages
			this.setProxyMessage(false);
		
		} else {
		
		//If enabling proxy
		  this.loadProxyNames();
		}
		
		// Enable/Disable the ProxyName field
		proxyName.disabled = disabled;
				
		// Reset proxy buttons
		this.resetProxyButtons();
  },
	
  lockProxyElements: function(bool) {    
		for (i in this.proxyElements){
      var x = this.proxyElements[i];
			this.m_oForm[x].disabled = bool;
		}
		if(!bool)
		  this.switchAuth(this.m_oForm["AuthEnable"].value);
  },
  
  switchAuth: function(x) {
    var authscheme = this.m_oForm["AuthScheme"];
    var authuser = this.m_oForm["AuthUser"];
    var authpassword = this.m_oForm["AuthPassword"];
    var authflag = parseInt(x,10);
    if (authflag == 1)
    {
      // Only enable fields if userconfig==true
			authscheme.disabled=false || !this.agentConfigMap.authScheme.userconfig;
      authuser.disabled=false || !this.agentConfigMap.authUsername.userconfig;
      authpassword.disabled=false || !this.agentConfigMap.authPassword.userconfig;
    }
    else
    {
      authscheme.disabled=true;
      authuser.disabled=true;
      authpassword.disabled=true;
			//this.m_oForm["AuthScheme"].options[0].selected = true;
    }
  },
  
	enableFields: function() {			
		// For all the fields in the form
		for (i=0; i<this.m_oForm.length; i++){
		  
			// Skip the fields in the proxyElements array
			c = false;
			for(j=0; j<this.proxyElements.length; j++){
			  if(this.m_oForm[i].name == this.proxyElements[j])
				  c = true;
			}
			if(c){continue;}
			
			// Enable the field
			this.m_oForm[i].disabled = false;
		}
  },
	
	saveScripts: function(){
		configForm = document.getElementById("ConfigForm");
		if(configForm)
		  configForm.className = "invisible";
		
		wait = document.getElementById("WaitMessage");
		wait.className = "wait";
			
		var wsh = new ActiveXObject("WScript.Shell");
		var wshSysEnv = wsh.Environment("SYSTEM");
		var insite2Home = wshSysEnv("INSITE2_HOME");
		var insite2RootDir = wshSysEnv("INSITE2_ROOT_DIR");
		var insite2DataDir = wshSysEnv("INSITE2_DATA_DIR");
		var perlHome = wshSysEnv("PERL_HOME");
		
		/* Build the following command
		 * "%INSITE2_ROOT_DIR%\bin\gencfg.cmd" 
		 *   -template "%INSITE2_DATA_DIR%\etc\templates\qsa" 
		 *   -cfgdir "%INSITE2_DATA_DIR%\etc"
		 */
		var cmd = '"'+insite2RootDir+'\\bin\\gencfg.cmd" '
		  +'-template "'+insite2DataDir+'\\etc\\templates\\qsa" '
			+'-cfgdir "'+insite2DataDir+'\\etc"';
		
		// Run command with hidden window and wait to return before moving on
		wsh.run(cmd, 0, true);

                // Build the command to apply sitemap to virtual devices.
                var mycmd = '"'+insite2Home+'\\AgentConfig\\ApplyCfgDockables.bat"';

                // Run mycmd with hidden window and wait
                wsh.run(mycmd, 0, true);
		
		/* Build the following command
		 * %PERL_HOME%\bin\perl.exe"
		 *   "%INSITE2_HOME%\Questra\ExtractSitemap.pl" 
		 *   "%INSITE2_DATA_DIR%\etc\sitemap.xml" 
		 *   "%INSITE2_HOME%\Questra\AgentConfig.xml"
		 */
		cmd = '"'+perlHome+'bin\\perl.exe" '
		  +'"'+insite2Home+'\\Questra\\ExtractSitemap.pl" '
			+'"'+insite2DataDir+'\\etc\\sitemap.xml" '+
			+'"'+insite2Home+'\\Questra\\AgentConfig.xml"';
		
		// Run command with hidden window and wait to return before moving on
		wsh.run(cmd, 0, true);
		
		/* Build the following command
		 * "%INSITE2_HOME%\Questra\QSAServiceCreate.bat"
		 */
		cmd = '"'+insite2Home+'\\Questra\\QSAManControl.bat"';

		// Run command with hidden window and wait to return before moving on
		wsh.run(cmd, 0, true);		
		
		wait.className = "invisible";
		configForm.className = "";
		
		return true;
	},
	
	getNewSitemapPath: function(){
	
	  var installOption = FileIO.loadRemoteXML("../InstallOption.xml");
		if (!installOption)
			return;
		
		var node = installOption.selectSingleNode("//EnvVar[@varname='INSITE2_DATA_DIR']");
		
		if (node){
			 var dataDir = FileIO.textContent(node);
			 dataDir = dataDir.replace(/\\/g, '/');
			 return(dataDir + "/etc/sitemap.xml");			 
		}
	
	},
	
	testing: function() {
	}
};

function MapEntry(htmlName, xmlName){
  this.htmlName = htmlName;
  this.xmlName  = xmlName;
	this.userconfig = false;
}

function AgentConfigMap() {
  this.deviceName       = new MapEntry("DeviceName", "__SA_ASSET_NAME__");
  this.serialNumber		  = new MapEntry("SerialNumber", "__SA_ASSET_SERIAL_NUMBER__");
  this.displayName 		  = new MapEntry("FriendlyName", "__SA_ASSET_FRIENDLY_NAME__");
  this.agentDescription = new MapEntry("AgentDescription", "__SA_ASSET_DESCRIPTION__");
  
  this.continent        = new MapEntry("Continent", "__SA_CONTINENT__");
  this.country 				  = new MapEntry("Country", "__SA_COUNTRY__");	
  this.addressLine1 		= new MapEntry("AddressLine1", "__SA_ADDRESS_LINE1__");
  this.addressLine2 		= new MapEntry("AddressLine2", "__SA_ADDRESS_LINE2__");
  this.city 						= new MapEntry("City", "__SA_CITY__");
  this.state 					  = new MapEntry("State", "__SA_STATE__");
  this.postal 					= new MapEntry("PostalCode", "__SA_POSTALCODE__");

  this.latitude 				= new MapEntry("Latitude", "__SA_LATITUDE__");
	this.longitude 			  = new MapEntry("Longitude", "__SA_LONGITUDE__");
  
  this.institution 		  = new MapEntry("Institution", "__SA_INSTITUTION__");
  this.department 			= new MapEntry("Department", "__SA_DEPARTMENT__");
  this.building 				= new MapEntry("Building", "__SA_BUILDING__");
  this.theFloor 				= new MapEntry("Floor", "__SA_FLOOR__");
  this.room 						= new MapEntry("Room", "__SA_ROOM__");
	
	this.serviceCenter    = new MapEntry("SvcCenter", "__SA_SERVICE_CENTER__");
	this.logLevel         = new MapEntry("LogLevel", "__LOG_LEVEL__");
	
	this.entURL           = new MapEntry("UserEntURL", "__ENT_URL__");
	this.tunURL           = new MapEntry("UserTunURL", "__TUN_URL__");
	
	this.reposDir         = new MapEntry("FileRepository", "__FILE_REPOS_DIR__");
  this.watcherDir       = new MapEntry("WatchDir", "__FILE_WATCHER_DIR__");
  this.watcherFilter    = new MapEntry("WatchFilter", "__FILE_WATCHER_FILTER__");

	this.proxyServer      = new MapEntry("ProxyServer", "__PROXY_SERVER__");
	this.authScheme       = new MapEntry("AuthScheme", "__PROXY_AUTH_SCHEME__");
	this.authUsername     = new MapEntry("AuthUser", "__PROXY_AUTH_USERNAME__");
	this.authPassword     = new MapEntry("AuthPassword", "__PROXY_AUTH_PASSWORD__");	
}

var fwEnableText = new Array("/ServiceAgent/ContactInfo/ServiceAgentProfile/FileRepository/FileWatcher");

var proxyEnableText = new Array("/HttpServerConnDS/Asset/Connection/ProxyServerAddress",
                                "/ServiceAgent/OCM/ProxyServerAddress");

var authEnableText = new Array("/HttpServerConnDS/Asset/Connection/ProxyServerAuthorization",
                               "/ServiceAgent/OCM/ProxyServerAuthorization");

var authSchemeText = new Array("/HttpServerConnDS/Asset/Connection/ProxyServerAuthorization/AuthScheme",
                               "/ServiceAgent/OCM/ProxyServerAuthorization/AuthScheme");
