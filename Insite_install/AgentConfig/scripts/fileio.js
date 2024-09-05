// FileIO Library: Contains functionality for handling XML/XSL documents.
//	  This library also contains functionality for managing plain text
//	  files as well as reading directories. This library is compatible
//	  with Internet Explorer and Firefox/Mozilla. All paths used in the
//	  library accept either absolute or relative paths.
//	Version:     1.4.2c
//	Author(s):   Andy Kant (Andrew.Kant@ge.com)
//	             Al Kuhn (Alan.Kuhn@ge.com, contributor)
//	             Jung Oh (Jung.Oh@ge.com, contributor)
//	Date:        Jun.12.2006
//	Modified:   Jun.13.2007
//	Changelog:
//		Jun.13.2007 UPDATED FileIO.execute INTERFACE (v1.4.2c):
//                        FileIO.execute(path[, args][, block][, normalize][, async][, interactive]);
//                        If the optional "interactive" parameter is set, fileio.exe will execute the command 
//                        without hiding the window.  This is for interactive RFS preprocessors not wrapped by a batch file.
//		Apr.03.2007   Increased FileIO.AJAX_POLL_TIMEOUT to 20 seconds (v1.4.2b).
//		Feb.15.2007   Fixed memory-leaking AJAX calls in the FileIO.loadRemoteXML and FileIO.loadRemoteFile 
//		                methods. Added FileIO.AJAX_POLL_RATE (default 50ms) and FileIO.AJAX_POLL_TIMEOUT 
//		                (default 5000ms) constants to define the poll rate and timeout for AJAX calls. Added 
//		                FileIO._poll as an internal variable that is used to handle AJAX polling. Updated 
//		                debug console to v1.1 which fixes some issues (v1.4.2).
//		Dec.07.2006   FileIO.textContent returned incorrectly if it contained an empty string (v1.4.1f).
//		Oct.10.2006   Made adjustments for certain security settings in Internet Explorer to FileIO.saveXML
//		                and FileIO.saveFile (v1.4.1e).
//		Oct.10.2006   Added DOMDocument.Save support for FileIO.saveXML to enable saving in UTF-8 for cases
//		                where the ADODB object is not present in Internet Explorer. On a related note, if 
//		                the ADODB object is not present, FileIO.saveFile will save in ASCII instead of 
//		                UTF-8. Also added the FileIO.HAS_ADODB boolean constant (v1.4.1d).
//		Oct.04.2006   Fixed FileIO.execute issue in the async controller where the adjacent method (i.e. kill
//		                for poll and poll for kill) would sometimes fire even after the process has 
//		                finished execution or has been killed (1.4.1c).
//		Oct.02.2006   Fixed some FileIO.execute logic as well as changed what the method returns. The method
//		                will now ALWAYS return an object containing the "failure" property (boolean). If
//		                "block" = false, this does not guarantee that the process will succeed. This will
//		                not be known until the "exit_object" is passed to either of the exit or timeout 
//		                handlers. IMPORTANT: The "failure" property is based on whether or not the 
//		                "exitCode" is equal to zero. If it isn't zero, "failure" will be true. If an
//		                application returns exit codes that are successful even when they are not set to
//		                zero, they must be checked manually. An exit code with a value of
//		                FileIO.EXITCODE_ERROR can be assumed to always be a failure because that is a value
//		                used internally by fileio.exe and FileIO.execute. The data passed to the handlers 
//		                has changed, see the documentation for FileIO.execute for the new interface/result 
//		                objects (v1.4.1b).
//		Sep.26.2006   Added FileIO.createDirectory and FileIO.deleteDirectory (v1.4.1). In the future, the
//		                FileIO.create/delete methods will probably be moved to a FileIO.Operations 
//		                sub-library along with adding methods for copy/move. The interfaces to the old
//		                methods will still be accessible, but will be deprecated.
//		              Updated fileio.exe to support calling applications without needing a path (use PATH 
//		                environment variable instead). Also updated FileIO.execute to support applications 
//		                in PATH by adding an extra parameter, "normalize" (boolean). "normalize" will 
//		                default to true and generate the path dynamically if true. By setting "normalize" 
//		                to false, the FileIO.execute method will keep the path verbatim. The position of the
//		                "normalize" argument replaces "async" since that interface has only been around a
//		                weekend anyways and this interface makes more sense.
//		                	UPDATED FileIO.execute INTERFACE:
//		                		FileIO.execute(path[, args][, block][, normalize][, async]);
//		              Added optional "executable" parameter to FileIO.saveFile. This will set the permissions
//		                to 0755 in Mozilla (for Linux) instead of 0644. Updated FileIO.execute to use this.
//		Sep.22.2006		Changed version numbering scheme (v1.4.0).
//		                Example: v1.4.0b
//		                	[v1][.4][.0][b]
//		                		v1 = major structural change
//		                		.4 = major feature addition/change revision
//		                		.0 = minor feature addition/change revision
//		                		b = bug fix revision (only present for bug fix revisions)
//		              Added a debug console for Internet Explorer and Mozilla Firefox without Firebug. 
//		                This will allow for easy debugging messages in Internet Explorer or Mozilla
//		                Firefox without being annoyed by console.logs. If Firefox with the Firebug extension 
//		                installed is being used, it will just use the Firebug version of the console.
//		                The display of all console/debug messages is triggered by the console.DEBUG property.
//		                If debugging should be enabled, it should be changed programmatically instead
//		                of editing fileio.js directly. Console references can be left in the development
//		                versions of files but should be removed from the production versions or have the
//		                console.DEBUG property set to false. Also created a standalone version that doesn't
//		                require FileIO.
//		                USAGE:
//		                	console.DEBUG = true;
//		                	console.log(var1, var2, var3, ...);
//		                	console.info(var1, var2, var3, ...);
//		                	console.warn(var1, var2, var3, ...);
//		                	console.error(var1, var2, var3, ...);
//		              Added asynchronous (non-blocking) support to FileIO.execute. The most IMPORTANT note
//		                about asynchronous support is that it does not currently work in Mozilla, however,
//		                the effect is simulated (it just still runs in block mode). Asynchronous support
//		                for Mozilla is implemented, but the implementation requires a value to poll on
//		                that changes when the application exits, which is not currently available in
//		                Mozilla. The FileIO library now ncludes the fileio.exe application wrapper which 
//		                may be used to launch console applications as hidden. This is required for Mozilla 
//		                Firefox in Windows and is required for non-blocking (asynchronous) mode in Internet 
//		                Explorer. The source code is included in "app_wrapper" directory. The fileio.exe 
//		                application wrapper will automatically be used when an application is executed from 
//		                a Windows system for FileIO.execute. Also added "async" parameter which, if present, 
//		                must be an object with the following structure:
//		                	async = {
//		                		poll: 2000,       // Time in milliseconds (2.0s)
//		                		timeout: 10000,   // Time in milliseconds (10.0s)
//		                		exitHandler:      // Method to receive exit code call.
//		                			function(exitCode, hash) {..},
//		                		timeoutHandler:   // Method to receive timeout call.
//		                			function(hash) {..}
//		                	}
//		                The "async" parameter is optional but recommended whenever blocking is disabled
//		                (a.k.a. asynchronous). When blocking is disabled and the "async" object is present,
//		                the following object will be returned by the FileIO.execute method:
//		                	{ hash: <hash>, kill: function(){<method_to_kill_polling_and_process>} }
//		                The kill method that is returned will have no effect after a process has
//		                terminated (whether called by the kill method or by the process finishing or timing
//		                out) because the process controller object will destroy itself to free memory.
//		                IMPORTANT: Each asyncronous/non-blocking execution call MUST return an exit code.
//		                Exit code integers that are returned for asynchronous processes may not
//		                return a value of -2147483648 or 2147483647; these are reserved values. -2147483648
//		                is the value returned when the wrapper fails to execute an application and 
//		                2147483647 is a placeholder for the default exit code value that is checked for 
//		                change in order to determine if an application finished in Mozilla Firefox. 
//		                Asynchronous support in Mozilla Firefox is not currently supported (although the 
//		                support is simulated properly so an asynchronous call may still be used) due to 
//		                Firefox never updating any values that could be polled against (such as exit 
//		                code). The hash that is passed does not need to be implemented by the handler 
//		                functions, but is there to provide support in the case that multiple processes 
//		                have been invoked and are being tracked using the same function objects. The 
//		                "async" object serves no purpose when blocking is enabled.
//		                	FileIO Hidden Console Application Wrapper
//		                		USAGE: fileio.exe "c:\full\path\to\application.exe" "other" "arguments"
//		                		WARNING: Any console applications that require user input or never exit 
//		                			will cause fileio.exe to never exit.
//		                		IMPORTANT: fileio.exe must reside in the same directory as fileio.js.
//		              Fixed a bug with parameters not being passed correctly for FileIO.execute in Mozilla
//		                Firefox. Mozilla now requires that a batch file be created dynamically at runtime 
//		                in cases where parameters are being passed.
//		              Fixed a bug with parameters not being passed for FileIO.execute in Internet Explorer.
//		Sep.13.2006		Added parameters support to FileIO.transformXML (via Al Kuhn, v1.37).
//		Sep.12.2006		Added onComplete parameter to FileIO.loadRemoteXML/loadRemoteFile to allow for
//		                asynchronous data returns. If the AJAX request was successfully created, the
//		                functions will return true and will call the onComplete function with the resulting
//		                object once it arrives (will still return false if it fails). The resulting
//		                object can be retrieved through the first parameter of the onComplete function (v1.36).
//		              Fixed a bug with FileIO.loadRemoteXML/loadRemoteFile where the methods did
//		                not return false when a 404 was returned by the server. The methods will now
//		                return false whenever the HTTP status is not 200 (the normal value).
//		Sep.11.2006		Removed FileIO.utfEncode and FileIO.utfDecode because they served no purpose (v1.35c).
//		              Fixed UTF-8 write support, now works all the time with Mozilla and in HTA 
//		                mode for Internet Explorer. When in non-HTA mode for Internet Explorer, 
//		                the library will save in ASCII with UTF-8 escape sequences substituted 
//		                in place of UTF-8 characters.
//		Sep.08.2006		Fixed UTF-8 support, old method had problems on some string sequences (v1.35b).
//		Sep.06.2006		Added mandatory UTF-8 support to save/load methods (v1.35).
//		              Added FileIO.execute method (via Jung Oh).
//		              Added FileIO.utfEncode and utfDecode methods.
//		Aug.30.2006		Added FileIO.loadRemoteFile (AJAX) method (v1.34).
//		              Added FileIO.textContent to read the inner text of XML elements.
//		              Fixed bug in FileIO.loadRemoteXML.
//		Aug.28.2006		Added FileIO.loadRemoteXML (AJAX) method (v1.33).
//		Aug.25.2006		Added FileIO.IS_WINDOWS constant (v1.32).
//		              Fixed spaces in relative paths bug.
//		Aug.09.2006		Added FileIO.validateXML (only works in IE, v1.31).
//		Jul.11.2006		Added FileIO.Test unit testing suite (v1.30).
//		              Added FileIO.Properties.isFile and isDirectory methods.
//		              Changed FileIO.normalizePath to automatically fix relative paths as necessary.
//		Jul.10.2006		Added FileIO.deleteFile method (v1.21).
//		Jul.07.2006		Added FileIO.Properities sub-library (v1.2).
//		Jul.06.2006		Renamed library to FileIO (v1.1).
//		              Added FileIO.listDirectory method.
//		Jun.27.2006		Fixed some bugs (v1.0b).
//		Jun.12.2006		Initial revision (v0.1).
/*
	USAGE:
	Add this code at the beginning of the <head> section of your webpage (updating path as necessary):
		<script src="./scripts/fileio.js" type="text/javascript"></script>
	DEBUG CONSOLE:
		DESCRIPTION:
			The debug console provides functionality similar to debugging with Firebug in Mozilla Firefox
			without needing to have Firebug/Firefox installed. Debug messages will only be displayed if 
			console.DEBUG = true. It is recommended to change this value programmatically rather than 
			directly inside fileio.js. If Firebug is installed, the console will use that for displaying 
			messages instead. Otherwise, the debug console is an area that will show up at the top of the
			page upon encountering the first console logging call. This area can be clicked to collapse the
			console, and clicked again to expand it. This supports both Internet Explorer and Mozilla Firefox
			and can be used to avoid using annoying console.logs in order to debug.
		USAGE:
			console.DEBUG = true;
			console.log(var1, var2, var3, ...);
			console.info(var1, var2, var3, ...);
			console.warn(var1, var2, var3, ...);
			console.error(var1, var2, var3, ...);
	METHODS:
		FileIO.loadRemoteXML(url[, onComplete]);
			DESCRIPTION: Load a remote XML document.
				Returns a DOM XML document created from the content located at "url."
				The onComplete parameter is OPTIONAL. If onComplete is used, it must be a function. The
				FileIO.loadRemoteXML will return as true if the onComplete parameter is a function and will
				trigger asynchronous mode. Once the data has been retrieved from the server, it will be 
				passed to the onComplete function. The resulting object can be accessed by using 
				the first parameter of the onComplete function.
			USAGE:
				FileIO.loadRemoteXML("./cgi-bin/config.pl");
				FileIO.loadRemoteXML("./cgi-bin/config.pl", function(xml) {
					console.log("XML Result: " + xml);
					});
			PARAMETERS:
				url          The path to the XML document.
				onComplete   The function that will handle the resulting object once it has been
				             returned asynchronously. [OPTIONAL]
		FileIO.loadXML(path);
			DESCRIPTION: Load an XML document.
				Returns a DOM XML document created from the file located at "path."
			USAGE:
				FileIO.loadXML("./xml/rfs_config.xml");
			PARAMETERS:
				path         The path to the XML document.
		FileIO.saveXML(path, xml_doc);
			DESCRIPTION: Save an XML document.
				Saves a DOM XML document to "path."
			USAGE:
				FileIO.saveXML("./xml/rfs_recent.xml");
			PARAMETERS:
				path         The path to the XML document.
				xml_doc      The DOM XML document object to save.
		FileIO.loadRemoteFile(url[, onComplete]);
			DESCRIPTION: Load a remote document.
				Returns a string created from the content located at "url."
				The onComplete parameter is OPTIONAL. If onComplete is used, it must be a function. The
				FileIO.loadRemoteFile will return as true if the onComplete parameter is a function and will
				trigger asynchronous mode. Once the data has been retrieved from the server, it will be 
				passed to the onComplete function. The resulting object can be accessed by using 
				the first parameter of the onComplete function.
			USAGE:
				FileIO.loadRemoteFile("./styles/base.css");
				FileIO.loadRemoteFile("./styles/base.css", function(file) {
					console.log("File Result: " + file);
					});
			PARAMETERS:
				url          The path to the document.
				onComplete   The function that will handle the resulting object once it has been
				               returned asynchronously. [OPTIONAL]
		FileIO.loadFile(path);
			DESCRIPTION: Load a document.
				Returns a string created from the file located at "path."
			USAGE:
				FileIO.loadFile("somefile.txt");
			PARAMETERS:
				path         The path to the document.
		FileIO.saveFile(path, text[, executable]);
			DESCRIPTION: Save a document.
				Saves "text" to the file "path."
			USAGE:
				FileIO.saveFile("./log/something.txt");
			PARAMETERS:
				path         The path to the document.
				text         The string to save.
				executable   Makes the file executable (for Mozilla on Linux systems). [OPTIONAL]
		FileIO.deleteFile(path);
			DESCRIPTION: Delete a document.
				Deletes file at "path." Mozilla cannot delete read-only files.
			USAGE:
				FileIO.deleteFile("./log/something.txt");
			PARAMETERS:
				path         The path to the document.
		FileIO.createDirectory(path);
			DESCRIPTION: Creates a directory.
				Create directory at "path."
			USAGE:
				FileIO.createDirectory("./tmp_dir");
			PARAMETERS:
				path         The path to the directory.
		FileIO.deleteDirectory(path);
			DESCRIPTION: Delete a directory.
				Deletes directory at "path." Mozilla cannot delete read-only directories.
			USAGE:
				FileIO.deleteDirectory("./tmp_dir");
			PARAMETERS:
				path         The path to the directory.
		FileIO.listDirectory(path);
			DESCRIPTION: List the contents of a directory.
				Returns an object containing the following properties:
					path       Normalized path to the directory that was listed.
					files      Filenames for each file in the directory.
					folders    Folder names for each folder in the directory.
			USAGE:
				FileIO.listDirectory("D:\\Projects\\RFS\\code\\queue\\MRFS*.xml");
			PARAMETERS:
				path         The path to the directory.
		FileIO.transformXML(xml, xsl[, parameters]);
			DESCRIPTION: Transform an XML document with an XSL document.
				Transforms "xml" with the "xsl" stylesheet.
				Returns a string containing the XSL-processed result.
				If parameters is specified, it will pass on the parameters to the XSL stylesheet;
				this argument is OPTIONAL. The parameters object must be an object literal where the
				keys correspond to parameter names and the values correspond to parameter values.
			USAGE:
				FileIO.transformXML(FileIO.loadXML("data.xml"), FileIO.loadXML("table.xsl"));
				FileIO.transformXML(FileIO.loadXML("data.xml"), FileIO.loadXML("table.xsl"), 
					{paramname: "paramvalue", anotherparamname: 37});
			PARAMETERS:
				xml          The XML DOM document object to transform.
				xsl          The XML DOM document stylesheet to transform with.
				parameters   Parameters to pass on to the XSL stylesheet (object literal). [OPTIONAL]
		FileIO.validateXML(xml_path, xsd_path);
			DESCRIPTION: Validates an XML document with an XSD document.
				Validates XML document at "xml_path" with the XSD document at "xsd_path."
				This is ONLY SUPPORTED in Internet Explorer.
				Returns true if the XML document is valid and false if it is invalid.
			USAGE:
				var xml = FileIO.getDOMDocument();
			PARAMETERS:
				xml_path     The path to the XML document to be validated.
				xsd_path     The path to the XSD schema to validate against.
		FileIO.getDOMDocument();
			DESCRIPTION: Get a DOM XML document.
				Returns a DOM XML document.
			USAGE:
				var xml = FileIO.getDOMDocument();
		FileIO.makeDOMDocument(xml_string);
			DESCRIPTION: Make a DOM XML document.
				Returns a DOM XML document created from "xml_string."
			USAGE:
				FileIO.makeDOMDocument("<root><item>1</item><item>2</item></root>");
			PARAMETERS:
				xml_string   The string to convert into a DOM XML document.
		FileIO.makeDOMString(xml_doc);
			DESCRIPTION: Make a DOM XML string.
				Returns a string created from the DOM XML document, "xml_doc."
			USAGE:
				FileIO.makeDOMString(FileIO.loadXML("data.xml"));
			PARAMETERS:
				xml_doc      The DOM XML document to convert to a string.
		FileIO.execute(path[, args][, block][, normalize][, async]);
			DESCRIPTION: Execute an external application.
				Any exit code that isn't zero (0) should be considered a failure.
				Failure should be tested for using the "failure" property, however, "failure"
					being set to false when "block" = false does not guarantee that the
					execution will be successful.
				Returns the following if "block" = true:
					{
						exitCode: <exit_code_integer>,   // The exit code returned by the process.
						failure: <boolean>               // Whether or not the process failed.
					}
				Returns the following if "block" = false:
					{
						failure: <boolean>,              // Whether or not the process failed.
						                                 //   "failure" = false does NOT ensure success.
						hash: <string>,                  // Unique identifier.
						kill: <function>;                // Method to kill process.
					}
				Passed to exit/timeout handlers after execution if "block" = false:
					<exit_object> {
						exitCode: <exit_code_integer>,   // The exit code returned by the process.
						failure: <boolean>,              // Whether or not the process failed.
						hash: <string>,                  // Unique identifier.
					}
			USAGE:
				FileIO.execute("application.exe");
				FileIO.execute("application.exe", ["-ro", "c:/monitor.log"]);
				FileIO.execute("application.exe", ["-ro", "c:/monitor.log"], true);
				FileIO.execute("application.exe", ["-ro", "c:/monitor.log"], true, false);
				FileIO.execute("application.exe", ["-ro", "c:/monitor.log"], false, true, {
						poll: 2000,       // Time in milliseconds (2.0s)
						timeout: 10000,   // Time in milliseconds (10.0s)
						exitHandler:      // Method to receive exit code call.
							function(exit_object) {..},
						timeoutHandler:   // Method to receive timeout call.
							function(exit_object) {..}
					});
			PARAMETERS:
				path         Path to executable.
				args         Array of strings containing arguments (or null). [OPTIONAL]
				               Defaults to null.
				block        Whether or not to block until the operation completes (boolean).
				               Defaults to true. [OPTIONAL]
				normalize    Whether or not to normalize/resolve the path of an executable (boolean). 
				               Defaults to true. [OPTIONAL]
				async        Required when block = false. Requires the following structure: [OPTIONAL]
				               async = {
				              	poll: 2000,			// Time in milliseconds (2.0s)
				              	timeout: 10000,		// Time in milliseconds (10.0s)
				              	exitHandler: 		// Method to receive exit code call.
				              		function(<exit_object>) {..},
				              	timeoutHandler: 	// Method to receive timeout call.
				              		function(<exit_object>) {..}
				              }
		FileIO.textContent(element);
			DESCRIPTION: Read text from an XML element.
				Returns a string containing the inner text value for an XML element.
			USAGE:
				FileIO.textContent(xml_node);
			PARAMETERS:
				element      The DOM XML element to read the value from.
		FileIO.utfEncode(ascii_string);
			DESCRIPTION: Encode an ASCII string in UTF-8.
				Returns a string encoded in UTF-8 using a ASCII base.
			USAGE:
				FileIO.utfEncode("some string");
			PARAMETERS:
				ascii_string   The ASCII string to encode.
		FileIO.utfDecode(utf_string);
			DESCRIPTION: Decode a UTF-8 string to ASCII.
				Returns a string encoded in ASCII using a UTF-8 base.
			USAGE:
				FileIO.utfDecode("some string");
			PARAMETERS:
				utf_string   The ASCII string to encode.
		FileIO.normalizePath(path, url);
			DESCRIPTION: Fix path for local files.
				Returns an absolute path to the file at "path" using the URL.
				Appends a file:/// address if "url" is set to true.
				Note: Do NOT specify the path starting with a slash (/)
					unless it is an absolute path. Precede the slash with
					a period to signify the current directory (./) for a
					relative path or leave it off completely.
			USAGE:
				FileIO.normalizePath("queue/something.xml");
			PARAMETERS:
				path         The path to the file.
				url          Only needs to be included and set to true if a 
				               URL (file:///) address is wanted.
	FileIO.Properties METHODS:
		FileIO.Properties.lastModified(path);
			DESCRIPTION: Get the last modified date/time of a file.
				Returns the last modified date/time of the file at "path."
			USAGE:
				FileIO.Properties.lastModified("D:\\Projects\\somedocument.xml");
			PARAMETERS:
				path         The path to the file.
		FileIO.Properties.size(path);
			DESCRIPTION: Get the size of a file.
				Returns the size of the file at "path."
			USAGE:
				FileIO.Properties.size("D:\\Projects\\somedocument.xml");
			PARAMETERS:
				path		The path to the file.
		FileIO.Properties.isFile(path);
			DESCRIPTION: Checks if the file exists and is an actual file.
				Returns true if the file exists and is a file.
			USAGE:
				FileIO.Properties.isFile("D:\\Projects\\somedocument.xml");
			PARAMETERS:
				path         The path to the file.
		FileIO.Properties.isDirectory(path);
			DESCRIPTION: Checks if the directory exists and is an actual directory.
				Returns true if the directory exists and is a directory.
			USAGE:
				FileIO.Properties.isDirectory("D:\\Projects");
			PARAMETERS:
				path         The path to the directory.
*/

