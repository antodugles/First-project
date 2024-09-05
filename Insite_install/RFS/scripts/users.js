// Users class: Contains functionality for the RFS users management page.
//	Author:		Andy Kant (Andrew.Kant@ge.com)
//	Date:		Jul.17.2006
//	Modified:	Jul.18.2006
var Users = {
	// VARIABLES
	// Button current pressed (if any).
	button: false,
	// Array of recent contacts (up to 15).
	recent: new Array(),
	recentUnsorted: new Array(),
	// Is edit mode active?
	editMode: false,
	// Remove confirmation string.
	removeString: "",
	// User row strings.
	editString: "",
	cancelString: "",
	saveString: "",
	// Is machine RFS enabled?
	machineRFS: false,
	
	// Toggle AddUser form.
	toggleAddUserForm: function() {
		var adduser = Users.$("adduser");
		if (adduser.style.display != "block")
			adduser.style.display = "block";
		else
		{
			adduser.style.display = "none";
			Users.reset();
		}
	},
	
	// Check all users in a table.
	checkAll: function(e) {
		// Grab table.
		var table = e.parentNode.parentNode.parentNode;
		if (table)
		{
			var cb = table.getElementsByTagName("INPUT");
			for (var i = 0; i < cb.length; i++)
			{
				if (cb[i].type == "checkbox")
					cb[i].checked = e.checked;
			}
		}
	},
	
	// Deselect "check all" as necessary.
	validateCheck: function(e) {
		// Grab table.
		var table = e.parentNode.parentNode.parentNode;
		if (table)
		{
			var type = e.parentNode.parentNode.parentNode.parentNode.parentNode.id.replace("_table","");
			var cb = table.getElementsByTagName("INPUT");
			var result = true;
			for (var i = 0; i < cb.length; i++)
			{
				if (cb[i].type == "checkbox" && cb[i] != Users.$(type+"_checkbox"))
					result = result && cb[i].checked;
			}
			Users.$(type+"_checkbox").checked = result;
		}
	},
	
	// Checks for selected users.
	hasChecks: function(e) {
		// Grab table.
		var table = Users.$(e);
		if (table)
		{
			var type = table.id.replace("_table","");
			var cb = table.getElementsByTagName("INPUT");
			for (var i = 0; i < cb.length; i++)
			{
				if (cb[i].type == "checkbox" && cb[i] != Users.$(type+"_checkbox") && cb[i].checked)
					return true;
			}
			return false;
		}
	},
	
	// Remove selected users from a table.
	removeUsers: function(e) {
		e = Users.$(e);
		if (e && Users.hasChecks(e) && confirm(Users.removeString))
		{
			var cb = e.getElementsByTagName("INPUT");
			for (var i = cb.length-1; i >= 0; i--)
			{
				if (cb[i].type == "checkbox" && cb[i].checked && cb[i].parentNode.parentNode.className != "header")
				{
					var row = cb[i].parentNode.parentNode;
					row.parentNode.removeChild(row);
				}
			}
			Users.saveRow(false, e.id.replace("_table",""));
		}
	},
	
	// Set the selected user as the default contact for machine generated RFS.
	setDefaultUser: function(e) {
		e = Users.$(e);
		if (e && Users.hasChecks(e))
		{
			// Reset the old default contact
			var tr = Users.$("default");
			if (tr)
				tr.id = "";  
			// Set the first slected user as the default contact
			var cb = e.getElementsByTagName("INPUT");
			for (var i = 0; i < cb.length; i++)
			{
				if (cb[i].type == "checkbox" && cb[i].checked && cb[i].parentNode.parentNode.className != "header")
				{
					var row = cb[i].parentNode.parentNode;
					// Set the id of the new default contact to "default"
					row.id = "default";
					break;
				}
			}
			// Save and reload
			Users.saveRow(false, e.id.replace("_table",""));
		}
	},
	
	// Toggle edit mode.
	editRow: function(row) {
		row = Users.$(row);
		if (Users.editMode == false && row)
		{
			// Prevent other rows from editing while this row is active.
			Users.editMode = {last: false, first: false, phone: false, ext: false, email: false};
			// Change to edit row class.
			if (!/editrow/.test(row.className))
				row.className += " editrow";
			// Create input elements.
			var cells = row.getElementsByTagName("TD");
			for (var i = 0; i < cells.length; i++)
			{
				if (/actions/.test(cells[i].className))
					cells[i].innerHTML = "<a href=\"javascript:if (Users.validateRow('" + row.id + "')) Users.saveRow('" + row.id + "');\" class=\"save\" title=\"" + Users.saveString + "\">" + Users.saveString + "</a><a href=\"javascript:Users.cancelRow('" + row.id + "');\" class=\"cancel\" title=\"" + Users.cancelString + "\">" + Users.cancelString + "</a>";
				else if (/cbox/.test(cells[i].className))
					cells[i].innerHTML = "";
				else if (/last/.test(cells[i].className))
				{
					Users.editMode.last = cells[i].innerHTML;
					cells[i].innerHTML = "<input type=\"text\" value=\"" + Users.editMode.last + "\" class=\"text edit\" maxlength=\"25\" onchange=\"Users.capitalize(this); Users.validate(this,/^[A-Z-.]{1,25}$/);\" onkeyup=\"Users.capitalize(this); Users.validate(this,/^[A-Z-.]{1,25}$/);\"/>";
				}
				else if (/first/.test(cells[i].className))
				{
					Users.editMode.first = cells[i].innerHTML;
					cells[i].innerHTML = "<input type=\"text\" value=\"" + Users.editMode.first + "\" class=\"text edit\" maxlength=\"25\" onchange=\"Users.capitalize(this); Users.validate(this,/^[A-Z-.]{1,25}$/);\" onkeyup=\"Users.capitalize(this); Users.validate(this,/^[A-Z-.]{1,25}$/);\" />";
				}
				else if (/phone/.test(cells[i].className))
				{
					Users.editMode.phone = cells[i].innerHTML;
					cells[i].innerHTML = "<input type=\"text\" value=\"" + Users.editMode.phone + "\" class=\"text edit\" maxlength=\"25\" onchange=\"Users.validate(this,/^[0-9-*#.]{1,25}$/);\" onkeyup=\"Users.validate(this,/^[0-9-*#\.]{1,25}$/);\" />";
				}
				else if (/ext/.test(cells[i].className))
				{
					Users.editMode.ext = cells[i].innerHTML;
					cells[i].innerHTML = "<input type=\"text\" value=\"" + Users.editMode.ext + "\" class=\"text edit\" maxlength=\"25\" onchange=\"Users.validate(this,/^[0-9-*#.]{0,25}$/);\" onkeyup=\"Users.validate(this,/^[0-9-*#]{0,25}$/);\" />";
				}
				else if (/email/.test(cells[i].className))
				{
					Users.editMode.email = cells[i].innerHTML;
					cells[i].innerHTML = "<input type=\"text\" value=\"" + Users.editMode.email + "\" class=\"text edit\" maxlength=\"50\" onchange=\"Users.validate(this,/^.{0,50}$/);\" onkeyup=\"Users.validate(this,/^.{0,50}$/);\" />";
				}
			}
		}
	},
	
	// Restore old values of an edit row.
	cancelRow: function(row) {
		row = Users.$(row);
		if (Users.editMode != false && row)
		{
			// Create input elements.
			var cells = row.getElementsByTagName("TD");
			for (var i = 0; i < cells.length; i++)
			{
				if (/actions/.test(cells[i].className))
					cells[i].innerHTML = "<a href=\"javascript:Users.editRow('" + row.id + "');\" class=\"edit\" title=\"" + Users.editString + "\">" + Users.editString + "</a>";
				else if (/cbox/.test(cells[i].className))
				{
					var type = row.parentNode.parentNode.parentNode.id.replace(/_table/,"");
					if (Users.$(type+"_checkbox").checked)
						cells[i].innerHTML = "<input type=\"checkbox\" onclick=\"Users.validateCheck(this);\" checked=\"true\" />";
					else
						cells[i].innerHTML = "<input type=\"checkbox\" onclick=\"Users.validateCheck(this);\" />";
				}
				else if (/last/.test(cells[i].className))
					cells[i].innerHTML = Users.editMode.last;
				else if (/first/.test(cells[i].className))
					cells[i].innerHTML = Users.editMode.first;
				else if (/phone/.test(cells[i].className))
					cells[i].innerHTML = Users.editMode.phone;
				else if (/ext/.test(cells[i].className))
					cells[i].innerHTML = Users.editMode.ext;
				else if (/email/.test(cells[i].className))
					cells[i].innerHTML = Users.editMode.email;
			}
			// Restore old mode.
			Users.editMode = false;
			row.className = row.className.replace(/editrow/g,"");
		}
	},
	
	// Save the row (thereby saving the entire table).
	saveRow: function(row, override, noReload) {
		// Apply changes to row.
		row = Users.$(row);
		if (Users.editMode != false && row)
		{
			// Create input elements.
			var cells = row.getElementsByTagName("TD");
			for (var i = 0; i < cells.length; i++)
			{
				if (/actions/.test(cells[i].className))
					cells[i].innerHTML = "<a href=\"javascript:Users.editRow('" + row.id + "');\" class=\"edit\" title=\"" + Users.editString + "\">" + Users.editString + "</a>";
				else if (/cbox/.test(cells[i].className))
				{
					var type = row.parentNode.parentNode.parentNode.id.replace(/_table/,"");
					if (Users.$(type+"_checkbox").checked)
						cells[i].innerHTML = "<input type=\"checkbox\" onclick=\"Users.validateCheck(this);\" checked=\"true\" />";
					else
						cells[i].innerHTML = "<input type=\"checkbox\" onclick=\"Users.validateCheck(this);\" />";
				}
				else if (/last/.test(cells[i].className) && cells[i].getElementsByTagName("INPUT")[0])
					cells[i].innerHTML = cells[i].getElementsByTagName("INPUT")[0].value;
				else if (/first/.test(cells[i].className) && cells[i].getElementsByTagName("INPUT")[0])
					cells[i].innerHTML = cells[i].getElementsByTagName("INPUT")[0].value;
				else if (/phone/.test(cells[i].className) && cells[i].getElementsByTagName("INPUT")[0])
					cells[i].innerHTML = cells[i].getElementsByTagName("INPUT")[0].value;
				else if (/ext/.test(cells[i].className) && cells[i].getElementsByTagName("INPUT")[0])
					cells[i].innerHTML = cells[i].getElementsByTagName("INPUT")[0].value;
				else if (/email/.test(cells[i].className) && cells[i].getElementsByTagName("INPUT")[0])
					cells[i].innerHTML = cells[i].getElementsByTagName("INPUT")[0].value;
			}
			// Restore old mode.
			Users.editMode = false;
			row.className = row.className.replace(/editrow/g,"");
		}
		
		// Grab containers.
		var container, type;
		if (override)
		{
			type = override;
			container = Users.$(type+"_table").getElementsByTagName("TBODY")[0];
		}
		else
		{
			container = row.parentNode;
			type = row.parentNode.parentNode.parentNode.id.replace(/_table/,"");
		}
		if (type && /^users|recent$/.test(type))
		{
			// Grab data.
			var data = new Array();
			var rows = container.getElementsByTagName("TR");
			for (var j = 0; j < rows.length; j++)
			{
				// Create input elements.
				var cells = rows[j].getElementsByTagName("TD");
				var contact = {last: false, first: false, phone: false, ext: false, email: false, defaultCont: false};
				if (/default/.test(rows[j].id))
					contact.defaultCont = true;
				for (var i = 0; i < cells.length; i++)
				{
					if (/last/.test(cells[i].className) && cells[i].innerHTML.length > 0)
						contact.last = cells[i].innerHTML;
					else if (/first/.test(cells[i].className) && cells[i].innerHTML.length > 0)
						contact.first = cells[i].innerHTML;
					else if (/phone/.test(cells[i].className) && cells[i].innerHTML.length > 0)
						contact.phone = cells[i].innerHTML;
					else if (/ext/.test(cells[i].className) && cells[i].innerHTML.length > 0)
						contact.ext = cells[i].innerHTML;
					else if (/email/.test(cells[i].className) && cells[i].innerHTML.length > 0)
						contact.email = cells[i].innerHTML;
				}
				// Validate new contact (if any).
				if (contact.last && contact.first && contact.phone)
					data.push(contact);
			}
			// Sort the users if necessary.
			if (type == "users")
			{
				// Bubble sort the contacts.
				for (var i = 0; i < data.length; i++)
				{
					for (var j = 0; j < data.length; j++)
					{
						if (Users.bubbleCompare(data[i], data[j]))
						{
							var tmp = data[i];
							data[i] = data[j];
							data[j] = tmp;
						}
					}
				}
			}			
			// Generate XML.
			var newline = "\r\n";
			var xml = new Array();
			xml.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"+newline);
			xml.push("<"+type+"RFS>"+newline);
			for (var i = 0; i < data.length; i++)
			{
				if (data[i].defaultCont)
					xml.push("\t<contact default=\"true\">"+newline);
				else
					xml.push("\t<contact>"+newline);
				xml.push("\t\t<Last>"+data[i].last+"</Last>"+newline);
				xml.push("\t\t<First>"+data[i].first+"</First>"+newline);
				xml.push("\t\t<Phone>"+data[i].phone+"</Phone>"+newline);
				if (data[i].ext) xml.push("\t\t<Ext>"+data[i].ext+"</Ext>"+newline);
				if (data[i].email) xml.push("\t\t<Email>"+data[i].email+"</Email>"+newline);
				xml.push("\t</contact>"+newline);
			}		
			xml.push("</"+type+"RFS>");
			// Save XML.
			if (type == "users")
				FileIO.saveXML("./xml/users.xml", FileIO.makeDOMDocument(xml.join("")));
			else if (type == "recent")
				FileIO.saveXML("./xml/users_recent.xml", FileIO.makeDOMDocument(xml.join("")));
			// Reload the page body.
			if (!noReload)
				Users.doLoad();
		}
	},
	
	// Add new permanent user.
	addUser: function() {
		var form = Users.$("adduser");
		var fields = form.getElementsByTagName("INPUT");
		var contact = {last: false, first: false, phone: false, ext: false, email: false,  defaultCont: false};
		for (var i = 0; i < fields.length; i++)
		{
			if (/Last/.test(fields[i].name) && fields[i].value.length > 0)
				contact.last = fields[i].value;
			else if (/First/.test(fields[i].name) && fields[i].value.length > 0)
				contact.first = fields[i].value;
			else if (/Phone/.test(fields[i].name) && fields[i].value.length > 0)
				contact.phone = fields[i].value;
			else if (/Ext/.test(fields[i].name) && fields[i].value.length > 0)
				contact.ext = fields[i].value;
			else if (/Email/.test(fields[i].name) && fields[i].value.length > 0)
				contact.email = fields[i].value;
		}
		
		// Validate and save.
		if (contact.last && contact.first && contact.phone)
		{
			// Add row to table.
			var row = document.createElement("TR");
			row.id = "newuser";
			var last = document.createElement("TD");
			last.className = "last";
			last.innerHTML = contact.last;
			row.appendChild(last);
			var first = document.createElement("TD");
			first.className = "first";
			first.innerHTML = contact.first;
			row.appendChild(first);
			var phone = document.createElement("TD");
			phone.className = "phone";
			phone.innerHTML = contact.phone;
			row.appendChild(phone);
			if (contact.ext)
			{
				var ext = document.createElement("TD");
				ext.className = "ext";
				ext.innerHTML = contact.ext;
				row.appendChild(ext);
			}
			if (contact.email)
			{
				var email = document.createElement("TD");
				email.className = "email";
				email.innerHTML = contact.email;
				row.appendChild(email);
			}
			
			// Grab table.
			var tbody = Users.$("users_table").getElementsByTagName("TBODY");
			if (tbody && tbody[0])
			{
				// Make this user as the default machine RFS contact if this is the first permanent user.
				var rows = tbody[0].getElementsByTagName("TR");
				if (rows.length == 3 && Users.machineRFS)
					row.id = "default";
				// Save data.
				tbody[0].appendChild(row);
				Users.saveRow(false, "users");
			}
		}
	},
	
	makePermanent: function() {
		// Select rows.
		var e = Users.$("recent_table");
		var users = Users.$("users_table").getElementsByTagName("TBODY");
		var rows = new Array();
		if (e)
		{
			var cb = e.getElementsByTagName("INPUT");
			for (var i = cb.length-1; i >= 0; i--)
			{
				if (cb[i].type == "checkbox" && cb[i].checked && cb[i].parentNode.parentNode.className != "header")
				{
					var row = cb[i].parentNode.parentNode;
					if (users && users[0])
						users[0].appendChild(row);
				}
			}
			Users.saveRow(false, "users", true);
			Users.saveRow(false, "recent");
		}
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
		e.className = e.className.replace(/invalid/g,"").replace(/valid/g,"");
		is_valid ? e.className += " valid" : e.className += " invalid";
		Users.validateAddUser();
		return is_valid;
	},
	
	// Validate a row.
	validateRow: function(row) {
		// Grab all textual form elements.
		row = Users.$(row);
		var input =  row.getElementsByTagName("INPUT");
		var e = new Array();
		for (var i in input)
			e.push(input[i]);
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
		
		// Return result.
		return result;
	},
	
	// Validate the entire form. Updates the style of the AddUser button.
	validateAddUser: function() {
		// Grab all textual form elements.
		var au = Users.$("adduser");
		var input =  au.getElementsByTagName("INPUT");
		var e = new Array();
		for (var i in input)
			e.push(input[i]);
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
		
		// Update AddUser button style.
		var adduser = Users.$("addUserButton");
		if (result && /disabled/.test(adduser.className))
			adduser.className = adduser.className.replace("disabled", "enabled");
		else if (!result && /enabled/.test(adduser.className))
			adduser.className = adduser.className.replace("enabled", "disabled");
		
		// Return result.
		return result;
	},
	
	// Reset the form, clearing all data.
	reset: function() {
		// Reset all input fields.
		var input = Users.$("adduser").getElementsByTagName("INPUT");
		for (var i = 0; i < input.length; i++)
		{
			if (input[i].type && input[i].type == "text")
			{
				input[i].value = "";
				input[i].className = "valid";
			}
		}
		// Validate the form.
		Users.validateAddUser();
	},
	
	// Update button style while pushed.
	buttonDown: function(e) {
		Users.button = e;
		if (/disabled/.test(e.className))
			e.className = "button pushed disabled";
		else
			e.className = "button pushed enabled";
	},
	
	// Update button style while hovered and previously pushed.
	buttonOver: function(e) {
		if (Users.button == e)
		{
			if (/disabled/.test(e.className))
				e.className = "button pushed disabled";
			else
				e.className = "button pushed enabled";
		}
	},
	
	// Update button style while released.
	buttonUp: function(e) {
		Users.button = false;
		if (/disabled/.test(e.className))
			e.className = "button released disabled";
		else
			e.className = "button released enabled";
	},
	
	// Update button style while it the mouse is away.
	buttonOut: function(e) {
		if (Users.button == e)
		{
			if (/disabled/.test(e.className))
				e.className = "button released disabled";
			else
				e.className = "button released enabled";
		}
	},
	
	// Force button reset.
	mouseUp: function(e) {
		Users.button = false;
	},
	
	// Update form on load.
	doLoad: function() {
		// Replace body.
		var xml = FileIO.loadXML("./xml/rfs_config.xml");
		var xsl = FileIO.loadXML("./xsl/users.xsl");
		document.body.innerHTML = FileIO.transformXML(xml, xsl);
		
		// Execute all transformed scripts. (They get ignored otherwise.)
		var s = document.body.getElementsByTagName("SCRIPT");
		for (var i = 0; i < s.length; i++)
			eval(s[i].text);
		
		// Update form status.
		Users.reset();
		Users.validateAddUser();
		
		// Enforce unique check.
		Users.enforceUnique();
	},
	
	// Enforce unique check, permanent users get priority.
	enforceUnique: function() {
		// Grab data.
		var data = new Array();
		var reload = false;
		var rows;
		
		// Add permanent users.
		var rows = Users.$("users_table").getElementsByTagName("TR");
		for (var j = rows.length-1; j >= 0; j--)
		{
			// Create input elements.
			var cells = rows[j].getElementsByTagName("TD");
			var contact = {last: false, first: false, phone: false, ext: false, email: false};
			for (var i = 0; i < cells.length; i++)
			{
				if (/last/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.last = cells[i].innerHTML;
				else if (/first/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.first = cells[i].innerHTML;
				else if (/phone/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.phone = cells[i].innerHTML;
				else if (/ext/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.ext = cells[i].innerHTML;
				else if (/email/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.email = cells[i].innerHTML;
			}
			// Validate new contact (if any).
			if (contact.last && contact.first && contact.phone)
			{
				if (Users.contactExists(data, contact))
				{
					reload = true;
					rows[j].parentNode.removeChild(rows[j]);
				}
				else
					data.push(contact);
			}
		}
		
		// Add recent users.
		var rows = Users.$("recent_table").getElementsByTagName("TR");
		for (var j = rows.length-1; j >= 0; j--)
		{
			// Create input elements.
			var cells = rows[j].getElementsByTagName("TD");
			var contact = {last: false, first: false, phone: false, ext: false, email: false};
			for (var i = 0; i < cells.length; i++)
			{
				if (/last/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.last = cells[i].innerHTML;
				else if (/first/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.first = cells[i].innerHTML;
				else if (/phone/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.phone = cells[i].innerHTML;
				else if (/ext/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.ext = cells[i].innerHTML;
				else if (/email/.test(cells[i].className) && cells[i].innerHTML.length > 0)
					contact.email = cells[i].innerHTML;
			}
			// Validate new contact (if any).
			if (contact.last && contact.first && contact.phone)
			{
				if (Users.contactExists(data, contact))
				{
					reload = true;
					rows[j].parentNode.removeChild(rows[j]);
				}
				else
					data.push(contact);
			}
		}
		
		// Reload if non-uniques were found.
		if (reload)
		{
			Users.saveRow(false, "users", true);
			Users.saveRow(false, "recent");
			Users.doLoad();
		}
	},
	
	// Check if contact is already in the contacts list.
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
	}
}

// Add events (requires CSSpp library).
CSSpp.addEvent(window, "load", Users.doLoad);
CSSpp.addEvent(document, "mouseup", Users.mouseUp);