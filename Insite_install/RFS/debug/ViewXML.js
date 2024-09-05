// ViewXML class: Updates the element with id="xml" with new content.
//	Author:		Andrew.Kant@ge.com
//	Date:		Jun.06.2006
//	Modified:	Jun.09.2006
// NOTE: Uses Xparse class by Jeremie (jer@jeremie.com, http://www.jeremie.com/Dev/XML/).
/* 
	USAGE:
	Add this code at the beginning of the <head> section of your webpage (updating path as necessary):
		<link href="ViewXML.css" media="screen" rel="stylesheet" type="text/css" />
		<script src="ViewXML.js" type="text/javascript"></script>
	In the following, the "if (ViewXML)" is important because your JavaScript won't crash if ViewXML is
	missing or isn't instantiated. Add this code in your JavaScript to generate a ViewXML object:
		if (ViewXML)
			ViewXML.view("<tag>text</tag>");
	Or set custom options:
		if (ViewXML)
			ViewXML.view("<tag>text</tag>", {element: "xml", timestamp: false});
	METHODS:
		ViewXML.view(xml [, options]);
			DESCRIPTION: Converts an XML string to an easily viewed XHTML block.
			USAGE:
				ViewXML.view("<tag>text</tag>");
				ViewXML.view("<tag>text</tag>", {element: "xml"});
				ViewXML.view("<tag>text</tag>", {element: "xml", timestamp: false});
				ViewXML.view("<tag>text</tag>", {timestamp: false});
			PARAMETERS:
				xml			The actual XML text you wish to be displayed.
				options		This parameter does not need to be specified, but is used for the options.
					OPTIONS:
						element		This specifies the ID of an element which will be emptied and filled with ViewXML content.
									This can also be an actual JavaScript element object. If no element is specified, 
									a new element is appended to the <body> element of the webpage.
						timestamp	This specifies whether or not to add a timestamp to the ViewXMl content.
									Set to true by default.
		ViewXML.viewObject(obj [, options]);
			DESCRIPTION: Converts an object to an easily viewed XHTML block.
			USAGE:
				ViewXML.viewObject(someRegExp);
				ViewXML.viewObject(someRegExp, {name: "regexp"});
			PARAMETERS:
				obj			The actual object you wish to be displayed.
				options		This parameter does not need to be specified, but is used for the options.
					OPTIONS:
						name		A name for the element containing the value. Set to "object" by default.
		ViewXML.viewValue(value [, options]);
			DESCRIPTION: Converts a value to an easily viewed XHTML block.
			USAGE:
				ViewXML.viewValue("some string");
				ViewXML.viewValue("some string", {name: "attribute"});
			PARAMETERS:
				value		The actual value you wish to be displayed.
				options		This parameter does not need to be specified, but is used for the options.
					OPTIONS:
						name		A name for the element containing the value. Set to "value" by default.
*/
var ViewXML = {
	// Convert XML to display in browser.
	view: function(xml) {
		// Set options.
		var options = {
			element: false,
			timestamp: true
		}
		ViewXML.setOptions(options, arguments[1]);
			
		// Get/create the XML storage element.
		var e = false;
		if (options.element)
		{
			if (typeof options.element == "string")
				e = document.getElementById(options.element);
			else
				e = options.element;
			if (e)
			{
				if (e.className.indexOf("ViewXML") == -1)
					e.className += " ViewXML";
			}
		}
		if (!e)
		{
			e = document.createElement("DIV");
			e.className = "ViewXML";
			var body = document.getElementsByTagName("BODY");
			if (body.length > 0)
				body[0].appendChild(e);
		}
			
		// Update the XML storage element.
		if (e)
		{
			// Reset element.
			for (var i; i < e.childNodes.length; i++)
				e.removeChild(e.childNodes[i]);
			e.innerHTML = "";
				
			// Add XML text.
			var ghost = document.createElement("DIV");
			ghost.className = "ghost";
			ghost.innerHTML = "XML";
			e.appendChild(ghost);
			
			// Add timestamp.
			if (options.timestamp)
			{
				var timestamp = document.createElement("DIV");
				var d = new Date();
				var dstr = (1+d.getMonth()) + "/" + d.getDate() + "/" + d.getFullYear() + " @ " + d.getHours() + ":" + ViewXML.addZero(d.getMinutes()) + ":" + ViewXML.addZero(d.getSeconds()) + "." + d.getMilliseconds();
				timestamp.className = "timestamp";
				timestamp.innerHTML = dstr;
				e.appendChild(timestamp);
			}
			
			// Fix processing instructions for the parser.
			xml = xml.replace("<?", "<? ");
			
			// Parse XML using Xparse.
			var x = Xparse(xml);
			// Update element.
			var str = new String();
			for (var i in x.contents)
				str += ViewXML.format(x.contents[i]);
			e.innerHTML = e.innerHTML + str;
			return true;
		}
		else
			return false;
	},
	
	// Output all of the values/functions for an object.
	viewValue: function(value) {
		// Set options.
		var options = {
			name: "value"
		}
		ViewXML.setOptions(options, arguments[1]);
		
		// View value.
		ViewXML.view("<" + options.name + ">" + value.replace(/</g,"&amp;lt;").replace(/>/g,"&amp;gt;") + "</" + options.name + ">");
	},
	
	// Output all of the values/functions for an object.
	viewObject: function(obj) {
		// Set options.
		var options = {
			name: "object"
		}
		ViewXML.setOptions(options, arguments[1]);
		
		// Make object string.
		var str = new String();
		str += "<" + options.name + ">";
		str += ViewXML.formatObject(obj);
		str += "</" + options.name + ">";
		
		// View object.
		ViewXML.view(str);
	},
	
	// Add preceeding number if necessary.
	addZero: function(num) {
		if (num < 10)
			return "0" + num;
		else
			return num;
	},
	
	// Copy options array.
	setOptions: function(dest, source) {
		for (var prop in source)
			dest[prop] = source[prop];
		return dest;
	},
	
	// Generate object XML (recursive).
	formatObject: function(obj) {
		var xml = new String();
		for (var i in obj)
		{
			try
			{
				if (typeof obj[i] != "object" && obj[i].constructor == Array)
					xml += ViewXML.formatObject(obj[i]);
				else
					xml += "<" + i + ">" + obj[i].replace(/</g,"&amp;lt;").replace(/>/g,"&amp;gt;") + "</" + i + ">";
			}
			catch(e)
			{
			}
		}
		return xml;
	},
	
	// Generate element XHTML (recursive).
	format: function(xml_e) {
		if (xml_e.type == "element")
		{
			var str = "<div><span class=\"symbol\">&lt;</span>" + xml_e.name;
			if (xml_e.attributes.length > 0)
			{
				for (var i in xml_e.attributes)
					str += " " + i + "<span class=\"symbol\">=\"</span><span class=\"data\">" + xml_e.attributes[i] + "</span><span class=\"symbol\">\"</span> ";
			}
			if (xml_e.contents.length > 0)
			{
				str += "<span class=\"symbol\">&gt;</span>";
				for (var i in xml_e.contents)
					str += ViewXML.format(xml_e.contents[i]);
				str += "<span class=\"symbol\">&lt;/</span>" + xml_e.name + "<span class=\"symbol\">&gt;</span></div>";
			}
			else
				str += " <span class=\"symbol\">/&gt;</span></div>";
			return str;
		}
		else if (xml_e.type == "pi")
			return "<div><span class=\"pi\">&lt;?" + xml_e.value.replace(/^ /,'') + " ?&gt;</span></div>";
		else if (xml_e.type == "comment")
			return "<div><span class=\"symbol\">&lt;!--</span> <span class=\"comment\">" + xml_e.value + "</span> <span class=\"symbol\">--&gt;</span></div>";
		else if (xml_e.type == "chardata")
			return "<span class=\"data\">" + xml_e.value + "</span>";
	}
}

