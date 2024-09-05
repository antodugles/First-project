// RFS class: Contains functionality for the RFS menu.
//	Author:		Andy Kant (Andrew.Kant@ge.com)
//	Date:		Jun.23.2006
//	Modified:	Jul.06.2006
var Menu = {
	// Update menu on load.
	doLoad: function() {
		// Replace body.
		var xml = FileIO.loadXML("./xml/rfs_config.xml");
		var xsl = FileIO.loadXML("./xsl/menu.xsl");
		document.body.innerHTML = FileIO.transformXML(xml, xsl);
	}
}

// Load initial data.
CSSpp.addEvent(window, "load", Menu.doLoad);