// This JavaScript file contains functions that are used make ContactGE and ConnectToGE API calls
// Date Added: 09/11/06
// Modified: 02/09/2007
// Written by: Jung Oh
// Modified by: Andy Kant
  
var APICalls = {
	m_oStringsNode: false,
	m_sContactGEPath: "..\\Questra\\GeHealthcare\\Agent\\bin\\ContactGE.exe",
	m_sConnectToGEPath: "..\\Questra\\GeHealthcare\\Agent\\bin\\ConnectToGE.exe",
	m_sQSAConfigPath: false,
	m_oConfigXMLDoc: false,
	m_sPostprocessingPath: false,
	forcePollPeriod: 30,
	forcePollDuration: 30,
	useConnectToGE: true,
	// ContactGE variables, set the first time APICalls.send is called, poll is hard-coded.
	contactGE: { retryCount: 3, retryPeriod: 15, timeout: 60, poll: 250, loaded: false },

	// Get the full path of qsaconfig.xml files
	getQSAConfigPath: function() {
		if (!APICalls.m_sQSAConfigPath)
		{
			var optionXMLDoc = FileIO.loadXML("..\\InstallOption.xml");
			var envVarElem = optionXMLDoc.selectSingleNode("/InstallOption/SystemEnvVars/EnvVar[@varname='INSITE2_DATA_DIR']");
			try 
			{
				if (envVarElem)
					APICalls.m_sQSAConfigPath = FileIO.textContent(envVarElem) + "\\etc\\qsaconfig.xml"; 
				else
					APICalls.m_sQSAConfigPath = "..\\Questra\\GeHealthcare\\Agent\\etc\\qsaconfig.xml"; 
			}
			catch(e)
			{
				APICalls.m_sQSAConfigPath = false;
			}
		}
		return APICalls.m_sQSAConfigPath;
	},
	
	// Send the RFS
	// path: Path of the RFS xml
	// runPhases: Configures which phases to run
	// resultHandler: A function that handles the returned value
	// Result object structure:
	// bResult: true if the API succeeded, false if the API fails
	// rfsNumber: RfsNumber
	// errorMsg: translated error message
	// afterHourMsg: translated after hour message
	send: function(path, runPhases, resultHandler) {
		// ---------------- IMPORTANT NOTE ---------------- //
		// There are multiple stages of asynchronous calls; //
		// the phases are defined in semi-reverse order.    //
		//                                                  //
		// DESIGN:                                          //
		//   APICalls.send(..)                              //
		//     Initialize variables.                        //
		//     Define SENDING phase.                        //
		//       Define/execute RETRY phase.                //
		//         Define/execute PROCESS RESULT phase.     //
		//           Define/execute POSTPROCESSING phase.   //
		//         Return result.                           //
		//     Define/execute PREPROCESSING phase.          //
		//       Execute SENDING phase.                     //
		//                                                  //
		// NOTES:                                           //
		//   Results (including errors) are passed through  //
		//   the "resultHandler" function if and when they  //
		//   are received. Preprocessing and postprocessing //
		//   stages are only attempted when the preprocess  //
		//   parameter is set to true. If they fail, they   //
		//   are skipped and the execution continues.       //
		// ---------------- IMPORTANT NOTE ---------------- //
		
		// Initialize variables.
		var defaultPhases = {
			debug: false,
			preprocess: false,
			send: true,
			postprocess: false
		};
		runPhases = runPhases || {};
		for (var phase in defaultPhases) {
			if (typeof runPhases[phase] != 'boolean') {
				runPhases[phase] = defaultPhases[phase];
			}
		}
		resultHandler = /^function$/i.test(typeof resultHandler) ? resultHandler : false;
		var cfg = APICalls.getConfigXML();
		var rfsPath = path.match(/^(.*[\\\/])(.+)\.xml$/)[1].replace(/\\/g, "/");
		var rfsName = path.match(/^(.*[\\\/])(.+)\.xml$/)[2];

		//console.DEBUG = true;
		//console.log(rfsPath+rfsName, rfsPath+rfsName+".xml");
		result = {bResult: false, rfsNumber: "", errorMsg: "", afterHourMsg: ""};
		// Alter resultHandler to allow returns.
		if (resultHandler)
		{
			var __method = resultHandler;
			resultHandler = function(result) {
				__method.call(__method, result);
				return result;
			};
		}
		else
		{
			resultHandler = function(result) {
				return result;
			};
		}
		
		// Check if the ContactGE API exists
		if (FileIO.Properties.isFile(APICalls.m_sContactGEPath) == false)
		{
			result.errorMsg = APICalls.getString("ErrorContactGENotFound");
			return resultHandler(result);
		}
		
		// Load ContactGE settings.
		if (cfg && !APICalls.contactGE.loaded)
		{
			try
			{
				APICalls.contactGE.retryCount = FileIO.textContent(cfg.selectSingleNode("/configRFS/SendOptions/ContactGE/RetryCount"));
				APICalls.contactGE.retryPeriod = FileIO.textContent(cfg.selectSingleNode("/configRFS/SendOptions/ContactGE/RetryPeriod"));
				APICalls.contactGE.timeout = FileIO.textContent(cfg.selectSingleNode("/configRFS/SendOptions/ContactGE/Timeout"));
				APICalls.contactGE.loaded = true;
			}
			catch(e)
			{
				APICalls.contactGE = { retryCount: 3, retryPeriod: 15, timeout: 60, loaded: true };
			}
		}
		
		// DEFINE PHASE 2 and later (Sending, Retries, Postprocessing, Result).
		var PHASE_TWO = function() {
			// PHASE 2: SENDING
			if (runPhases.send) {
				if (runPhases.preprocess)
					StatusBar.updateActionStatus("<span class=\"red\">" + APICalls.getString("Sending") + "</span>", true);
				// Use ContactGE.exe to send the RFS
				var args = new Array();
				args.push(path);
				
				// Attempt send and retries.
				var tryCount = 0;
				var attemptContactGE = function() {
					var execResult = FileIO.execute(APICalls.m_sContactGEPath, args, false, true, {
						poll: APICalls.contactGE.poll, timeout: APICalls.contactGE.timeout * 1000,
						exitHandler:
							function(exitObj) {
								if (!exitObj.failure)
								{
									// Load RFS XML
									var oXMLDoc = FileIO.loadXML(path);
									
									// Check if the request succeeded by checking RfsNumber element in the RFS
									var oRfsNumber = oXMLDoc.documentElement.selectSingleNode("RfsNumber");
									if (oRfsNumber || runPhases.debug)
									{
										// Check if the number actually exists
										if (oRfsNumber) {
											var sRfsNumber;
											if (document.all)
												sRfsNumber=oRfsNumber.text;
											else
												sRfsNumber=oRfsNumber.textContent;
										}
											
										// If the number exists, the request is succeeded.
										if (sRfsNumber != "" || runPhases.debug)
										{
											if (sRfsNumber != "") {
												// Change the status in the RFS xml
												// Add or modify the Status element to Sent
												var oStatus = oXMLDoc.documentElement.selectSingleNode("Status");
												if (oStatus)
													oXMLDoc.documentElement.removeChild(oStatus);
												oStatus = oXMLDoc.createElement("Status");
												if (document.all)
													oStatus.text = "Sent";
												else
													oStatus.textContent = "Sent";
												oXMLDoc.documentElement.appendChild(oStatus);
												FileIO.saveXML(path, oXMLDoc);
												// Check if it's currently outside of OnLine Center coverage hours
												var oCovered = oXMLDoc.documentElement.selectSingleNode("RequestCovered");
												afterHourMsg = "";
												if (oCovered)
												{
													var sCovered;
													if (document.all)
														sCovered=oCovered.text;
													else
														sCovered=oCovered.textContent;
													
													// If out of OnLine Center hours, generate the message.
													if (sCovered.match(/^no$/i))
													{
														result.afterHourMsg = APICalls.getString("AfterHourMsg1") + "\n";
														var sHour = "";
														var oHour = oXMLDoc.documentElement.selectSingleNode("NextOpeningHour");
														if (oHour)
														{
															if (document.all)
																sHour=oHour.text;
															else
																sHour=oHour.textContent;
														}
														var sDate = "";
														var oDate = oXMLDoc.documentElement.selectSingleNode("NextWorkingDate");
														if (oDate)
														{
															if (document.all)
																sDate=oDate.text;
															else
																sDate=oDate.textContent;
														}
														result.afterHourMsg += APICalls.getString("AfterHourMsg2");
														if (sHour != "" || sDate != "")
														{
															result.afterHourMsg +=  " - " + APICalls.getString("Next Opening Time") + ":";
															if (sHour != "")
																result.afterHourMsg +=  " "  + sHour;
															if (sDate != "")
															{
																// Remove <sup> tags
																sDate = sDate.replace(/<\/?sup>/g,"");
																result.afterHourMsg +=  "/" + sDate;
															}
														}
														result.afterHourMsg += "\n";
														
														var sPhone = "";
														var oPhone = oXMLDoc.documentElement.selectSingleNode("PhoneNumbers");
														if (oPhone)
														{
															if (document.all)
																sPhone=oPhone.text;
															else
																sPhone=oPhone.textContent;
														}
														result.afterHourMsg += APICalls.getString("AfterHourMsg3");
														if (sPhone != "")
															result.afterHourMsg +=  " - " + APICalls.getString("Phone Number") + ": " + sPhone;
													}
												}
											}
											result.bResult = true;
											if (sRfsNumber != "")
												result.rfsNumber = sRfsNumber ;
											else 
												result.rfsNumber = runPhases.debug ? 'test123' : '';
											
											// PHASE 3: POSTPROCESSING
											if (runPhases.postprocess)
											{
												StatusBar.updateActionStatus("<span class=\"red\">" + APICalls.getString("Postprocessing") + "</span>", true);
												// Find ZIP path.
												if (!APICalls.m_sPostprocessingPath)
												{
													if (FileIO.Properties.isFile(APICalls.getQSAConfigPath()))
													{
														var qsaConfigXML = FileIO.loadXML(APICalls.getQSAConfigPath());
														var zipPath = false;
														if (qsaConfigXML)
															zipPath = qsaConfigXML.selectSingleNode("//VirtualDirectory/Directory");
														if (zipPath)
														{
															APICalls.m_sPostprocessingPath = FileIO.textContent(zipPath).replace("\\", "/");
															APICalls.m_sPostprocessingPath += /[\\\/]$/.test(APICalls.m_sPostprocessingPath) ? "" : "/";
														}
													}
												}
												// ZIP up the preprocessor directory if it exists.
												if (APICalls.m_sPostprocessingPath && FileIO.Properties.isDirectory(rfsPath+rfsName))
												{
													// Create export directory if it doesn't exist.
													if (!FileIO.Properties.isDirectory(APICalls.m_sPostprocessingPath))
														FileIO.createDirectory(APICalls.m_sPostprocessingPath);
													//console.log(rfsPath+rfsName+".xml");
													var zipResult = FileIO.execute("zip", ["-rD", APICalls.m_sPostprocessingPath+result.rfsNumber+".zip", rfsPath+rfsName+".xml", rfsPath+rfsName], false, false, {
														poll: APICalls.contactGE.poll, timeout: APICalls.contactGE.timeout * 1000,
														exitHandler:
															function(exitObj) {
																// Return regardless of result.
																return resultHandler(result);
															},
														timeoutHandler:
															function(exitObj) {
																// Return regardless of result.
																return resultHandler(result);
															}
													});
													if (zipResult.failure)
													{
														// Return regardless of result.
														return resultHandler(result);
													}
												}
												else
												{
													// Wasn't able to postprocess, finish anyways.
													return resultHandler(result);
												}
											}
											else
											{
												// Skipping the postprocessor.
												return resultHandler(result);
											}
										}
										else
										{
											var sFailedMsg = "";
											// If the number is empty, check ResponseException element
											var oException= oXMLDoc.documentElement.selectSingleNode("ResponseException");
											if (oException)
											{
												var sException;
												if (document.all)
													sException=oException.text;
												else
													sException=oException.textContent;
													
												if (sException != "")
													sFailedMsg = APICalls.getString("Request Failed") + ": " + sException;
												
												// Remove this element, since it's not needed anymore
												oXMLDoc.documentElement.removeChild(oException);
											}
											if (sFailedMsg == "")
												sFailedMsg = APICalls.getString("Request Failed") + ": " + APICalls.getString("Unknown Error");
											
											// Remove the response related elements, so this RFS can be retried next time
											oXMLDoc.documentElement.removeChild(oRfsNumber);
											var oElement = oXMLDoc.documentElement.selectSingleNode("RequestCovered");
											if (oElement)
												oXMLDoc.documentElement.removeChild(oElement);
											oElement = oXMLDoc.documentElement.selectSingleNode("NextOpeningHour");
											if (oElement)
												oXMLDoc.documentElement.removeChild(oElement);
											oElement = oXMLDoc.documentElement.selectSingleNode("NextWorkingDate");
											if (oElement)
												oXMLDoc.documentElement.removeChild(oElement);
											oElement = oXMLDoc.documentElement.selectSingleNode("PhoneNumbers");
											if (oElement)
												oXMLDoc.documentElement.removeChild(oElement);
											FileIO.saveXML(path, oXMLDoc);
											
											// Set the Request Failed message
											result.bResult = true;
											result.errorMsg = sFailedMsg;
											// Return result.
											return resultHandler(result);
										}
									}
									else
									{
										// Connection error, retry.
										if (++tryCount <= APICalls.contactGE.retryCount)
										{
											// Try it again after the specified retry period
											setTimeout(attemptContactGE, APICalls.contactGE.retryPeriod * 1000);
										}
										else
										{
											// If RfsNumber element doesn't even exist, there's a problem with connection
											result.bResult = false;
											result.errorMsg = APICalls.getString("ErrorConnection");
											// Return result.
											return resultHandler(result);
										}
									}
								}
								else
								{
									// Error, unsuccessful send.
									// This error is not worth retrying.
									result.bResult = false;
									result.errorMsg = APICalls.getString("Unknown Error") + " - ExitCode: " + exitObj.exitCode;
									return resultHandler(result);
								}
							},
						timeoutHandler:
							function(exitObj) {
								// Attempt timed out, retry.
								if (++tryCount < APICalls.contactGE.retryCount)
								{
									// Try it again after the specified retry period
									setTimeout(attemptContactGE, APICalls.contactGE.retryPeriod * 1000);
								}
								else
								{
									// Error, unsuccessful send.
									result.bResult = false;
									result.errorMsg = APICalls.getString("Unknown Error") + " - ExitCode: " + exitObj.exitCode;
									return resultHandler(result);
								}
							}
					});
					if (execResult.failure)
					{
						result.bResult = false;
						result.errorMsg = APICalls.getString("Unknown Error");
						return resultHandler(result);
					}
				}
				// Start first attempt.
				attemptContactGE();
			}
			else
			{
				result.bResult = false;
				result.errorMsg = APICalls.getString("Unknown Error");
				return resultHandler(result);
			}
		};
		
		// PHASE 1: PREPROCESSING
		// Preprocess the RFS if applicable.
		if (runPhases.preprocess && /([^\\\/]+?\.xml)$/.test(path) && FileIO.Properties.isFile(path))
		{
			StatusBar.updateActionStatus("<span class=\"red\">" + APICalls.getString("Preprocessing") + "</span>", true);
			var preprocessor = cfg.selectSingleNode("/configRFS/SendOptions/Preprocessor[@enable='true']") || false;
			var interactive = cfg.selectSingleNode("/configRFS/SendOptions/Preprocessor[@interactive='true']") || false;
			var preprocessorPath = preprocessor.getAttribute("commandPath") || false;
			// Is the preprocessor enabled and does it exist?
			if (preprocessor && preprocessorPath && FileIO.Properties.isFile(preprocessorPath))
			{
				// Initialize variables.
				var rfs = FileIO.loadXML(path);
				var problemType = FileIO.textContent(rfs.selectSingleNode("/createRFS/ProblemType"));
				var problemAreas = FileIO.textContent(rfs.selectSingleNode("/createRFS/ProblemArea"));
				// Create directory for RFS.
				var mkdir = FileIO.createDirectory(rfsPath + rfsName);
				// Execute preprocessor.
				var exit = FileIO.execute(preprocessorPath, [problemType, problemAreas, rfsPath + rfsName], false, true, {
					poll: APICalls.contactGE.poll, timeout: APICalls.contactGE.timeout * 1000,
					exitHandler:
						function(exitObj) {
							// Regardless of result, continue to phase 2.
							PHASE_TWO();
						},
					timeoutHandler:
						function(exitObj) {
							// Regardless of result, continue to phase 2.
							PHASE_TWO();
						}
				}, interactive);
			}
			else
			{
				// Preprocessor could not be found/validated, continue.
				PHASE_TWO();
			}
		}
		else if (runPhases.preprocess)
		{
			// Error, RFS doesn't exist or can't capture RFS name, continue.
			PHASE_TWO();
		}
		else
		{
			// Go directly to phase 2.
			PHASE_TWO();
		}
	},
	
	// Use ConnectToGE API to set force polling
	// Return the translated error message if it fails
	forcePoll: function() {
		if (APICalls.useConnectToGE)
		{
			if (FileIO.Properties.isFile(APICalls.m_sConnectToGEPath) == false)
			{
				return APICalls.getString("ErrorConnectToGENotFound");
			}
			
			// Use ConnectToGE.exe to start force polling
			var args = new Array();
			args.push("-f");
			args.push(APICalls.forcePollPeriod);
			args.push("-t");
			args.push(APICalls.forcePollDuration);
			// Don't check on the exit code.  ConnectToGE.exe doesn't return any meaningful exit code.
			FileIO.execute(APICalls.m_sConnectToGEPath, args, true)
		}
		
		// Use "%INSITE2_HOME%\Temp\idunnNotify" log to notify Active Messaging RFS Icon state upon successful RFS send.
		FileIO.saveFile("..\\Temp\\idunnNotify", "ServiceIcon = 2");
	},
	
	// Load qsaconfig.xml file and return the SystemID (SerialNumber field)
	// Return "Agent Not Found" if qsaconfig.xml  is not found and return "Agent Not Configured" if MemberName is empty or "unknown"
	// Otherwise return the SystemID
	getSystemID: function()
	{
		if (FileIO.Properties.isFile(APICalls.getQSAConfigPath()))
		{
			var qsaConfigXML = FileIO.loadXML(APICalls.getQSAConfigPath());
			if (!qsaConfigXML)
			{
				alert("Error Loading Agent Configuration File");  
				return;
			}
			var oMemberName = qsaConfigXML.selectSingleNode("//ServiceAgentProfile/SerialNumber")
			var systemID;
			if (document.all)
				systemID = oMemberName.text; //IE
			else
				systemID = oMemberName.textContent;
			
			if (systemID == "" || systemID.match(/unknown/i) || systemID.match(/default/i))
				return "Agent Not Configured";
			else
				return systemID;
		}
		else
			return "Agent Not Found";
	},
	
	// Return the connection status by looking at qsaconfig.xml and qsaconfig.xml.booted files
	getConnectionStatus: function()
	{
		var systemID = APICalls.getSystemID();
		if (systemID != "Agent Not Found" && systemID != "Agent Not Configured")
		{
			if (FileIO.Properties.isFile(APICalls.getQSAConfigPath()+".booted"))
				return "Checked Out";
			else
				return "Not Checked Out";
		}
		else
			return systemID;
	},
	
	// Returns translated string from dictionary.xml according to the language configuration
	getString: function(sString)
	{	
		if (!APICalls.m_oStringsNode)
		{
			var dictXML = FileIO.loadXML("./xml/dictionary.xml");
			//dictXML.setProperty("SelectionLanguage", "XPath");
			var configXML = APICalls.getConfigXML();
			var lang = false;
			if (document.all)
				lang = configXML.selectSingleNode("//lang").text;
			else
				lang = configXML.selectSingleNode("//lang").textContent;
			APICalls.m_oStringsNode = dictXML.selectSingleNode("//strings[lang('" + lang + "')]");
			if (!APICalls.m_oStringsNode)
				return sString;
		}
		
		var oStringNode = APICalls.m_oStringsNode.selectSingleNode("string[@phrase='" + sString + "']");
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
		if (!APICalls.m_oConfigXMLDoc)
		{
			APICalls.m_oConfigXMLDoc = FileIO.loadXML("./xml/rfs_config.xml");
		}
		return APICalls.m_oConfigXMLDoc;
	}
}