// Ver .91 Feb 21 1998
//////////////////////////////////////////////////////////////
//
//	Copyright 1998 Jeremie
//	Free for public non-commercial use and modification
//	as long as this header is kept intact and unmodified.
//	Please see http://www.jeremie.com for more information
//	or email jer@jeremie.com with questions/suggestions.
//
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
////////// Simple XML Processing Library //////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
////   Fully complies to the XML 1.0 spec 
////   as a well-formed processor, with the
////   exception of full error reporting and
////   the document type declaration(and it's
////   related features, internal entities, etc).
///////////////////////////////////////////////////////////////


/////////////////////////
//// the object constructors for the hybrid DOM

function _element()
{
	this.type = "element";
	this.name = new String();
	this.attributes = new Array();
	this.contents = new Array();
	this.uid = _Xparse_count++;
	_Xparse_index[this.uid]=this;
}

function _chardata()
{
	this.type = "chardata";
	this.value = new String();
}

function _pi()
{
	this.type = "pi";
	this.value = new String();
}

function _comment()
{
	this.type = "comment";
	this.value = new String();
}

// an internal fragment that is passed between functions
function _frag()
{
	this.str = new String();
	this.ary = new Array();
	this.end = new String();
}

/////////////////////////


// global vars to track element UID's for the index
var _Xparse_count = 0;
var _Xparse_index = new Array();


