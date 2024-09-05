// CSSpp class: CSS Preprocessor, allows for extended functionality in defining CSS stylesheets.
// All paths used in the class accept either absolute or relative paths.
// This class is compatible with Internet Explorer and modern browsers such as Firefox.
//	Version:	1.2
//	Author:		Andy Kant (Andrew.Kant@ge.com)
//	Date:		Jun.14.2006
//	Modified:	Jul.06.2006
// NOTE: This is based on the CSS Server-side Constants idea, syntax, and PHP script by Shaun Inman.
//	(http://www.shauninman.com/plete/2005/08/css-constants)
/* 
	USAGE:
		Add this code in the <head> section of your webpage (updating path as necessary):
			<script src="./scripts/csspp.js?css=./styles/main/rfs.css&xml=./xml/rfs_style.xml&media=screen" type="text/javascript"></script>
		The script has three parameters: "css" is required, "xml" is optional, and "media" is optional.
		These three parameters must be listed in that order (css, xml, media).
		The script source must have it's source defined in a specific order:
				csspp.js?css=[file]&xml=[file]&media=[media]
				csspp.js?css=[file]&xml=[file]
				csspp.js?css=[file]&media=[media]
				csspp.js?css=[file]
				ex.:	./scripts/csspp.js?css=./styles/main/rfs.css&xml=./xml/rfs_style.xml&media=screen
	IMPORTANT NOTE:
		Although this script allows global constants which make the CSS easier to change (especially for those
		with little CSS knowledge), it is a bit inefficient in that the CSS cannot be cached using this method.
		My recommendation is to move any CSS not requiring preprocessing to its own stylesheet and referencing
		it separately in your XHTML. WARNING: @import has been changed to embed the linked stylesheet directly
		within the preprocessed stylesheet. This is because it will cause Internet Explorer to crash if this isn't
		done. It is also recommended that you only define constants in one location (either the CSS or the XML) 
		and keep your total number of constants small because otherwise it will take too long to process.
	USABLE METHODS:
		The CSS Preprocessor contains a cross-browser addEvent method. This may be used to stack functions on 
		normally singular events such as onLoad. Any window.onload events are added to the window.onload queue
		by default to make sure that they are executed sequentially. This is to guarantee to the CSSpp.go 
		method is called before any window.onload events in case they dynamically update styles. This may be 
		overridden by adding a fourth argument that is set to "true." The window.onload event queue does not
		currently support arguments for the function object. The Preprocessor also contains a method called $
		that simply is an alias for document.getElementById.
		METHODS:
			CSSpp.addEvent(element, name, observer);
				DESCRIPTION:
					Add a cross-browser event listener.
				USAGE:
					CSSpp.addEvent(window, "load", some_function_object);
				PARAMETERS:
					element		The element to listen on.
					name		The name of the event (not including "on").
					observer	The function object to execute.
					arg4		A hidden argument; set to "true" to prevent a window.onload event
								from being added to the window.onload queue.
			CSSpp.$(e);
				DESCRIPTION:
					Element selector.
				USAGE:
					CSSpp.$("header");
				PARAMETERS:
					e			The element OR id string of the element to select.
	USING CSS PREPROCESSOR DIRECTIVES:
		CSS directives (primarily being constants) can be embedded directly into the CSS as well as that they
		can be included via an XML document. Constants defined later in the document will override the earlier
		ones. Constants defined in the XML will override those defined in the CSS.
		DEFINING CONSTANTS:
			Constants embedded in the CSS can be defined using the following syntax:
				@server constants {
					CDI_Background: #CEC;
					CDI_FontColor: #C00;
					CDI_BorderColor: #000;
					CDI_BorderStyle: solid;
					CDI_BorderWidth: 1px;
					}
			The word before the colon (:) is the name of the constant, and the text to the right of the colon
			is the value of the constant. Constant elements in XML can be added anywhere into the schema as the
			script will automatically find them. Here is the syntax in defining CSS constants in XML:
				<constant name="CDI_Background" value="#CEC" />
				<constant name="CDI_FontColor" value="#C00" />
				<constant name="CDI_BorderColor" value="#000" />
				<constant name="CDI_BorderStyle" value="solid" />
				<constant name="CDI_BorderWidth" value="1px" />
		LINKING STYLESHEETS:
			Linking stylesheets within a preprocessed CSS stylesheet is similar to using the @import command
			already existing in CSS. Any stylesheet linked using the @import command will also be preprocessed.
			This is because if it isn't preprocessed, it will cause Internet Explorer to crash. To link and 
			preprocess a stylesheet, use the following command in your CSS:
				@server url(test.css);
		USING CONSTANTS:
			To use a constant in your CSS stylesheet, simply use the name of the constant for a CSS value
			instead of using an actual value. Here is an example:
				div#CDI {
					background: CDI_Background;
					color: CDI_FontColor;
					border: CDI_BorderWidth CDI_BorderStyle CDI_BorderColor;
				}
*/
// Make sure the class doesn't get created/executed twice.
if (!CSSpp)
{
	var CSSpp = {
		// Queue for window.onload events.
		loadQueue: new Array(),
		
		// Start the preprocessor.
		//	Grabs the CSS path.
		go: function() {
			// Find the reference to this script.
			var scripts = document.getElementsByTagName("HEAD")[0].getElementsByTagName("SCRIPT");
			var css = false;
			var xml = false;
			var media = false;
			var result = true;
			for (var i = 0; i < scripts.length; i++)
			{
				if (/csspp\.js\?css=(.+?)(&xml=(.+?))?(&media=(.+?))?$/.test(scripts[i].src))
				{
					var match = /csspp\.js\?css=(.+?)(&xml=(.+?))?(&media=(.+?))?$/.exec(scripts[i].src);
					css = match[1];
					if (match[3])
						xml = match[3];
					if (match[5])
						media = match[5];
					if (css)
						result = result && CSSpp.process(css, xml, media);
				}
			}
			if (css)
				return result;
			else
				return false;
		},
		
		// Process CSS document.
		//	Set xml_path to false if there are no XML configured constants.
		process: function(css_path, xml_path, media) {
			// Grab stylesheet.
			var css = CSSpp.loadFile(css_path, false);
			if (css)
			{
				// Load external stylesheets.
				css = CSSpp.processExternal(css, css_path);
				var matches;
				
				// Grab constants.
				var constants = new Array();
				matches = css.match(/@server\s+(?:variables|constants)\s*\{\s*([^\}]+)\s*\}\s*/ig);
				if (matches)
				{
					for (var i = 0; i < matches.length; i++)
					{
						var match = /@server\s+(?:variables|constants)\s*\{\s*([^\}]+)\s*\}\s*/i.exec(matches[i]);
						var matches2 = match[1].match(/([^:}\s]+)\s*:\s*([^;}]+);/g);
						if (matches2)
						{
							for (var j = 0; j < matches2.length; j++)
							{
								var match3 = /([^:}\s]+)\s*:\s*([^;}]+);/.exec(matches2[j]);
								constants.push({name: match3[1], value: match3[2]});
							}
						}
					}
					// Remove constant sections.
					css = css.replace(/@server\s+(?:variables|constants)\s*\{\s*([^\}]+)\s*\}\s*/ig, "");
				}
					
				// Add constants from XML if applicable.
				if (xml_path)
				{
					var xml = CSSpp.loadFile(xml_path, true);
					if (xml)
					{
						var elements = xml.getElementsByTagName("constant");
						for (var i = 0; i < elements.length; i++)
						{
							var cname = elements[i].getAttribute("name");
							var cval = elements[i].getAttribute("value");
							if (cname && cval)
								constants.push({name: cname, value: cval});
						}
					}
					else
						return false;
				}
				
				// Apply constants.
				for (var i = constants.length-1; i >= 0; i--)
					css = css.replace(eval("/([^:\}\s]+\s*:\s*[^;\}]*)"+constants[i].name+"([^;\}]*)/g"), "$1"+constants[i].value+"$2");
				
				// Add preprocessed CSS to page.
				var style = document.createElement("STYLE");
				style.setAttribute("type", "text/css");
				style.setAttribute("media", media);
				if (style.styleSheet)
					style.styleSheet.cssText = css;
				else
					style.appendChild(document.createTextNode(css));
				document.getElementsByTagName("HEAD")[0].appendChild(style);
				return true;
			}
			else
				return false;
		},
		
		// Process external stylesheets.
		processExternal: function(css, css_path) {
			var re = /(@server|@import)\s+url\(([^)]+)\);\s*/ig;
			var matches = css.match(re);
			var include_path = css_path.substr(0, css_path.lastIndexOf("/")+1);
			var replacements = new Array();
			if (matches)
			{
				for (var i = 0; i < matches.length; i++)
				{
					try
					{
						var match = /(@server|@import)\s+url\(([^\)]+)\);\s*/i.exec(matches[i]);
						var new_css = CSSpp.loadFile(include_path + match[2], false);
						new_css = CSSpp.processExternal(new_css, include_path);
						replacements.push({match: match[0], css: new_css});
					}
					catch (e) { }
				}
			}
			for (var i = 0; i < replacements.length; i++)
			{
				try { css = css.replace(replacements[i].match, replacements[i].css); }
				catch (e) { }
			}
			return css;
		},
		
		// Load a document.
		//	Returns a string created from the file located at "path."
		loadFile: function(path, xml) {
			// Normalize the path.
			// Convert paths to normal slashes.
			path = path.replace(/\\/g, "/");
			// Is this an absolute path?
			if (/^([a-z]:\/|\/\/[a-z]+)/ig.test(path))
				path = "file:///" + path;
			
			var doc = false;
//Because of native XML and IE7 compatibility, only ActiveXObject code can be used
//Code is not deleted in order to help further development, in case of alternative (mozzilla, safary etc) browser support would be required.
/*			if (window.XMLHttpRequest && window.XSLTProcessor)
			{
				try { doc = new XMLHttpRequest(); }
				catch(e) { doc = false; }
			}
			else */ if (window.ActiveXObject)
			{
				if (xml)
				{
					var doc = false;
					try { doc = new ActiveXObject("Msxml2.DOMDocument.4.0"); }
					catch (e)
					{
						try { doc = new ActiveXObject("Microsoft.XMLDOM"); }
						catch (e) { }
					}
					try
					{
						doc.async = false;
						doc.load(path);
						return doc;
					}
					catch (e) { return false; }
				}
				else
				{
					try { doc = new ActiveXObject("Msxml2.XMLHTTP"); } 
					catch(e)
					{
						try { doc = new ActiveXObject("Microsoft.XMLHTTP"); }
						catch(e) { doc = false; }
					}
				}
			}
			if (doc)
			{
				try
				{
					doc.open("GET", path, false);
					doc.send(null);
				}
				catch (e) { return false; }
				if (xml)
					return doc.responseXML;
				else if (doc.responseText)
					return doc.responseText;
				else
					return false;
			}
			else
				return false;
		},
		
		// Add event listener.
		addEvent: function(element, name, observer) {
			// If the extra argument doesn't exist or is not set to true, add window.onload to queue.
			if (element == window && name == "load" && (!arguments[3]))
				CSSpp.loadQueue.push(observer);
			else
			{
				if (element.addEventListener)
					element.addEventListener(name, observer, true);
				else if (element.attachEvent)
				  element.attachEvent("on" + name, observer);
			}
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
		
		// Get computed style for an element.
		style: function(e, attr) {
			// Validate element.
			e = CSSpp.$(e);
			if (e)
			{
				try
				{
					// IE.
					if (e.currentStyle)
						return eval("e.currentStyle." + attr);
					// Mozilla.
					else
						return eval("document.defaultView.getComputedStyle(e, null)." + attr);
				}
				catch (e) { return false; }
			}
			else
				return false;
		},
		
		// Process all window.onload events.
		doLoad: function() {
			// Iterate through load queue.
			for (var i = 0; i < CSSpp.loadQueue.length; i++)
				CSSpp.loadQueue[i]();
		}
	}
	// Apply styles on load.
	CSSpp.addEvent(window, "load", CSSpp.doLoad, true);
	CSSpp.addEvent(window, "load", CSSpp.go);
}