// Add cross-browser XPath selection methods. (from http://km0ti0n.blunted.co.uk/mozXPath.xap)
if (document.implementation.hasFeature("XPath", "3.0"))
{
	XMLDocument.prototype.selectNodes = function(cXPathString, xNode)
	{
		if (!xNode)
			xNode = this;
		var oNSResolver = this.createNSResolver(this.documentElement);
		var aItems = this.evaluate(cXPathString, xNode, oNSResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
		var aResult = [];
		for (var i = 0; i < aItems.snapshotLength; i++)
			aResult[i] = aItems.snapshotItem(i);
		return aResult;
	}
	Element.prototype.selectNodes = function(cXPathString)
	{
		if (this.ownerDocument.selectNodes)
			return this.ownerDocument.selectNodes(cXPathString, this);
		else
			return false;
	}
	XMLDocument.prototype.selectSingleNode = function(cXPathString, xNode)
	{
		if(!xNode)
			xNode = this;
		var xItems = this.selectNodes(cXPathString, xNode);
		if(xItems.length > 0)
			return xItems[0];
		else
			return false;
	}
	Element.prototype.selectSingleNode = function(cXPathString)
	{
		if (this.ownerDocument.selectSingleNode)
			return this.ownerDocument.selectSingleNode(cXPathString, this);
		else
			return false;
	}
}

// Add console for debugging, encapsulating it based on console.DEBUG value.
//	Version:     1.1
//	Author(s):   Andy Kant (Andrew.Kant@ge.com)
//	Date:        Sep.22.2006
//	Modified:    Feb.15.2007
{
	// Add simple console object if applicable (otherwise use Firebug for Firefox).
	if (/^undefined$/i.test(typeof window.console))
	{
		var consoleFactory = function(name) {
			if (name == 'time')
				return function() { window['console'].timers[arguments[0]] = new Date().getTime(); };
			else if (name == 'timeEnd') {
				return function() {
					var tmp = ['&nbsp;'];
					tmp.push(arguments[0] + ': ' + (new Date().getTime() - window['console'].timers[arguments[0]]) + 'ms');
					window.console._log('time',tmp.join(''));
				};
			} else {
				return function() {
					var tmp = ['&nbsp;'];
					if (!name.match(/^(profile|profileEnd)$/)) {
						for (var i = 0; i < arguments.length; i++)
							tmp.push(arguments[i].toString() + " ");
						window.console._log(name,tmp.join(''));
					}
				};
			}
		};
		window.console = new function() {
			this.log = new consoleFactory("log");
			this.info = new consoleFactory("info");
			this.warn = new consoleFactory("warn");
			this.error = new consoleFactory("error");
			this.time = new consoleFactory("time");
			this.timeEnd = new consoleFactory("timeEnd");
			this.profile = new consoleFactory("profile");
			this.profileEnd = new consoleFactory("profileEnd");
			this.firebug = false;
		};
	}
	else
		window.console.firebug = true;
	// Make sure this wrapper hasn't already been created.
	if (/^undefined$/i.test(typeof window.console.console))
	{
		// Duplicate console an wrap it.
		var newConsoleFactory = function(name) {
			return function() {
				if (this.DEBUG)
				{
					this.init();
					for (var i = 0; i < arguments.length; i++)
					{
						if (document.all && /^object$/i.test(typeof arguments[i]) 
						&& /^string$/i.test(typeof arguments[i].name)
						&& /^string$/i.test(typeof arguments[i].message))
							arguments[i] = arguments["+i+"].name + ": " + arguments["+i+"].message;
					}
					this.console[name].apply(this.console, arguments);
				}
			};
		};
		var _oldConsole = window.console;
		window.console = new function() {
			this.console = _oldConsole;
			this.DEBUG = false;
			this.timers = {};
			this.init = function() {
				if (!this.console.firebug && !document.getElementById("debug_console"))
				{
					var con = document.createElement("DIV");
					document.body.appendChild(con);
					var con_holder = document.createElement("DIV");
					con.appendChild(con_holder);
					con_holder.margin = "0px";
					con_holder.padding = "0px";
					con.id = "debug_console";
					con.collapsed = false;
					con.style.zIndex = 1000000;
					con.style.position = "absolute";
					con.style.top = "0px";
					con.style.left = "0px";
					con.style.width = "100%";
					con.style.margin = "0px";
					con.style.padding = "0px";
					con.style.borderBottom = "1px solid #999";
					con.style.backgroundColor = "#F6F6F6";
					con.style.height = "200px";
					con.style.overflow = "auto";
					con.style.cursor = "pointer";
					if (document.all)
					{
						con.style.left = document.body.currentStyle.marginLeft;
						if (!/^0/.test(con.style.left))
						{
							con.style.borderLeft = con.style.borderBottom;
							con.style.borderRight = con.style.borderBottom;
						}
					}
					con.onclick = function() {
						var holder = this.getElementsByTagName('div')[0];
						if (this.collapsed)
						{
							this.style.height = "200px";
							this.style.backgroundColor = "#F6F6F6";
							this.style.overflow = "auto";
							holder.style.display = "block";
						}
						else
						{
							this.style.height = "4px";
							this.style.backgroundColor = "#C6C6C6";
							this.style.overflow = "hidden";
							holder.style.display = "none";
						}
						this.collapsed = !this.collapsed;
					};
				}
			};
			this.log = new newConsoleFactory("log");
			this.info = new newConsoleFactory("info");
			this.warn = new newConsoleFactory("warn");
			this.error = new newConsoleFactory("error");
			this.time = new newConsoleFactory("time");
			this.timeEnd = new newConsoleFactory("timeEnd");
			this.profile = new newConsoleFactory("profile");
			this.profileEnd = new newConsoleFactory("profileEnd");
		};
		window.console._log = function(type, text) {
			var con = document.getElementById("debug_console");
			var holder = con.getElementsByTagName('div')[0];
			var entry = document.createElement("DIV");
			entry.innerHTML = "<span style=\"display: block; float: left; width: 5em; font-weight: bold;\">" 
				+ type.toUpperCase() + "&nbsp;&nbsp&nbsp;</span>" + text;
			entry.style.margin = "0px";
			entry.style.padding = "2px 5px";
			entry.style.borderBottom = "1px solid #D6D6D6";
			if (/^log$/i.test(type))
				entry.style.color = "#000";
			else if (/^info$/i.test(type))
				entry.style.color = "#00F";
			else if (/^warn$/i.test(type))
				entry.style.backgroundColor = "#FF9";
			else if (/^error$/i.test(type))
				entry.style.backgroundColor = "#F99";
			holder.appendChild(entry);
			if (con.collapsed) {
				con.style.height = "200px";
				con.style.backgroundColor = "#F6F6F6";
				con.style.overflow = "auto";
				holder.style.display = "block";
			}
		};
	}
}

// FileIO Library
var FileIO = {
	// Constants.
	IS_WINDOWS: /win/i.test(navigator.userAgent.toLowerCase()),
	IS_HTA: document.all ? (function() {
		var owner = window;
		while (owner.frameElement != null)
			owner = owner.parent;
		return /\.hta$/i.test(owner.location);
	})() : false,
	HAS_ADODB: document.all ? (function() {
		try { var adodb = new ActiveXObject("ADODB.Stream"); return true; }
		catch(e) { return false; }
	})() : false,
	EXITCODE_ERROR: -2147483648, // (max negative signed 32-bit integer)
	EXITCODE_RESET: 2147483647, // (max positive signed 32-bit integer)
	WRAPPER_PATH: (function(){
		var scripts = document.getElementsByTagName("SCRIPT");
		for (var i = 0; i < scripts.length; i++)
		{
			if (/fileio[^\\\/]*?\.js$/i.test(scripts[i].src))
			{
				if (document.all)
					return scripts[i].src.replace(/(fileio)[^\\\/]*?\.js$/i, "$1.exe");
				else
				{
					var url = window.location.toString();
					return scripts[i].src.replace(url.substr(0, url.lastIndexOf("/") + 1), "").replace(/(fileio)[^\\\/]*?\.js$/i, "$1.exe");
				}
			}
		}
	})(),
	ENABLE_MOZILLA_EXECUTE_ASYNC: false,
	AJAX_POLL_RATE: 50,
	AJAX_POLL_TIMEOUT: 20000,
	// Internal variables.
	_poll: {},
	
	// Load a remote XML document.
	//	Returns a DOM XML document created from the content located at "url."
	//	The onComplete parameter is OPTIONAL. If onComplete is used, it must be a function. The
	//	FileIO.loadRemoteXML will return as true if the onComplete parameter is a function and will
	//	trigger asynchronous mode. Once the data has been retrieved from the server, it will be 
	//	passed to the onComplete function. The resulting object can be accessed by either using 
	//	the first parameter of onComplete or by using the "this" pointer. WARNING: If the "this"
	//	pointer is used, the typeof of the returned data will always be "object."
	loadRemoteXML: function(url, onComplete) {
		var xml = false;
		onComplete = /^function$/i.test(typeof onComplete) ? onComplete : false;
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
/*		if (window.XMLHttpRequest && window.XSLTProcessor)
		{
			try
			{
				try { xml = new XMLHttpRequest(); }
				catch(e) { console.warn(e); return false; }
				xml.open("GET", url, onComplete ? true : false);
				if (onComplete)
				{
					var pollFn = function() {
						if (xml.readyState == 4) {
							window.clearInterval(FileIO._poll[url]);
							delete FileIO._poll[url];
							var result = (xml.status == 200 || xml.status == 304 || xml.status == 0) && xml.responseXML != null ? xml.responseXML : false;
							onComplete.call(result, result);
							xml = null;
							onComplete = null;
						}
					}
					FileIO._poll[url] = setInterval(pollFn, FileIO.AJAX_POLL_RATE);
					setTimeout(function() {
						try {
							window.clearInterval(FileIO._poll[url]);
							xml = null;
							onComplete = null;
						} catch(e) {};
					}, FileIO.AJAX_POLL_TIMEOUT);
					xml.send("");
					return true;
				}
				else
				{
					xml.send("");
					return (xml.status == 200 || xml.status == 304 || xml.status == 0) && xml.responseXML != null ? xml.responseXML : false;
				}
			}
			catch(e) { return false; }
		}
		else */ if (window.ActiveXObject)
		{
			try
			{
				var xml = false;
				try { xml = new ActiveXObject("Msxml2.XMLHTTP"); }
				catch(e)
				{
					try { xml = new ActiveXObject("Microsoft.XMLHTTP"); } 
					catch(e) { console.warn(e); return false; }
				}
				if (xml)
				{
					xml.open("GET", url, onComplete ? true : false);
					if (onComplete)
					{
						var pollFn = function() {
							if (xml.readyState == 4) {
								window.clearInterval(FileIO._poll[url]);
								delete FileIO._poll[url];
								var result = (xml.status == 200 || xml.status == 304 || xml.status == 0) ? FileIO.makeDOMDocument(xml.responseText) : false;
								onComplete.call(result, result);
								xml = null;
								onComplete = null;
							}
						}
						FileIO._poll[url] = setInterval(pollFn, FileIO.AJAX_POLL_RATE);
						setTimeout(function() {
							try {
								window.clearInterval(FileIO._poll[url]);
								xml = null;
								onComplete = null;
							} catch(e) {};
						}, FileIO.AJAX_POLL_TIMEOUT);
						xml.send("");
						return true;
					}
					else
					{
						xml.send("");
						return (xml.status == 200 || xml.status == 304 || xml.status == 0) ? FileIO.makeDOMDocument(xml.responseText) : false;
					}
				}
				else
					return false;
			}
			catch(e) { return false; }
		}
		return false;
		//return xml;
	},
	
	// Load an XML document.
	//	Returns a DOM XML document created from the file located at "path."
	loadXML: function(path) {
		var xml = false;
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
/* 
		if (window.XMLHttpRequest && window.XSLTProcessor)
		{
			path = FileIO.normalizePath(path, true);
			try
			{
				try { xml = new XMLHttpRequest(); }
				catch(e) { console.warn(e); return false; }
				xml.open("GET", path, false);
				xml.send(null);
				return xml.responseXML;
			}
			catch(e) { console.warn(e); return false; }
		}
		else */ if (window.ActiveXObject)
		{
			path = FileIO.normalizePath(path);
			try
			{
				xml = FileIO.getDOMDocument();
				xml.load(path);
				try { xml.setProperty("SelectionLanguage", "XPath"); xml.setProperty("SelectionNamespaces", "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'"); }
				catch(e) { return false; }
				return xml;
			}
			catch(e) { console.warn(e); return false; }
		}
		return false;
		//return xml;
	},
	
	// Save an XML document.
	//	Saves a DOM XML document to "path."
	saveXML: function(path, xml_doc) {
		if (document.all)
		{
			// Attempt to save without ADODB in Internet Explorer.
			try
			{
				xml_doc.save(FileIO.normalizePath(path));
				return true;
			}
			catch(e) { }
		}
		return FileIO.saveFile(path, FileIO.makeDOMString(xml_doc));
	},
	
	// Load a remote document.
	//	Returns a string created from the content located at "url."
	//	The onComplete parameter is OPTIONAL. If onComplete is used, it must be a function. The
	//	FileIO.loadRemoteFile will return as true if the onComplete parameter is a function and will
	//	trigger asynchronous mode. Once the data has been retrieved from the server, it will be 
	//	passed to the onComplete function. The resulting object can be accessed by either using 
	//	the first parameter of onComplete or by using the "this" pointer. WARNING: If the "this"
	//	pointer is used, the typeof of the returned data will always be "object."
	loadRemoteFile: function(url, onComplete) {
		var xml = false;
		onComplete = /^function$/i.test(typeof onComplete) ? onComplete : false;
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
/*		if (window.XMLHttpRequest && window.XSLTProcessor)
		{
			try
			{
				try { xml = new XMLHttpRequest(); }
				catch(e) { return false; }
				xml.open("GET", url, onComplete ? true : false);
				if (onComplete)
				{
					var pollFn = function() {
						if (xml.readyState == 4) {
							window.clearInterval(FileIO._poll[url]);
							delete FileIO._poll[url];
							var result = (xml.status == 200 || xml.status == 304 || xml.status == 0) && xml.responseText != null ? xml.responseText : false;
							onComplete.call(result, result);
							xml = null;
							onComplete = null;
						}
					}
					FileIO._poll[url] = setInterval(pollFn, FileIO.AJAX_POLL_RATE);
					setTimeout(function() {
						try {
							window.clearInterval(FileIO._poll[url]);
							xml = null;
							onComplete = null;
						} catch(e) {};
					}, FileIO.AJAX_POLL_TIMEOUT);
					xml.send("");
					return true;
				}
				else
				{
					xml.send("");
					return (xml.status == 200 || xml.status == 304 || xml.status == 0) && xml.responseText != null ? xml.responseText : false;
				}
			}
			catch(e) { return false; }
		}
		else */ if (window.ActiveXObject)
		{
			try
			{
				var xml = false;
				try { xml = new ActiveXObject("Msxml2.XMLHTTP"); }
				catch(e)
				{
					try { xml = new ActiveXObject("Microsoft.XMLHTTP"); } 
					catch(e) { return false; }
				}
				if (xml)
				{
					xml.open("GET", url, onComplete ? true : false);
					if (onComplete)
					{
						var pollFn = function() {
							if (xml.readyState == 4) {
								window.clearInterval(FileIO._poll[url]);
								delete FileIO._poll[url];
								var result = (xml.status == 200 || xml.status == 304 || xml.status == 0) ? xml.responseText : false;
								onComplete.call(result, result);
								xml = null;
								onComplete = null;
							}
						}
						FileIO._poll[url] = setInterval(pollFn, FileIO.AJAX_POLL_RATE);
						setTimeout(function() {
							try {
								window.clearInterval(FileIO._poll[url]);
								xml = null;
								onComplete = null;
							} catch(e) {};
						}, FileIO.AJAX_POLL_TIMEOUT);
						xml.send("");
						return true;
					}
					else
					{
						xml.send("");
						return (xml.status == 200 || xml.status == 304 || xml.status == 0) ? xml.responseText : false;
					}
				}
				else
					return false;
			}
			catch(e) { return false; }
		}
		return false;
		//return xml;
	},
	
	// Load a document.
	//	Returns a string created from the file located at "path."
	loadFile: function(path) {
		path = FileIO.normalizePath(path, true);
		var doc = false;
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
/*		if (window.XMLHttpRequest && window.XSLTProcessor)
		{
			try { doc = new XMLHttpRequest(); }
			catch(e) { console.warn(e); return false; }
		}
		else */ if (window.ActiveXObject)
		{
			try { doc = new ActiveXObject("Msxml2.XMLHTTP"); }
			catch(e)
			{
				try { doc = new ActiveXObject("Microsoft.XMLHTTP"); }
				catch(e) { console.warn(e); return false; }
			}
		}
		if (doc)
		{
			try
			{
				doc.open("GET", path, false);
				doc.send(null);
			}
			catch (e) { console.warn(e); return false; }
			if (doc.responseText)
				return doc.responseText;
			else if (doc.responseXML)
				return FileIO.makeDOMString(doc.responseXML);
			else
				return false;
		}
		else
			return false;
	},
	
	// Save a document.
	//	Saves "text" to the file "path."
	saveFile: function(path, text, executable) {
		executable = executable || false;
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				try
				{
					// Write file in UTF-8 (requires ADODB).
					var stream = new ActiveXObject("ADODB.Stream");
					stream.Open();
					stream.Type = 2;
					stream.Charset = "utf-8";
					stream.WriteText(text);
					stream.SaveToFile(path, 2);
					stream.Close();
				}
				catch(e)
				{
					// Otherwise substitute UTF-8 escape sequences.
					var fso = new ActiveXObject("Scripting.FileSystemObject");
					var file = fso.CreateTextFile(path, true);
					// Convert UTF-8 characters to "\u****".
					for (var i = text.length - 1; i >= 0; i--)
					{
						var charcode = text.charCodeAt(i);
						if (charcode > 128)
						{
							charcode = charcode.toString(16);
							while (charcode.length < 4)
								charcode = "0" + charcode;
							text = text.substr(0, i) + "\\u" + charcode + text.substr(i+1);
						}
					}
					// Save file.
					file.Write(text);
					file.Close();
				}
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				if (!file.exists())
					file.create(0x00, executable ? 0755 : 0644);
				var outputStream = Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);
				outputStream.init(file, 0x20 | 0x04, 00004, null);
				var utfStream = Components.classes["@mozilla.org/intl/converter-output-stream;1"].createInstance(Components.interfaces.nsIConverterOutputStream);
				utfStream.init(outputStream, "UTF-8", 0, 0x0000);
				utfStream.writeString(text);
				utfStream.close();
				outputStream.close();
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Delete a document.
	//	Deletes file at "path." Mozilla cannot delete read-only files.
	deleteFile: function(path) {
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				if (fso.FileExists(path))
					fso.DeleteFile(path, true);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				if (file.exists())
					file.remove(false);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Creates a directory.
	//	Create directory at "path."
	createDirectory: function(path) {
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				if (!fso.FolderExists(path))
					fso.CreateFolder(path);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				if (!file.exists())
					file.create(0x01, 0755);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Delete a directory.
	//	Deletes directory at "path." Mozilla cannot delete read-only directories.
	deleteDirectory: function(path) {
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				if (fso.FolderExists(path))
					fso.DeleteFolder(path, true);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				if (file.exists())
					file.remove(true);
				return true;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// List the contents of a directory.
	//	Returns an object containing the following properties:
	//		path		Normalized path to the directory that was listed.
	//		files		Filenames for each file in the directory.
	//		folders		Folder names for each folder in the directory.
	listDirectory: function(path) {
		// Set shared variables.
		path = FileIO.normalizePath(path);
		var list = {
			path: path,
			files: new Array(),
			folders: new Array()
		}
		
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				var dir = false;
				try { dir = fso.GetFolder(list.path); }
				catch (e) {
					try
					{
						list.path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + list.path.replace(/\\/g,"/");
						dir = fso.GetFolder(list.path);
					}
					catch (e) { console.warn(e); }
				}
				if (dir)
				{
					var entries = new Enumerator(dir.files);
					while (!entries.atEnd())
					{
						list.files.push(entries.item().Name);
						entries.moveNext()
					}
					var folders = new Enumerator(dir.subFolders);
					while (!folders.atEnd())
					{
						list.folders.push(folders.item().Name);
						folders.moveNext()
					}
					list.folders.sort();
					list.files.sort();
					return list;
				}
				else
					return false;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var dir = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				try { dir.initWithPath(list.path); }
				catch (e) {
					try
					{
						list.path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + list.path.replace(/\\/g,"/");
						list.path = list.path.replace(/\//g, "\\");
						dir.initWithPath(list.path);
					}
					catch (e) { console.warn(e); }
				}
				var entries = dir.directoryEntries;
				while (entries.hasMoreElements())
				{
					var entry = entries.getNext();
					entry.QueryInterface(Components.interfaces.nsIFile);
					if (entry.isDirectory())
						list.folders.push(entry.leafName);
					else
						list.files.push(entry.leafName);
				}
				list.folders.sort();
				list.files.sort();
				return list;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Transform an XML document with an XSL document.
	//	Transforms "xml" with the "xsl" stylesheet.
	//	Returns a string containing the XSL-processed result.
	//	If parameters is specified, it will pass on the parameters to the XSL stylesheet;
	//	this argument is OPTIONAL. The parameters object must be an object literal where the
	//	keys correspond to parameter names and the values correspond to parameter values.
	transformXML: function(xml, xsl, parameters) {
		parameters = parameters || false;
		var t = false;
		if (window.ActiveXObject)
		{
			if (parameters)
			{
				try
				{
					// Transform with parameters.
					var xslt = new ActiveXObject("Msxml2.XSLTemplate");
					var xsl2 = new ActiveXObject("Msxml2.FreeThreadedDOMDocument");
					xsl2.async = false;
					xsl2.loadXML(FileIO.makeDOMString(xsl));
					xslt.stylesheet = xsl2;
					var xslproc = xslt.createProcessor();
					xslproc.input = xml;
					for (var key in parameters)
						xslproc.addParameter(key, parameters[key]);
					xslproc.transform();
					t = xslproc.output;
					t = t.replace(/^\<\?.+?utf-16.*?\?\>/i, "");
				}
				catch(e) { console.warn(e); return false; }
			}
			else
				t = xml.transformNode(xsl);
		}
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
		/*else
		{
			var xslproc = new XSLTProcessor();
			xslproc.importStylesheet(xsl);
			for (var key in parameters)
				xslproc.setParameter(null, key, parameters[key]);
			var fragment = xslproc.transformToFragment(xml, document);
			if (fragment.childNodes.length > 0)
			{
				var tmp = document.createElement("DIV");
				tmp.appendChild(fragment.childNodes[0]);
				t = tmp.innerHTML;
			}
		}*/
		return t;
	},
	
	// Validates an XML document with an XSD document.
	//	Validates XML document at "xml_path" with the XSD document at "xsd_path."
	//	This is ONLY SUPPORTED in Internet Explorer.
	//	Returns true if the XML document is valid and false if it is invalid.
	validateXML: function(xml_path, xsd_path) {
		xml_path = FileIO.normalizePath(xml_path);
		xsd_path = FileIO.normalizePath(xsd_path);
		if (document.all)
		{
			try
			{
				// Set up validation.
				var schema = FileIO.loadXML(xsd_path);
				var schemaCache = new ActiveXObject('Msxml2.XMLSchemaCache.4.0');
				schemaCache.add('', schema);
				xml = FileIO.getDOMDocument();
				xml.validateOnParse = true;
				xml.schemas = schemaCache;
				// Validate the document.
				if (xml.load(xml_path))
					return true;
				else
					return false;
			}
			catch(e) { console.warn(e); return false; }
		}
		else
		{
			try
			{
				// Mozilla cannot currently validate XML documents.
				return true;
			}
			catch(e) { console.warn(e); return false; }
		}
		return false;
	},
	
	// Get a DOM XML document.
	//	Returns a DOM XML document.
	getDOMDocument: function() {
		var doc = false;
		if (document.implementation && document.implementation.createDocument)
			doc = document.implementation.createDocument("", "", null);
		else if (window.ActiveXObject)
		{
			try { doc = new ActiveXObject("Msxml2.DOMDocument.4.0"); }
			catch (e)
			{
				try { doc = new ActiveXObject("Microsoft.XMLDOM"); }
				catch (e) { console.warn(e); }
			}
			try
			{
				doc.async = false;
				doc.setProperty("SelectionLanguage", "XPath");
				doc.setProperty("SelectionNamespaces", "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'");
			}
			catch(e) { console.warn(e); }
		}
		return doc;
	},
	
	// Make a DOM XML document.
	//	Returns a DOM XML document created from "xml_string."
	makeDOMDocument: function(xml_string) {
		var doc = false;
		if (document.implementation && document.implementation.createDocument)
		{
			var parser = new DOMParser();
			doc = parser.parseFromString(xml_string, "text/xml");
		}
		else if (window.ActiveXObject)
		{
			try { doc = new ActiveXObject("Msxml2.DOMDocument.4.0"); }
			catch (e)
			{
				try { doc = new ActiveXObject("Microsoft.XMLDOM"); }
				catch (e) { console.warn(e); }
			}
			if (doc)
			{
				doc.async = false;
				doc.validateOnParse = false;
				doc.loadXML(xml_string);
				try { doc.setProperty("SelectionLanguage", "XPath"); doc.setProperty("SelectionNamespaces", "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'"); }
				catch(e) { console.warn(e); }
			}
		}
		return doc;
	},
	
	// Make a DOM XML string.
	//	Returns a string created from the DOM XML document, "xml_doc."
	makeDOMString: function(xml_doc) {
		if (document.implementation && document.implementation.createDocument)
		{
			var serialize = new XMLSerializer();
			return serialize.serializeToString(xml_doc);
		}
		else if (window.ActiveXObject)
		{
			// Truncate forced new line.
			return xml_doc.xml.substr(0, xml_doc.xml.length-2);
		}
		return false;
	},
	
	// Execute an external application.
	//	Any exit code that isn't zero (0) should be considered a failure.
	//	Failure should be tested for using the "failure" property, however, "failure"
	//		being set to false when "block" = false does not guarantee that the
	//		execution will be successful.
	//	Returns the following if "block" = true:
	//		{
	//			exitCode: <exit_code_integer>,	// The exit code returned by the process.
	//			failure: <boolean>				// Whether or not the process failed.
	//		}
	//	Returns the following if "block" = false:
	//		{
	//			failure: <boolean>,				// Whether or not the process failed.
	//											//	"failure" = false does NOT ensure success.
	//			hash: <string>,					// Unique identifier.
	//			kill: <function>;				// Method to kill process.
	//		}
	//	Passed to exit/timeout handlers after execution if "block" = false:
	//		{
	//			exitCode: <exit_code_integer>,	// The exit code returned by the process.
	//			failure: <boolean>,				// Whether or not the process failed.
	//			hash: <string>,					// Unique identifier.
	//		}
	execute: function(path, args, block, normalize, async, interactive)
	{
		// Fix args if not passed.
		args = args || null;
		block = /^undefined$/i.test(typeof block) ? true : block;
		normalize = /^undefined$/i.test(typeof normalize) ? true : normalize;
		async = async || false;
		interactive =interactive || false;
		if (normalize)
		{
			path = FileIO.normalizePath(path);
			if (!FileIO.Properties.isFile(path))
				return { exitCode: FileIO.EXITCODE_ERROR, failure: true };
		}
		var wrapper = FileIO.normalizePath(FileIO.WRAPPER_PATH);
		var proc = false;
		// Add quotes to arguments if necessary.
		if (args != null)
		{
			for (var i = 0; i < args.length; i++)
			{
				if (!/^".*?"$/.test(args[i]))
					args[i] = "\"" + args[i] + "\"";
			}
		}
		// Internet Explorer.
		if (document.all)
		{
			try {
				var myshell = new ActiveXObject("WScript.shell");
			} catch (e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
			
			// Make the command-line
			var cmd = "\"" + wrapper;
			// If this command requires user interactions (eg. UI window), add "-s" option, so the window will not be hidden.
			if (interactive)
				cmd += "\" -s \"";
			else
				cmd += "\" \"";
			cmd += path + "\""
			
			if (args != null)
			{
				for (var i = 0; i < args.length; i++)
					cmd += " " + args[i];
			}
			try {
				var tmp_path = FileIO.normalizePath(".");
				myshell.CurrentDirectory = tmp_path.substr(0, tmp_path.length - 1);
				if (block)
					proc = myshell.Run(cmd, 0, block);
				else
					proc = myshell.Exec(cmd);
			} catch (e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
		}
		// Mozilla Firefox.
		else
		{
			// Create file object.
			netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
			var file = new Components.Constructor("@mozilla.org/file/local;1","nsILocalFile","initWithPath");
			try {
				// Call the wrapper instead.
				var exec = new file(wrapper);
			} catch (e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
			// Create process.
			try {
				proc = Components.classes["@mozilla.org/process/util;1"].createInstance(Components.interfaces.nsIProcess);
			} catch(e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
			
			// Set up and start.
			try {
				// Reset the exit code to FileIO.EXITCODE_RESET if blocking is disabled.
				if (!block && FileIO.ENABLE_MOZILLA_EXECUTE_ASYNC)
				{
					try {
						var resetScript = "";
						if (!FileIO.IS_WINDOWS)
							resetScript += "#!/bin/bash\n"
						else
							resetScript += "@echo off\n";
						resetScript += "exit " + FileIO.EXITCODE_RESET + "\n";
						var resetName = "reset_mozilla_exitcode_" + new Date().getTime() + (FileIO.IS_WINDOWS ? ".bat" : ".sh");
						FileIO.saveFile(resetName, resetScript, true);
						proc.init(new file(FileIO.normalizePath(resetName)));
						proc.run(true, null, 0, {});
						FileIO.deleteFile(resetName);
					} catch(e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
				}
				
				// Create temporary batch file.
				var batchScript = new Array();
				if (!FileIO.IS_WINDOWS)
					batchScript.push("#!/bin/bash\n");
				else
					batchScript.push("@echo off\n");
				// Change working directory.
				if (path.indexOf(FileIO.IS_WINDOWS ? "\\" : "/") > -1)
				{
					batchScript.push("cd " + (FileIO.IS_WINDOWS ? "/D " : "") + "\"");
					batchScript.push(FileIO.IS_WINDOWS ? path.substr(0, path.lastIndexOf("\\")) : path.substr(0, path.lastIndexOf("/")));
					batchScript.push("\"\n");
				}
				// Set variables.
				var set_var = function(name, value) {
					name = /errorlevel/i.test(name) ? FileIO.IS_WINDOWS ? "ERRORLEVEL" : "?" : name;
					return (FileIO.IS_WINDOWS ? "set "+name+"=" : "export "+name+"=") + value + "\n";
				};
				var get_var = function(name) {
					name = /errorlevel/i.test(name) ? FileIO.IS_WINDOWS ? "ERRORLEVEL" : "?" : name;
					return FileIO.IS_WINDOWS ? "%"+name+"%" : "$"+name;
				};
				// Set executable variable.
				var batchExecutable = "\"" + (FileIO.IS_WINDOWS ? path.substr(path.lastIndexOf("\\")+1) : path.substr(path.lastIndexOf("/")+1)) + "\"";
				batchScript.push(set_var("FILEIO_EXE", batchExecutable));
				// Set other variables.
				if (args != null)
				{
					for (var i = 0; i < args.length; i++)
						batchScript.push(set_var("FILEIO_ARG"+i, args[i]));
				}
				// Create execution line.
				batchScript.push(FileIO.IS_WINDOWS ? "call " : "source ");
				batchScript.push(get_var("FILEIO_EXE"));
				if (args != null)
				{
					for (var i = 0; i < args.length; i++)
						batchScript.push(" " + get_var("FILEIO_ARG"+i));
				}
				batchScript.push("\n");
				batchScript.push("exit " + get_var("ERRORLEVEL") + "\n");
				batchScript = batchScript.join("");
				var batchName = "fileio_runner_" + new Date().getTime() + (FileIO.IS_WINDOWS ? ".bat" : ".sh");
				FileIO.saveFile(batchName, batchScript, true);
				
				// Run executable.
				proc.init(exec);
				var proc_args = [FileIO.normalizePath(batchName)];
				proc.run(FileIO.ENABLE_MOZILLA_EXECUTE_ASYNC ? block : true, proc_args, proc_args.length, {});
				// Clean up.
				FileIO.deleteFile(batchName);
			} catch (e) { console.warn(e); return { exitCode: FileIO.EXITCODE_ERROR, failure: true }; }
		}
		
		// Handle blocking process after creation.
		if (block)
		{
			// Return an object instead of just an exit code to allow boolean comparison [if (FileIO.execute(..))].
			return { exitCode: document.all ? proc : proc.exitValue, failure: (document.all ? proc : proc.exitValue) != 0 };
		}
		else if (!block && /object/i.test(typeof async) && /number/i.test(typeof async.poll)
		&& /number/i.test(typeof async.timeout) && /function/i.test(typeof async.exitHandler) 
		&& /function/i.test(typeof async.timeoutHandler)) {
			// Create asynchronous controller.
			var asyncController = new function() {
				// Create async, hash, and process properties.
				this.async = async;
				this.hash = path + "?args=" + (args != null ? args.toString() : "") + "&hash=" + new Date().getTime();
				this.process = proc;
				// Handle periodic polling, checking for finished process.
				this.poll = function() {
					if (document.all) {
						// Check for finished process.
						if (this.process.Status == 1) {
							// Clean up.
							this.kill = function() { };
							if (this.pollID)
								clearInterval(this.pollID);
							if (this.killID)
								clearTimeout(this.killID);
							// Pass exit code and hash to handler.
							this.async.exitHandler({
								exitCode: this.process.ExitCode,
								failure: this.process.ExitCode != 0,
								hash: this.hash
							});
							setTimeout(asyncController.destroy, 50);
							return true;
						}
						else
							return false;
					}
					else {
						// Check for finished process.
						netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
						if (this.process.exitValue != FileIO.EXITCODE_RESET) {
							// Clean up.
							this.kill = function() { };
							if (this.pollID)
								clearInterval(this.pollID);
							if (this.killID)
								clearTimeout(this.killID);
							// Pass exit code and hash to handler.
							this.async.exitHandler({
								exitCode: this.process.exitValue,
								failure: this.process.exitValue != 0,
								hash: this.hash
							});
							setTimeout(asyncController.destroy, 50);
							return true;
						}
						else
							return false;
					}
				};
				// Kill the process.
				this.kill = function() {
					try
					{
						// Clean up.
						this.poll = function() { };
						if (this.pollID)
							clearInterval(this.pollID);
						if (this.killID)
							clearTimeout(this.killID);
						// Kill process.
						if (document.all)
							this.process.Terminate();
						else
						{
							netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
							this.process.kill();
						}
						// Pass hash to handler.
						this.async.timeoutHandler({
							exitCode: FileIO.EXITCODE_ERROR,
							failure: true,
							hash: this.hash
						});
						setTimeout(asyncController.destroy, 50);
						return true;
					}
					catch(e)
					{
						// Clean up.
						if (this.pollID)
							clearInterval(this.pollID);
						if (this.killID)
							clearTimeout(this.killID);
						setTimeout(asyncController.destroy, 50);
						return false;
					}
				};
				// Timeout/Interval maintenance properties/methods.
				this.pollID = false;
				this.killID = false;
				this.pollBind = function() {
					asyncController.poll.call(asyncController);
				};
				this.killBind = function() {
					asyncController.kill.call(asyncController);
				};
				// Destory object.
				this.destroy = function() {
					asyncController.poll = null;
					asyncController.kill = null;
					asyncController.pollBind = null;
					asyncController.killBind = null;
					asyncController = null;
				}
			}
			
			// Is Mozilla asynchronous support enabled?
			if (document.all || FileIO.ENABLE_MOZILLA_EXECUTE_ASYNC)
			{
				// Start poll and kill timers.
				asyncController.pollID = setInterval(asyncController.pollBind, asyncController.async.poll);
				asyncController.killID = setTimeout(asyncController.killBind, asyncController.async.timeout);
			}
			// Fake as though this was executed asynchronously.
			else
			{
				// 50ms delay to call exit handler.
				setTimeout(function() {
					netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
					asyncController.async.exitHandler({
						exitCode: asyncController.process.exitValue, 
						failure: asyncController.process.exitValue != 0,
						hash: asyncController.hash
					});
				}, 50);
				// Destroy the controller object.
				setTimeout(asyncController.destroy, 100);
			}
			
			// Return object with hash and kill method.
			return { failure: false, hash: asyncController.hash, kill: function(){
				try { asyncController.kill(); return true; }
				catch(e) { console.warn(e); return false; };
			} };
		}
		else
			return { exitCode: FileIO.EXITCODE_ERROR, failure: true };
	},
	
	// Read text from an XML element.
	//	Returns a string containing the inner text value for an XML element.
	textContent: function(element) {
		return typeof element.textContent == 'string' ? element.textContent : element.text;
	},
	
	// Fix path for local files.
	//	Returns an absolute path to the file at "path" using the URL.
	//	Appends a file:/// address if "url" is set to true.
	normalizePath: function(path, url) {
		// Fix path.
		path = path.replace(/^file:\/\/\//,"").replace(/^file:/,"").replace(/\\/g,"/");
		if (path.length == 0)
			return false;
		var location = window.location.href.replace(/^file:\/\/\//,"").replace(/^file:/,"");
		if (location.indexOf("/") > -1)
			location = location.substr(0, location.lastIndexOf("/")+1) + path.replace(/\\/g,"/");
		
		// Is this a relative path?
		if (!/^\//.test(path) && !/^[a-z]:/i.test(path))
			path = location;
		
		// Fix relative path.
		path = path.replace(/\/([^\/]+?)\/\.\//g, "/$1/");
		path = path.replace(/\/([^\/]+?)\/\.\.\//g, "/");
		
		// Fix for Windows.
		if (FileIO.IS_WINDOWS && !url)
			path = path.replace(/\//g, "\\");
		// Fix spaces.
		path = path.replace(/%20/g, " ");
		
		// Requires URL?
		if (url && FileIO.IS_WINDOWS)
			path = "file:///" + path;
		else if (url && !FileIO.IS_WINDOWS)
			path = "file:" + path;
		return path;
	}
}

// FileIO.Properties Library
FileIO.Properties = {
	// Get the last modified date/time of a file.
	//	Returns the last modified date/time of the file at "path."
	lastModified: function(path) {
		// Set shared variables.
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				var file = false;
				try { file = fso.GetFile(path); }
				catch (e) {
					try
					{
						path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + path.replace(/\\/g,"/");
						file = fso.GetFile(path);
					}
					catch (e) { console.warn(e); }
				}
				if (file)
					return file.DateLastModified;
				else
					return false;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				try { file.initWithPath(path); }
				catch (e) {
					try
					{
						path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + path.replace(/\\/g,"/");
						path = path.replace(/\//g, "\\");
						file.initWithPath(path);
					}
					catch (e) { console.warn(e); }
				}
				return file.lastModifiedTime;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Get the size of a file.
	//	Returns the size of the file at "path."
	size: function(path) {
		// Set shared variables.
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				var file = false;
				try { file = fso.GetFile(path); }
				catch (e) {
					try
					{
						path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + path.replace(/\\/g,"/");
						file = fso.GetFile(path);
					}
					catch (e) { console.warn(e); }
				}
				if (file)
					return file.Size;
				else
					return false;
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				try { file.initWithPath(path); }
				catch (e) {
					try
					{
						path = window.location.href.substr(0, window.location.href.lastIndexOf("/")+1).replace("file:///","") + path.replace(/\\/g,"/");
						path = path.replace(/\//g, "\\");
						file.initWithPath(path);
					}
					catch (e) { console.warn(e); }
				}
				return file.fileSize;
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Checks if the file exists and is an actual file.
	//	Returns true if the file exists and is a file.
	isFile: function(path) {
		// Set shared variables.
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				return fso.FileExists(path);
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				return file.isFile();
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	},
	
	// Checks if the directory exists and is an actual directory.
	//	Returns true if the directory exists and is a directory.
	isDirectory: function(path) {
		// Set shared variables.
		path = FileIO.normalizePath(path);
		// Internet Explorer.
		if (window.ActiveXObject)
		{
			try
			{
				var fso = new ActiveXObject("Scripting.FileSystemObject");
				return fso.FolderExists(path);
			}
			catch (e) { console.warn(e); return false; }
		}
		// Mozilla/Firefox/Netscape.
		//	Requires the user to approve the action (can save choice though).
		else if (window.netscape)
		{
			try
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
				var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
				file.initWithPath(path);
				return file.isDirectory();
			}
			catch (e) { console.warn(e); return false; }
		}
		else
			return false;
	}
}