/////////////////////////
//// Main public function that is called to 
//// parse the XML string and return a root element object

function Xparse(src)
{
	var frag = new _frag();

	// remove bad \r characters and the prolog
	frag.str = _prolog(src);

	// create a root element to contain the document
	var root = new _element();
	root.name="ROOT";

	// main recursive function to process the xml
	frag = _compile(frag);

	// all done, lets return the root element + index + document
	root.contents = frag.ary;
	root.index = _Xparse_index;
	_Xparse_index = new Array();
	return root;
}

/////////////////////////


/////////////////////////
//// transforms raw text input into a multilevel array
function _compile(frag)
{
	// keep circling and eating the str
	while(1)
	{
		// when the str is empty, return the fragment
		if(frag.str.length == 0)
		{
			return frag;
		}

		var TagStart = frag.str.indexOf("<");

		if(TagStart != 0)
		{
			// theres a chunk of characters here, store it and go on
			var thisary = frag.ary.length;
			frag.ary[thisary] = new _chardata();
			if(TagStart == -1)
			{
				frag.ary[thisary].value = _entity(frag.str);
				frag.str = "";
			}
			else
			{
				frag.ary[thisary].value = _entity(frag.str.substring(0,TagStart));
				frag.str = frag.str.substring(TagStart,frag.str.length);
			}
		}
		else
		{
			// determine what the next section is, and process it
			if(frag.str.substring(1,2) == "?")
			{
				frag = _tag_pi(frag);
			}
			else
			{
				if(frag.str.substring(1,4) == "!--")
				{
					frag = _tag_comment(frag);
				}
				else
				{
					if(frag.str.substring(1,9) == "![CDATA[")
					{
						frag = _tag_cdata(frag);
					}
					else
					{
						if(frag.str.substring(1,frag.end.length + 3) == "/" + frag.end + ">" || _strip(frag.str.substring(1,frag.end.length + 3)) == "/" + frag.end)
						{
							// found the end of the current tag, end the recursive process and return
							frag.str = frag.str.substring(frag.end.length + 3,frag.str.length);
							frag.end = "";
							return frag;
						}
						else
						{
							frag = _tag_element(frag);
						}
					}
				}
			}

		}
	}
	return "";
}
///////////////////////


///////////////////////
//// functions to process different tags

function _tag_element(frag)
{
	// initialize some temporary variables for manipulating the tag
	var close = frag.str.indexOf(">");
	var empty = (frag.str.substring(close - 1,close) == "/");
	if(empty)
	{
		close -= 1;
	}

	// split up the name and attributes
	var starttag = _normalize(frag.str.substring(1,close));
	var nextspace = starttag.indexOf(" ");
	var attribs = new String();
	var name = new String();
	if(nextspace != -1)
	{
		name = starttag.substring(0,nextspace);
		attribs = starttag.substring(nextspace + 1,starttag.length);
	}
	else
	{
		name = starttag;
	}

	var thisary = frag.ary.length;
	frag.ary[thisary] = new _element();
	frag.ary[thisary].name = _strip(name);
	if(attribs.length > 0)
	{
		frag.ary[thisary].attributes = _attribution(attribs);
	}
	if(!empty)
	{
		// !!!! important, 
		// take the contents of the tag and parse them
		var contents = new _frag();
		contents.str = frag.str.substring(close + 1,frag.str.length);
		contents.end = name;
		contents = _compile(contents);
		frag.ary[thisary].contents = contents.ary;
		frag.str = contents.str;
	}
	else
	{
		frag.str = frag.str.substring(close + 2,frag.str.length);
	}
	return frag;
}

function _tag_pi(frag)
{
	var close = frag.str.indexOf("?>");
	var val = frag.str.substring(2,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _pi();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 2,frag.str.length);
	return frag;
}

function _tag_comment(frag)
{
	var close = frag.str.indexOf("-->");
	var val = frag.str.substring(4,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _comment();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 3,frag.str.length);
	return frag;
}

function _tag_cdata(frag)
{
	var close = frag.str.indexOf("]]>");
	var val = frag.str.substring(9,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _chardata();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 3,frag.str.length);
	return frag;
}

/////////////////////////


//////////////////
//// util for element attribute parsing
//// returns an array of all of the keys = values
function _attribution(str)
{
	var all = new Array();
	while(1)
	{
		var eq = str.indexOf("=");
		if(str.length == 0 || eq == -1)
		{
			return all;
		}

		var id1 = str.indexOf("\'");
		var id2 = str.indexOf("\"");
		var ids = new Number();
		var id = new String();
		if((id1 < id2 && id1 != -1) || id2 == -1)
		{
			ids = id1;
			id = "\'";
		}
		if((id2 < id1 || id1 == -1) && id2 != -1)
		{
			ids = id2;
			id = "\"";
		}
		var nextid = str.indexOf(id,ids + 1);
		var val = str.substring(ids + 1,nextid);

		var name = _strip(str.substring(0,eq));
		var len = all.length;
		all[name] = _entity(val);
		if (len == all.length)
			all.length++;
		str = str.substring(nextid + 1,str.length);
	}
	return "";
}
////////////////////


//////////////////////
//// util to remove \r characters from input string
//// and return xml string without a prolog
function _prolog(str)
{
	var A = new Array();

	A = str.split("\r\n");
	str = A.join("\n");
	A = str.split("\r");
	str = A.join("\n");

	var start = str.indexOf("<");
	if(str.substring(start,start + 3) == "<?x" || str.substring(start,start + 3) == "<?X" )
	{
		var close = str.indexOf("?>");
		str = str.substring(close + 2,str.length);
	}
	var start = str.indexOf("<!DOCTYPE");
	if(start != -1)
	{
		var close = str.indexOf(">",start) + 1;
		var dp = str.indexOf("[",start);
		if(dp < close && dp != -1)
		{
			close = str.indexOf("]>",start) + 2;
		}
		str = str.substring(close,str.length);
	}
	return str;
}
//////////////////


//////////////////////
//// util to remove white characters from input string
function _strip(str)
{
	var A = new Array();

	A = str.split("\n");
	str = A.join("");
	A = str.split(" ");
	str = A.join("");
	A = str.split("\t");
	str = A.join("");

	return str;
}
//////////////////


//////////////////////
//// util to replace white characters in input string
function _normalize(str)
{
	var A = new Array();

	A = str.split("\n");
	str = A.join(" ");
	A = str.split("\t");
	str = A.join(" ");

	return str;
}
//////////////////


//////////////////////
//// util to replace internal entities in input string
function _entity(str)
{
	var A = new Array();

	A = str.split("&lt;");
	str = A.join("<");
	A = str.split("&gt;");
	str = A.join(">");
	A = str.split("&quot;");
	str = A.join("\"");
	A = str.split("&apos;");
	str = A.join("\'");
	A = str.split("&amp;");
	str = A.join("&");

	return str;
}
//////////////////
