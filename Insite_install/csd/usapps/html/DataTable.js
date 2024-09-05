// DataTable class: Contains functionality for a dynamic datatable system.
//  Author:    Andy Kant (Andrew.Kant@ge.com)
//  Date:      Aug.10.2006
//  Modified:  Feb.19.2007
//  Notes:
//    DataTable includes and uses modified subsets of the following frameworks:
//      Prototype:
//        Prototype JavaScript framework, version 1.4.0
//        (c) 2005 Sam Stephenson <sam@conio.net>
//        Prototype is freely distributable under the terms of an MIT-style license.
//        For details, see the Prototype web site: http://prototype.conio.net/
//      Dojo Toolkit:
//        Copyright (c) 2004-2006, The Dojo Foundation
//        All Rights Reserved.
//        Licensed under the modified BSD license. For more information on Dojo licensing, see:
//        http://dojotoolkit.org/community/licensing.shtml
var DataTable = {
	// Member variables.
	datatables: [],          // Array of rendered datatables.
	datasets: {},            // Object of datasets, indexed by table ID.
	prerenderDatasets: [],   // Array of datasets to prerender.
	adjusting: [],           // Used to prevent IE's auto-multipass.
	loaded: false,           // Is the page already loaded?
	
	// Initialize.
	doLoad: function() {
		// Render all prerendered datasets if they are valid.
		DataTable.loaded = true;
		for (var i = (DataTable.prerenderDatasets.length - 1); i > -1; i--)
		{
			// Render the datatable and remove the dataset from the prerender list.
			if (DataTable.renderDataset(DataTable.prerenderDatasets[i]))
				DataTable.prerenderDatasets.splice(i, 1); 
		}
	},
	
	// Handle resize event.
	resize: function(e) {
		// Stop observing window.onresize temporarily (fixes IE infinite event bug).
		DataTable.removeEvent(window, "resize", DataTable.resize);
		// Adjust sizing of datatables, delay to allow IE to render.
		setTimeout("DataTable.adjust()", 5);
		// Resume observing window.onresize after a delay (fixes IE infinite event bug).
		setTimeout("Event.observe(window, \"resize\", DataTable.resize)", 100);
	},
	
	// Set the adjust status.
	setAdjusting: function(datatable_id) {
		for (var i = 0; i < DataTable.adjusting.length; i++)
		{
			if (DataTable.adjusting[i] == datatable_id)
				return;
		}
		DataTable.adjusting.push(datatable_id);
	},
	
	// Clear the adjust status.
	clearAdjusting: function(datatable_id) {
		for (var i = 0; i < DataTable.adjusting.length; i++)
		{
			if (DataTable.adjusting[i] == datatable_id)
			{
				DataTable.adjusting.splice(i, 1);
				break;
			}
		}
	},
	
	// Return the adjust status.
	isAdjusting: function(datatable_id) {
		for (var i = 0; i < DataTable.adjusting.length; i++)
		{
			if (DataTable.adjusting[i] == datatable_id)
				return true;
		}
		return false;
	},
	
	// Adjust sizing of datatables.
	adjust: function(datatable) {
		datatable = datatable || false;
		if (datatable)
			var tables = new Array(datatable);
		else
			var tables = document.getElementsByTagName("TABLE");
		for (var z = 0; z < tables.length; z++)
		{
			if (/datatable/.test(tables[z].className) && !DataTable.isAdjusting(tables[z].id))
			{
				var dataset = DataTable.datasets[tables[z].id];
				// Set the adjust status.
				DataTable.setAdjusting(tables[z].id);
				
				// Grab header cells.
				var footer = false;
				var th = tables[z].getElementsByTagName("TH");
				// Reset header.
				for (var i = 0; i < th.length; i++)
				{
					// Hide content of header.
					var th_p = th[i].getElementsByTagName("P");
					th_p = (th_p[0] || false) ? th_p[0] : false;
					if (th_p)
						th_p.style.display = "none";
					// Reset precentage width for column.
					th[i].style.width = dataset.columns[i].width;
				}
				// Fix header display.
				for (var i = 0; i < th.length; i++)
				{
					// Find header children.
					var th_p = th[i].getElementsByTagName("P");
					th_p = (th_p[0] || false) ? th_p[0] : false;
					var th_div = th[i].getElementsByTagName("DIV");
					var div_found = false;
					for (var j = 0; j < th_div.length; j++)
					{
						if (/filter/i.test(th_div[j].className))
						{
							th_div = th_div[j];
							th_div.style.right = "0px";
							div_found = true;
							break;
						}
					}
					th_div = div_found ? th_div : false;
					
					// Update header content widths.
					if (th_p && th_div)
					{
						th_p.style.display = "block";
						var err = (th_div.parentNode.offsetWidth - th_div.offsetLeft - 20);
						err = err > 0 ? err * -1 : 0;
						if (i == (th.length - 1))
							err--;
						th_div.style.right = err + "px";
					}
					else if (th_p)
						th_p.style.display = "block";
				}
				// Fix table body height if the table is scrollable.
				if (dataset.style.scrollable)
				{
					if (document.all)
					{
						var container = tables[z].getElementsByTagName("TABLE");
						container = container.length > 0 ? container[0].parentNode : false;
						var header = tables[z].getElementsByTagName("TH");
						header = header.length > 0 ? header[0].parentNode : false;
						if (container && header)
						{
							// Reset height.
							container.style.height = "auto";
							if (document.all && tables[z].offsetHeight > dataset.style.maxHeight)
							{
								if (dataset.style.maxHeight - header.offsetHeight - 2 > 0)
									container.style.height = (dataset.style.maxHeight - header.offsetHeight - 2) + "px";
							}
							// Fix filter list offset for IE when the table is scrollable.
							var ul = tables[z].getElementsByTagName("UL");
							for (var i = 0; i < ul.length; i++)
								ul[i].style.marginTop = (-1 * (container.offsetHeight) - 1) + "px";
							// Continue to add padding to last cell.
							var tr = container.getElementsByTagName("TR");
							for (var i = 0; i < tr.length; i++)
							{
								if (!/filters/i.test(tr[i].className))
								{
									var td = tr[i].getElementsByTagName("TD");
									td = td.length > 0 ? td[td.length-1] : false;
									if (td)
									{
										var p = td.getElementsByTagName("P");
										p = p.length > 0 ? p[0] : false;
										if (p && parseFloat(DataTable.style(p, "paddingRight").replace(/px/ig, ""), 10) < 22)
										{
											var tmp = 22 + parseFloat(DataTable.style(p, "paddingRight").replace(/px/ig, ""), 10);
											p.style.paddingRight = tmp + "px";
										}
									}
								}
								else
									footer = (tr[i]);
							}
						}
						
					}
					else
					{
						var tbody = tables[z].getElementsByTagName("TBODY");
						tbody = tbody.length > 0 ? tbody[0] : false;
						if (tbody)
						{
							// Check if scrolling is in use before applying extra padding.
							tbody.style.height = "auto";
							var header = th.length > 0 ? th[0].parentNode : false;
							if (tables[z].offsetHeight > dataset.style.maxHeight && header)
							{
								// Adjust TBODY height.
								tbody.style.height = (dataset.style.maxHeight - header.offsetHeight - 2) + "px";
								// Continue to add padding to last cell.
								var tr = tbody.getElementsByTagName("TR");
								for (var i = 0; i < tr.length; i++)
								{
									if (!/filters/i.test(tr[i].className))
									{
										var td = tr[i].getElementsByTagName("TD");
										td = td.length > 0 ? td[td.length-1] : false;
										if (td)
										{
											var p = td.getElementsByTagName("P");
											p = p.length > 0 ? p[0] : false;
											if (p && parseFloat(DataTable.style(p, "paddingRight").replace(/px/ig, ""), 10) < 16)
											{
												var tmp = 16 + parseFloat(DataTable.style(p, "paddingRight").replace(/px/ig, ""), 10);
												p.style.paddingRight = tmp + "px";
											}
										}
									}
									else
										footer = (tr[i]);
								}
							}
						}
					}
				}
				
				// Adjust filter list widths.
				var ul = tables[z].getElementsByTagName("UL");
				for (var i = 0; i < ul.length; i++)
				{
					var hcell = th[ul[i].parentNode.cellIndex];
					ul[i].style.width = (hcell.offsetWidth - 1) + "px";
					if (footer) {
						ul[i].style.marginTop = (-1 * (datatable.offsetHeight - header.offsetHeight 
							+ footer.parentNode.scrollHeight - footer.parentNode.offsetHeight 
							- footer.parentNode.scrollTop) + 1) + "px";
					}
				}
				// Reset the adjust status (after delay).
				setTimeout("DataTable.clearAdjusting(\"" + tables[z].id + "\")", 50);
			}
		}
	},
	
	// Custom typeof, needs to be checked via regex.
	otypeof: function(object) {
		var type = typeof object;
		if (!/object/i.test(type))
			return type;
		else
		{
			if (object.constructor != null && object.constructor.toString)
				return object.constructor.toString();
			else
				return object.toString();
		}
	},
	
	// Validate a dataset.
	validateDataset: function(dataset) {
		/* Example dataset.
		var dataset = {
			// ID if applicable. (false or string)
			id: false,
			// Class if applicable. (false or string)
			className: false,
			// Owner if applicable. (false or string[ID] or element)
			//	If false, the datatable will be appended to the body element.
			owner: false,
			// Sorting column and direction.
			sort: {
				// Column must be defined and match the ref of a column that is sortable.
				//	This column is also made the base sorting column in that if two values
				//	are equal, it will use this column as a secondary sort. (string)
				column: "name",
				// Sort in ascending order if true or descending order if false. (boolean)
				ascending: true
			},
			// List of columns within the table.
			columns: new Array(
				// The columns for a datatable must be defined.
				// Each column has the following properties:
				//	name		The interface name for the column. (string)
				//	ref			The internal name for the column that corresponds
				//					to an object in dataset.data. References must
				//					be unique. The ref may only contain these
				//					characters: a-z, A-Z, 0-9. (string)
				//	width		The width of the column. (string - as a percentage)
				//	filter		Whether to enable filtering. (boolean or string to specify filter)
				//	sort		Whether to enable sorting. (true or false)
				//					Atleast one column must be sortable.
				{ name: "Column #1", ref: "name", width: "30%", filter: true, sort: true },
				{ name: "Column #2", ref: "value", width: "70%", filter: false, sort: true }
			),
			// List of customizable table styles.
			style: {
				// Should the body of the table scrollable? (boolean)
				scrollable: true,
				// Maximum height (pixels) of the datatable, only used if table is scrollable. (number)
				maxHeight: 400,
				// The width of the table in a valid CSS width string. (string)
				width: "90%"
			},
			// Array of data rows including interface and internal representations of data.
			//	May include extra columns not listed in the columns object which will not be validated.
			data: new Array(
				{
					name: {
						// Text is the interface representation of the data.
						//	If text is a function, it will be called using value
						//	as a parameter; the returned result will be what is
						//	set for text. (boolean, string, number, or function)
						text: "interface_value",
						// Value is the internal value of the data. This is used for
						//	sorting as well as passing to text if text is a function.
						//	(boolean, string, number, or object)
						value: "internal_value"
					},
					value: { text: "interface_value", value: "internal_value" }
				},
				{	
					name: { text: "interface_value", value: "internal_value" },
					value: { text: "interface_value", value: "internal_value" }
				},
				{
					name: { text: "interface_value", value: "internal_value" },
					value: { text: "interface_value", value: "internal_value" }
				}
			),
			// Events applied to each row. These events will be passed the event (e)
			//	and will have a pointer to the row (this). Data for the row can be 
			//	retrieved using DataTable.getData(this) which will return the object
			//	containing the data values for that specific row.
			events: {
				click: function(e) { var data = DataTable.getData(this); },
				mouseover: function(idx) { var data = DataTable.getData(this); },
				mouseout: function(idx) { var data = DataTable.getData(this); }
			}
		}
		*/
		// Validate dataset.
		if (typeof dataset == "object")
		{
			if ( /boolean|string/i.test(typeof dataset.id) && /boolean|string/i.test(typeof dataset.className) 
			&& /boolean|string|object/i.test(typeof dataset.owner) && /object/i.test(typeof dataset.columns) 
			&& /object/i.test(typeof dataset.data) && /array/i.test(DataTable.otypeof(dataset.columns)) 
			&& /object/i.test(typeof dataset.sort) 
			&& /string/i.test(typeof dataset.sort.column) && /boolean/i.test(typeof dataset.sort.ascending) 
			&& /array/i.test(DataTable.otypeof(dataset.data)) && /object/i.test(typeof dataset.style) 
			&& /boolean/i.test(typeof dataset.style.scrollable) && /number/i.test(typeof dataset.style.maxHeight) 
			&& /string/i.test(typeof dataset.style.width) 
			&& ((/object/i.test(typeof dataset.datatable)) 
					? /HTMLTableElement/i.test(DataTable.otypeof(dataset.datatable))
					: !dataset.datatable) 
			&& ((/string|object/i.test(typeof dataset.owner)) 
					? $(dataset.owner) && $(dataset.owner).appendChild 
					: !dataset.owner) 
			&& ((/boolean/i.test(typeof dataset.id)) 
					? !dataset.id : true) 
			&& ((/boolean/i.test(typeof dataset.className)) 
					? !dataset.className : true) )
			{
				// Create data reference array for validation.
				var refs = new Array();
				// Validate columns array.
				for (var i = 0; i < dataset.columns.length; i++)
				{
					// Validate column.
					var column = dataset.columns[i];
					if (!/undefined/i.test(typeof column.name) && /string/i.test(typeof column.ref) 
					&& /string/i.test(typeof column.width) && /boolean|string/i.test(typeof column.filter) 
					&& /boolean/i.test(typeof column.sort) && /^\d{1,3}%$/i.test(column.width) 
					&& /.+/i.test(column.name) && /^[A-Za-z0-9]+$/.test(column.ref))
					{
						// Check for previous reference.
						for (var j = 0; j < refs.length; j++)
						{
							if (refs[j] == column.ref)
								return false;
						}
						// Made it this far, add ref to reference array.
						refs.push(column.ref);
					}
				}
				// Validate data array.
				for (var i = 0; i < dataset.data.length; i++)
				{
					// Clone reference array.
					var tmprefs = new Array();
					for (var k = 0; k < refs.length; k++)
						tmprefs.push(refs[k]);
					// Check reference sets.
					for (var k in dataset.data[i])
					{
						// Grab reference set.
						var refname = k;
						var refset = dataset.data[i][refname];
						
						// Check for previous reference.
						//	The dataset can stay valid while containing non-referenced sets.
						//	Only referenced sets are validated.
						for (var j = (tmprefs.length - 1); j > -1; j--)
						{
							// Reference found.
							if (tmprefs[j] == refname)
							{
								// Validate rows of reference set.
								for (var l = 0; l < refset.length; l++)
								{
									// Validate datarow.
									var row = refset[l];
									if (! (/boolean|string|number|function/i.test(typeof row.text) 
									&& /boolean|string|number|object/i.test(typeof row.value)
									&& /function/i.test(typeof row.text)
									&& /date/i.test(DataTable.otypeof(row.value))) )
										return false;
								}
								
								// Remove reference from the array.
								tmprefs.splice(j, 1);
							}
						}
					}
					// Does each reference have a corresponding set?
					//	Expecting tmprefs.length == 0 if the question is true.
					if (tmprefs.length > 0)
						return false;
				}
				// Validate sorting direction.
				for (var i = 0; i < dataset.columns.length; i++)
				{
					// Datatable is valid.
					if (dataset.columns[i].sort && dataset.columns[i].ref == dataset.sort.column)
						return true;
				}
				// Missed the sort check, datatable is invalid.
				return false;
			}
			else
				return false;
		}
		else
			return false;
	},
	
	// Add a dataset to the prerender list.
	prerenderDataset: function(dataset) {
		// Add dataset to prerender list.
		if (DataTable.loaded)
			DataTable.renderDataset(dataset);
		else
			DataTable.prerenderDatasets.push(dataset);
	},
	
	// Render a dataset.
	renderDataset: function(dataset) {
		if (DataTable.validateDataset(dataset))
		{
			// Copy default column to make it the base sorting column.
			dataset.sort.base = dataset.sort.column;
			
			// Create base element.
			var dt = document.createElement("TABLE");
			DataTable.datatables.push(dt);
			// Set up base element.
			dt.id = dataset.id || 'DataTable' + new Date().getTime();
			DataTable.datasets[dt.id] = dataset;
			dt.className = "datatable";
			if (dataset.className)
				dt.className += " " + dataset.className;
			dt.cellSpacing = 0;
			dt.cellPadding = 0;
			dt.style.width = dataset.style.width;
			// Set up structure.
			var thead = document.createElement("THEAD");
			dt.appendChild(thead);
			var tbody = document.createElement("TBODY");
			dt.appendChild(tbody);
			if (dataset.style.scrollable)
				tbody.className = "scrollable";
			
			// Set up header.
			var header = document.createElement("TR");
			thead.appendChild(header);
			header.className = "header";
			dt.header = header;
			// Define event handlers.
			var cellMouseOver = function(){ this.className += " over"; };
			var cellMouseOut = function(){ this.className = this.className.replace(/\s*over/ig, ""); };
			var cellMouseUp = function(e){
				if (!e)
					e = window.event;
				e.cancelBubble = true;
			};
			var filterClick = function(){
				// Find the corresponding filter list.
				var idx = this.parentNode.parentNode.cellIndex;
				var filters = false;
				var rows = this.parentNode.parentNode.parentNode.parentNode.parentNode.getElementsByTagName("TR");
				for (var i = rows.length - 1; i >= 0; i--)
				{
					if (/filters/.test(rows[i].className))
					{
						filters = rows[i];
						break;
					}
				}
				if (filters)
				{
					var cells = filters.getElementsByTagName("TD");
					var all_ul = filters.getElementsByTagName("UL");
					if (cells.length > idx)
					{
						var ul = cells[idx].getElementsByTagName("UL");
						ul = ul.length > 0 ? ul[0] : false;
						// Found the filter list.
						if (ul)
						{
							// Hide every other filter list.
							for (var i = 0; i < all_ul.length; i++)
							{
								if (all_ul[i] != ul)
									all_ul[i].style.display = "none";
							}
							// Toggle the selected filter list.
							ul.style.display = /^(none)?$/.test(ul.style.display) ? "block" : "none";
							// Adjust filter list height.
							if (document.all)
								ul.style.height = ul.offsetHeight > 100 ? "100px" : "auto";
						}
					}
				}
			};
			var sortClick = function(){ DataTable.updateTable(this.parentNode.parentNode.parentNode.parentNode.parentNode, { column: this.sortColumn, ascending: this.sortAscending }); };
			// Add header columns.
			for (var i = 0; i < dataset.columns.length; i++)
			{
				// Initialize header cell.
				var column = dataset.columns[i];
				var cell = document.createElement("TH");
				header.appendChild(cell);
				cell.style.width = column.width;
				cell.className = "col_" + column.ref;
				var div_container = document.createElement("DIV");
				div_container.className = "container";
				cell.appendChild(div_container);
				// Add text.
				var p = document.createElement("P");
				div_container.appendChild(p);
				p.innerHTML = "<span><span>" + column.name + "</span><span class=\"sort\">&nbsp;&nbsp;&nbsp;</span></span>";
				p.sortObserver = false;
				if (!column.filter)
				{
					p.className += " nofilter";
					if (i == (dataset.columns.length - 1))
						p.className += " last";
				}
				// Add drop-down if filters are enabled.
				var div = false;
				if (column.filter)
				{
					// Create drop-down arrow.
					div = document.createElement("DIV");
					div_container.appendChild(div);
					div.className = "filter";
					div.innerHTML = "<span></span>";
					if (i == (dataset.columns.length - 1))
					{
						div.className += " last";
						p.className += " lastfilter";
					}
				}
				
				// Add events.
				//	Add hover effect.
				Event.observe(cell, "mouseover", cellMouseOver.bindAsEventListener(cell));
				Event.observe(cell, "mouseout", cellMouseOut.bindAsEventListener(cell));
				Event.observe(cell, "mouseup", cellMouseUp);
				//	Add filter functionality.
				if (div && column.filter)
				{
					Event.observe(div, "click", filterClick.bindAsEventListener(div));
				}
				//	Add sorting functionality.
				if (column.sort)
				{
					p.sortColumn = column.ref;
					p.sortAscending = true;
					if (column.ref == dataset.sort.column && dataset.sort.ascending)
						p.sortAscending = false;
					Event.observe(p, "click", sortClick.bindAsEventListener(p));
					// Update sorting visual style.
					if (column.ref == dataset.sort.column)
					{
						if (/ascending|descending/.test(p.className))
						{
							if (dataset.sort.ascending)
								p.className = p.className.replace(/ascending|descending/, "ascending");
							else
								p.className = p.className.replace(/ascending|descending/, "descending");
						}
						else
						{
							if (dataset.sort.ascending)
								p.className += " ascending";
							else
								p.className += " descending";
						}
					}
					else
						p.className = p.className.replace(/ascending|descending/, "");
				}
			}
			
			// Append table to the DOM.
			var owner = dataset.owner ? $(dataset.owner) : document.body;
			dataset.owner = null;
			dataset.datatable = null;
			delete dataset.owner;
			delete dataset.datatable;
			// Remove the old table if it exists
			var olddt = $(dt.id);
			if (olddt)
				DataTable.destroyNode(olddt);
			owner.appendChild(dt);
			// Render datatable content.
			DataTable.updateTable(dt);
			return dt;
		}
		else
			return false;
	},
	
	// Compare two rows.
	compare: function(rowOne, rowTwo, sort) {
		sort = sort || this;
		// Can we compare these values?
		if (rowOne[sort.column].value != rowTwo[sort.column].value)
			return sort.ascending 
				? rowOne[sort.column].value < rowTwo[sort.column].value ? -1 : 1
				: rowOne[sort.column].value > rowTwo[sort.column].value ? -1 : 1;
		// No, solve the dispute by sorting by the base column (ascending).
		else if (rowOne[sort.base].value == rowTwo[sort.base].value)
			return 0;
		else
			return rowOne[sort.base].value < rowTwo[sort.base].value ? -1 : 1;
	},
	
	// Set a filter for a specified column.
	filter: function(filterLink) {
		// Filtered from the GUI.
		var column = filterLink.parentNode.parentNode.parentNode;
		var datatable = column.parentNode.parentNode.parentNode;
		var dataset = DataTable.datasets[datatable.id];
		if (/col_([A-Za-z0-9]+)/.test(column.className))
		{
			// Extract data from source link.
			var match = column.className.match(/col_([A-Za-z0-9]+)/);
			var ref = match[1];
			var value = /all/i.test(filterLink.parentNode.className) ? true : filterLink.innerHTML;
			// Check for corresponding column.
			for (var i = 0; i < dataset.columns.length; i++)
			{
				if (ref == dataset.columns[i].ref && dataset.columns[i].filter)
				{
					dataset.columns[i].filter = value;
					DataTable.updateTable(datatable);
					break;
				}
			}
		}
	},
	
	// Programmatically change the sorting and filters.
	//	datatable   TABLE element
	//	sort        { column: 'name', ascending: true } || null
	//	filters     [
	//	              { column: 'name', value: 'filter_value' },
	//	              { column: 'name', value: 'filter_value' },
	//	              { column: 'name', value: 'filter_value' }
	//	            ] || null
	view: function(datatable, sort, filters) {
		// Validate datatable.
		if (datatable && DataTable.datasets[datatable.id])
		{
			var dataset = DataTable.datasets[datatable.id];
			// Apply sorting.
			if (sort) {
				dataset.sort.column = sort.column;
				dataset.sort.ascending = sort.ascending;
			}
			// Adjust filtering.
			if (filters) {
				// Ensure there are no blank string filters.
				for (var i = 0; i < filters.length; i++) {
					filters[i].value = filters[i].value || true;
				}
				var findFilter = function(ref) {
					for (var i = 0; i < this.length; i++) {
						if (this[i].column == ref)
							return i;
					}
					return -1;
				};
				// Apply filters.
				var hCells = datatable.getElementsByTagName('thead')[0].getElementsByTagName('th');
				for (var i = 0; i < dataset.columns.length; i++)
				{
					var idx = findFilter.call(filters, dataset.columns[i].ref);
					if (idx > -1 && dataset.columns[i].filter) {
						dataset.columns[i].filter = filters[idx].value;
						// Show column as filtered/unfiltered.
						for (var j = 0; j < hCells.length; j++) {
							if (hCells[j].className.indexOf('col_' + dataset.columns[i].ref) > -1) {
								hCells[j].className = hCells[j].className.replace(/\s*filter/, '');
								if (typeof dataset.columns[i].filter == 'string')
									hCells[j].className += " filter";
							}
						}
					}
				}
			}
			if (sort || filters) {
				// Update the table display.
				DataTable.updateTable(datatable);
			}
		}
	},
	
	// Render the rows for a datatable.
	updateTable: function(datatable, sort) {
		// Validate datatable.
		if (datatable && DataTable.datasets[datatable.id])
		{
			var dataset = DataTable.datasets[datatable.id];
			// Update sort.
			//~ console.time("BLOCK update sort");
			sort = sort || false;
			if (typeof sort == 'object' && typeof sort.column == 'string' && typeof sort.ascending == 'boolean')
			{
				// Validate sorting direction.
				for (var i = 0; i < dataset.columns.length; i++)
				{
					// Datatable is valid.
					if (dataset.columns[i].sort && dataset.columns[i].ref == sort.column)
					{
						dataset.sort.column = sort.column;
						dataset.sort.ascending = sort.ascending;
						break;
					}
				}
			}
			//~ console.timeEnd("BLOCK update sort");
			
			// Clean out old rows.
			//~ console.time("BLOCK cleaning");
			// Unload the EventContainer if it exists.
			if (typeof datatable.container != 'undefined')
				datatable.container.unload();
			var header = datatable.header || false;
			var filtersRow = datatable.filtersRow || false;
			var selectedId = datatable.selectedId || false;
			if (filtersRow) {
				var ul = DataTable.findElements('ul', filtersRow);
				for (var j = 0; j < ul.length; j++) {
					if (ul[j].container) {
						ul[j].container.unload();
						ul[j].container = null;
					}
					DataTable.removeAllEvents(ul[j]);
				}
			}
			// Find table body.
			if (header && header.parentNode && header.parentNode.parentNode)
			{
				var tbody = header.parentNode.parentNode.getElementsByTagName("TBODY");
				tbody = tbody.length > 0 ? tbody[0] : false;
			}
			//~ console.timeEnd("BLOCK cleaning");
			// Continue.
			if (tbody)
			{
				//~ console.time("BLOCK tbody");
				// Clone the TBODY.
				var original_tbody = tbody;
				if (document.all) {
					var tmp_div = DataTable.findElements('div', original_tbody);
					for (var i = 0; i < tmp_div.length; i++)
						DataTable.removeAllEvents(tmp_div[i]);
				}
				else
					DataTable.removeAllEvents(original_tbody);
				tbody = tbody.cloneNode(false);
				var realtbody = tbody;
				// Add scrollable body for IE.
				if (document.all && dataset.style.scrollable)
				{
					// Generate child scrolling table.
					var containerRow = DataTable.createElement('tr');
					var containerCell = DataTable.createElement('td', { 'className': 'container', 'colSpan': dataset.columns.length });
					var containerDiv = DataTable.createElement('div');
					var containerTable = DataTable.createElement('table', { 'cellSpacing': 0, 'cellPadding': 0 });
					tbody.appendChild(containerRow);
					containerRow.appendChild(containerCell);
					containerCell.appendChild(containerDiv);
					containerDiv.appendChild(containerTable);
					// Append "new" TBODY.
					tbody = DataTable.createElement('tbody');
					containerTable.appendChild(tbody);
				}
				// Reset TBODY height.
				if (!document.all)
					tbody.style.height = "auto";
				
				// Update header and grab column indices.
				var hcells = header.getElementsByTagName("TH");
				var startIndex = -1;
				for (var i = 0; i < hcells.length; i++)
				{
					if (/col_[A-Za-z0-9]+/.test(hcells[i].className))
					{
						if (startIndex < 0)
							startIndex = i;
						var column = dataset.columns[i - startIndex];
						var p = hcells[i].getElementsByTagName("P")[0];
						if (/string/i.test(typeof p.sortColumn))
						{
							// Continue with the column.
							if (column && column.sort)
							{
								// Update events.
								p.sortAscending = true;
								if (column.ref == dataset.sort.column && dataset.sort.ascending)
									p.sortAscending = false;
								// Update sorting visual style.
								if (column.ref == dataset.sort.column)
								{
									if (/ascending|descending/.test(p.className))
									{
										if (dataset.sort.ascending)
											p.className = p.className.replace(/ascending|descending/, "ascending");
										else
											p.className = p.className.replace(/ascending|descending/, "descending");
									}
									else
									{
										if (dataset.sort.ascending)
											p.className += " ascending";
										else
											p.className += " descending";
									}
								}
								else
									p.className = p.className.replace(/ascending|descending/, "");
							}
						}
					}
				}
				//~ console.timeEnd("BLOCK tbody");
				
				// Generate dataview.
				//~ console.time("BLOCK dataview");
				var dataview = new Array();
				for (var i = 0; i < dataset.data.length; i++)
				{
					// Grab datarow.
					var datarow = dataset.data[i];
					var newrow = { index: i };
					// Add the data.
					for (var j = 0; j < dataset.columns.length; j++)
					{
						var column = dataset.columns[j];
						var text = datarow[column.ref].text;
						var value = datarow[column.ref].value;
						if (/function/i.test(typeof text))
							text = text.call(datarow, value);
						newrow[column.ref] = { text: text, value: value };
					}
					dataview.push(newrow);
				}
				// Filter the dataview.
				for (var i = (dataview.length - 1); i > -1; i--)
				{
					// Grab datarow.
					var datarow = dataset.data[i];
					var rowmatch = true;
					// Match the data.
					for (var j = 0; j < dataset.columns.length; j++)
					{
						var column = dataset.columns[j];
						if (/string/i.test(typeof column.filter))
							rowmatch = (rowmatch && datarow[column.ref].text.indexOf(column.filter) > -1);
					}
					if (!rowmatch)
						dataview.splice(i, 1);
				}
				// Sort the dataview.
				dataview.sort(DataTable.compare.bind(dataset.sort));
				for (var i = 0; i < dataview.length; i++) {
					dataview[i].value = null;
					delete dataview[i].value;
				}
				//~ console.timeEnd("BLOCK dataview");
				
				// Generate rows.
				//~ console.time("BLOCK generate");
				var _genRow = function(base, params, clone) {
					base = base || false;
					params = params || false;
					clone = clone || false;
					if (!base) {
						// Create row element.
						var row = DataTable.createElement('tr');
						// Are there extra cells in the table? (i.e. selection cells)
						for (var j = 0; j < startIndex; j++)
						{
							var cell = DataTable.createElement('td', { 'className': hcells[j].className, 'innerHTML': hcells[j].innerHTML });
							row.appendChild(cell);
						}
						// Add the cells.
						for (var j = 0; j < dataset.columns.length; j++)
						{
							var column = dataset.columns[j];
							var cell = DataTable.createElement('td', { 'className': 'col_' + column.ref, 'innerHTML': '<p></p>' });
							row.appendChild(cell);
							if (document.all && dataset.style.scrollable)
								cell.style.width = column.width;
						}
						return row;
					} else if (base && params) {
						var row = clone ? base.cloneNode(true) : base;
						row.className = params.zebra ? "zebra" : "";
						row.className += " idx_" + params.index;
						// Add selected class if row was previously 
						if (selectedId && selectedId == params.index)
							row.className += " selected";
						return row;
					}
				};
				var zebra = false;
				var fragment = document.createDocumentFragment();
				var base = _genRow();
				for (var i = 0; i < dataview.length; i++)
				{
					// Grab datarow.
					var datarow = dataview[i];
					// Generate row.
					var row = _genRow(base, { index: datarow.index, zebra: zebra }, true);
					for (var j = 0; j < dataset.columns.length; j++)
					{
						// Add the data.
						DataTable.alterElement(DataTable.findElements('p', DataTable.findElements('td', row)[j + startIndex])[0], {
							'innerHTML': datarow[dataset.columns[j].ref].text
						});
					}
					fragment.appendChild(row);
					zebra = zebra ? false : true;
				}
				tbody.appendChild(fragment);
				//~ console.timeEnd("BLOCK generate");
				
				//~ console.time("BLOCK replacing");
				original_tbody.parentNode.appendChild(document.all ? realtbody : tbody);
				DataTable.destroyNode(original_tbody);
				datatable.scrollArea = document.all ? containerDiv : tbody;
				//~ console.timeEnd("BLOCK replacing");
				
				// Add filter drop-downs.
				//~ console.time("BLOCK filters");
				var footer = DataTable.createElement('tr', { 'className': 'filters' });
				if (document.all && dataset.style.scrollable)
					realtbody.appendChild(footer);
				else
					tbody.appendChild(footer);
				// Are there extra cells in the table? (i.e. selection cells)
				var footerfrag = document.createDocumentFragment();
				for (var j = 0; j < startIndex; j++)
				{
					var cell = document.createElement("TD");
					footerfrag.appendChild(cell);
				}
				// Define event handlers.
				var ulMouseOver = function(){
					var idx = this.parentNode.cellIndex;
					var hcell = DataTable.findElements("th", this.parentNode.parentNode.parentNode.parentNode);
					if (hcell.length > idx)
						hcell[idx].className += " over";
				};
				var ulMouseOut = function(){
					var idx = this.parentNode.cellIndex;
					var hcell = DataTable.findElements("th", this.parentNode.parentNode.parentNode.parentNode);
					if (hcell.length > idx)
						hcell[idx].className = hcell[idx].className.replace(/\s*over/ig, "");
				};
				// Add the filter lists.
				for (var j = 0; j < dataset.columns.length; j++)
				{
					var column = dataset.columns[j];
					var cell = DataTable.createElement('td', { 'className': 'col_' + column.ref });
					footerfrag.appendChild(cell);
					if (column.filter)
					{
						// Add filters.
						var ul = document.createElement("ul");
						var all_li = DataTable.createElement('li', { 'className': 'all' });
						if (/boolean/i.test(typeof column.filter) && column.filter)
							all_li.className += " active";
						ul.appendChild(all_li);
						var all_link = DataTable.createElement('a', { 'innerHTML': '(All)' });
						all_li.appendChild(all_link);
						var zebra = true;
						var data_values = new Array();
						for (var i = 0; i < dataview.length; i++)
						{
							// Grab data and verify that it is unique.
							var data = dataview[i][dataset.columns[j].ref].text;
							var dupe = false;
							for (var k = 0; k < data_values.length; k++)
							{
								if (data_values[k] == data)
									dupe = true;
							}
							if (!dupe)
								data_values.push(data);
						}
						data_values.sort();
						for (var i = 0; i < data_values.length; i++)
						{
							var li = document.createElement("LI");
							if (zebra)
								li.className = "zebra";
							if (/string/i.test(typeof column.filter) && column.filter == data_values[i])
								li.className += " active";
							ul.appendChild(li);
							var link = DataTable.createElement('a', { 'innerHTML': data_values[i] });
							li.appendChild(link);
							zebra = zebra ? false : true;
						}
						data_values = null;
						// Adjust filters position.
						cell.appendChild(ul);
						// Add events to forward to header.
						Event.observe(ul, "mouseover", ulMouseOver.bindAsEventListener(ul));
						Event.observe(ul, "mouseout", ulMouseOut.bindAsEventListener(ul));
						ul.container = new DataTable.EventContainer(ul);
						ul.container.addWatchers(DataTable.findElements('a', ul));
						ul.container.addHandlers({
							'mouseover': function() { this.className += " over"; },
							'mouseout': function() { this.className = this.className.replace(/\s*over/ig, ""); },
							'click': function() {
								// Reset header.
								var idx = this.parentNode.parentNode.parentNode.cellIndex;
								var hcell = DataTable.findElements('th', this.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode);
								if (hcell.length > idx)
								{
									hcell[idx].className = hcell[idx].className.replace(/\s*over/ig, "");
									if (/all/i.test(this.parentNode.className))
										hcell[idx].className = hcell[idx].className.replace(/\s*filter/ig, "");
									else if (!/filter/i.test(hcell[idx].className))
										hcell[idx].className += " filter";
								}
								// Run filter.
								DataTable.filter(this);
							}
						});
					}
				}
				footer.appendChild(footerfrag);
				datatable.filtersRow = footer;
				var lists = DataTable.findElements('ul', footer);
				for (var i = 0; i < lists.length; i++)
				{
					lists[i].style.display = "none";
					lists[i].style.marginTop = (-1 * (datatable.offsetHeight - header.offsetHeight 
						+ footer.parentNode.scrollHeight - footer.parentNode.offsetHeight 
						- footer.parentNode.scrollTop) + 1) + "px";
				}
				// Fix filter drop-down lists when the table is scrolled in Mozilla.
				if (!document.all)
				{
					Event.observe(tbody, 'scroll', function(){
						// Grab base table elements.
						var datatable = this.parentNode;
						var header = datatable.getElementsByTagName("THEAD");
						header = header.length > 0 ? header[0] : false;
						if (header)
						{
							header = header.getElementsByTagName("TR");
							header = header.length > 0 ? header[0] : false;
						}
						var footer = this.getElementsByTagName("TR");
						footer = footer.length > 0 ? footer[footer.length-1] : false;
						// Update drop-down list styles.
						var ul = this.getElementsByTagName("UL");
						for (var i = 0; i < ul.length; i++)
						{
							ul[i].style.display = "none";
							ul[i].style.marginTop = (-1 * (datatable.offsetHeight - header.offsetHeight 
								+ footer.parentNode.scrollHeight - footer.parentNode.offsetHeight 
								- footer.parentNode.scrollTop) + 1) + "px";
						}
					}.bindAsEventListener(tbody));
				}
				else
				{
					Event.observe(containerDiv, 'scroll', function(){
						var tr = this.getElementsByTagName("TR");
						if (tr.length > 0) {
							var header = tr[0];
							var footer = tr[tr.length-1];
							// Update drop-down list styles.
							var ul = this.getElementsByTagName("UL");
							for (var i = 0; i < ul.length; i++)
							{
								ul[i].style.display = "none";
								ul[i].style.marginTop = (-1 * (this.parentNode.offsetHeight - header.offsetHeight 
									+ footer.parentNode.scrollHeight - footer.parentNode.offsetHeight 
									- footer.parentNode.scrollTop) + 1) + "px";
							}
						}
					}.bindAsEventListener(realtbody));
				}
				// Clean up the dataview object because we're done with it.
				dataview = null;
				//~ console.timeEnd("BLOCK filters");
				
				// Add row functionality.
				//~ console.time("BLOCK row functionality");
				datatable.container = new DataTable.EventContainer(document.all ? containerDiv : tbody, (document.all ? 1 : 0), (document.all ? 1 : 0));
				var tr = DataTable.findElements('tr', document.all ? containerDiv : tbody);
				if (!document.all) tr.pop();
				datatable.container.addWatchers(tr);
				var events = {
					'mouseover': function() { this.className += " over"; },
					'mouseout': function() { this.className = this.className.replace(/\s*over/ig, ""); },
					'click': function() {
						var dt = document.all ? this.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode : this.parentNode.parentNode;
						if (dt.selected && dt.selected != this) {
							dt.selected.className = dt.selected.className.replace(/\s*selected/ig, "");
							this.className = this.className.replace(/\s*over/ig, "");
							this.className += " selected";
							dt.selected = this;
							dt.selectedId = false;
							var index = this.className.match(/idx_(\d+)/i);
							index = index ? parseInt(index[1], 10) : -1;
							if (/selected/i.test(this.className))
								dt.selectedId = index;
						}
					}
				};
				// Apply custom events.
				for (var j in dataset.events)
				{
					var _handler = events[j];
					var _custom = dataset.events[j];
					events[j] = function() {
						_handler.apply(this, arguments);
						_custom.apply(this, arguments);
					};
				}
				datatable.container.addHandlers(events);
				//~ console.timeEnd("BLOCK row functionality");
				
				// Fix table body height if the table is scrollable.
				//~ console.time("BLOCK scrolling");
				if (dataset.style.scrollable)
				{
					if (!document.all && datatable.offsetHeight > dataset.style.maxHeight)
						tbody.style.height = (dataset.style.maxHeight - header.offsetHeight - 2) + "px";
					else if (document.all && datatable.offsetHeight > dataset.style.maxHeight)
						tbody.parentNode.parentNode.style.height = (dataset.style.maxHeight - header.offsetHeight - 2) + "px";
				}
				// Fix filter list offset for IE when the table is scrollable.
				if (document.all && dataset.style.scrollable)
				{
					var ul = DataTable.findElements('ul', footer);
					var container = DataTable.findElements('table', footer.parentNode);
					container = container.length > 0 ? container[0].parentNode : false;
					if (container)
					{
						for (var i = 0; i < ul.length; i++)
							ul[i].style.marginTop = (-1 * (container.offsetHeight) - 1) + "px";
					}
				}
				//~ console.timeEnd("BLOCK scrolling");
				
				// Clean up and adjust table.
				//~ console.time("BLOCK adjust");
				DataTable.adjust(datatable);
				//~ console.timeEnd("BLOCK adjust");
				
				// Clean up.
				datatable = null;
				header = null;
				tbody = null;
				realtbody = null;
				original_tbody = null;
			}
		}
	},
	
	// Retrieve data for a given datarow.
	getData: function(tr) {
		var idx = tr.className.match(/idx_(\d+)/i);
		idx = idx && idx.length > 0 ? idx[1] : false;
		if (idx)
		{
			var datatable = tr.parentNode.parentNode;
			if (document.all && !/datatable/i.test(datatable.className))
				datatable = datatable.parentNode.parentNode.parentNode.parentNode.parentNode;
			var dataset = DataTable.datasets[datatable.id];
			if (dataset && dataset.data && dataset.data[idx])
				return dataset.data[idx];
			else
				return false;
		}
		else
			return false;
	},
	
	// Add data from another dataset to the current dataset.
	addData: function(datatable, dataset, scrollToBottom) {
		// Validate datatable.
		if (datatable && DataTable.datasets[datatable.id]) {
			for (var i = 0; i < dataset.length; i++) {
				DataTable.datasets[datatable.id].data.push(dataset[i]);
			}
			DataTable.updateTable(datatable);
			if (scrollToBottom && datatable.scrollArea)
				datatable.scrollArea.scrollTop = datatable.scrollArea.scrollHeight;
		}
	},
	
	// Debug datarow values.
	debugData: function(datarow) {
		if (/object/i.test(typeof datarow))
		{
			var datastr = new Array();
			for (var i in datarow)
			{
				datastr.push(i + ": ");
				for (var j in datarow[i])
					datastr.push(j + "=\"" + datarow[i][j] + "\",");
				datastr.push("\n");
			}
			return datastr.join("");
		}
		else
			return false;
	},
	
	// Hide filter drop-down list when user clicks outside of it.
	mouseUp: function() {
		// Require a delay before resetting filter drop-down lists.
		//	(required to keep drop-down toggle button working)
		setTimeout("DataTable.execMouseUp()", 5);
	},
	execMouseUp: function() {
		// Grab all tables.
		var tables = document.getElementsByTagName("TABLE");
		for (var i = 0; i < tables.length; i++)
		{
			// Process only datatables.
			if (/datatable/i.test(tables[i].className))
			{
				// Grab filter row.
				var rows = tables[i].getElementsByTagName("TR");
				for (var j = 0; j < rows.length; j++)
				{
					if (/filters/i.test(rows[j].className))
					{
						// Hide filter drop-down list.
						var ul = rows[j].getElementsByTagName("UL");
						for (var k = 0; k < ul.length; k++)
							ul[k].style.display = "none";
					}
				}
			}
		}
	},
	
	// Remove an event from an element.
	removeEvent: function(element, name, observer, useCapture) {
		for (var i = (Event.observers.length - 1); i >= 0; i--)
		{
			useCapture = useCapture || false;
			if (Event.observers[i][0] == element && Event.observers[i][1] == name 
			&& Event.observers[i][2].toString() == observer.toString() && Event.observers[i][3] == useCapture)
			{
				// Stop observing the event and remove it from the cache.
				Event.stopObserving(Event.observers[i][0], Event.observers[i][1], Event.observers[i][2], Event.observers[i][3]);
				Event.observers[i][0] = null;
				Event.observers.splice(i, 1);
			}
		}
	},
	
	// Remove all events from an element.
	removeAllEvents: function(element) {
		for (var i = (Event.observers.length - 1); i >= 0; i--)
		{
			if (Event.observers[i][0] == element)
			{
				// Stop observing the event and remove it from the cache.
				Event.stopObserving(Event.observers[i][0], Event.observers[i][1], Event.observers[i][2], Event.observers[i][3]);
				Event.observers[i][0] = null;
				Event.observers.splice(i, 1);
			}
		}
	},
	
	// Get computed style for an element.
	style: function(e, attr) {
		// Validate element.
		e = $(e);
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
	
	// Fix memory leaks on unload.
	unload: function() {
		try {
			for (var i = 0; i < DataTable.datatables.length; i++) {
				var datatable = DataTable.datatables[i];
				// Unload the EventContainer if it exists.
				if (typeof datatable.container != 'undefined')
					datatable.container.unload();
				var rows = DataTable.findElements('tr', datatable);
				var header = datatable.header || false;
				var filtersRow = datatable.filtersRow || false;
				var selectedId = datatable.selectedId || false;
				if (filtersRow) {
					var ul = DataTable.findElements('ul', filtersRow);
					for (var j = 0; j < ul.length; j++) {
						if (ul[j].container) {
							ul[j].container.unload();
							ul[j].container = null;
						}
						DataTable.removeAllEvents(ul[j]);
					}
				}
				// Remove circular references.
				datatable.header = null;
				datatable.filtersRow = null;
				datatable.selectedId = null;
				datatable.scrollArea = null;
				datatable.container = null;
			}
			DataTable.datatables = null;
		} catch (e) {};
	},
	
	// DOM traversal methods. These are written to speed up DOM queries.
	findElements: function(tag, parent) {
		// Generate non-live node array.
		parent = parent || document;
		var elements = [];
		var allTag = parent.getElementsByTagName(tag);
		for (var i = 0; i < allTag.length; i++) {
			elements.push(allTag[i]);
		}
		return elements;
	},
	createElement: function(el, attributes) {
		var element = (typeof el == 'string') ? document.createElement(el) : el.cloneNode(true);
		return DataTable.alterElement(element, attributes);
	},
	alterElement: function(el, attributes) {
		for (var attr in attributes)
			el[attr] = attributes[attr];
		return el;
	},
	destroyNode: function(node, deep) {
		deep = deep || false;
		if (deep) {
			while (node.childNodes.length > 0)
				DataTable.destroyNode(node.childNodes[0], true);
		}
		dojo.dom.destroyNode(node);
	}
}

//*** BEGIN Prototype 1.4.0 SUBSET ***//
Object.extend = function(destination, source) {
  for (property in source) {
    destination[property] = source[property];
  }
  return destination;
}
Function.prototype.bind = function() {
  var __method = this, args = $A(arguments), object = args.shift();
  return function() {
    return __method.apply(object, args.concat($A(arguments)));
  }
}
Function.prototype.bindAsEventListener = function(object) {
  var __method = this;
  return function(event) {
    return __method.call(object, event || window.event);
  }
}
var Event = new Object();
Object.extend(Event, {
	KEY_BACKSPACE: 8,
	KEY_TAB:       9,
	KEY_RETURN:   13,
	KEY_ESC:      27,
	KEY_LEFT:     37,
	KEY_UP:       38,
	KEY_RIGHT:    39,
	KEY_DOWN:     40,
	KEY_DELETE:   46,
	element: function(event) {
		return event.target || event.srcElement;
	},
	isLeftClick: function(event) {
		return (((event.which) && (event.which == 1)) ||
						((event.button) && (event.button == 1)));
	},
	pointerX: function(event) {
		return event.pageX || (event.clientX +
			(document.documentElement.scrollLeft || document.body.scrollLeft));
	},
	pointerY: function(event) {
		return event.pageY || (event.clientY +
			(document.documentElement.scrollTop || document.body.scrollTop));
	},
	stop: function(event) {
		if (event.preventDefault) {
			event.preventDefault();
			event.stopPropagation();
		} else {
			event.returnValue = false;
			event.cancelBubble = true;
		}
	},
	findElement: function(event, tagName) {
		var element = Event.element(event);
		while (element.parentNode && (!element.tagName ||
				(element.tagName.toUpperCase() != tagName.toUpperCase())))
			element = element.parentNode;
		return element;
	},
	observers: false,
	unloaders: false,
	_observeAndCache: function(element, name, observer, useCapture) {
		if (!this.observers) this.observers = [];
		if (!this.unloaders) this.unloaders = [];
		if (name != 'unload') {
			if (element.addEventListener) {
				this.observers.push([element, name, observer, useCapture]);
				element.addEventListener(name, observer, useCapture);
			} else if (element.attachEvent) {
				this.observers.push([element, name, observer, useCapture]);
				element.attachEvent('on' + name, observer);
			}
		} else {
			if (element.addEventListener) {
				this.unloaders.push([element, name, observer, useCapture]);
				element.addEventListener(name, observer, useCapture);
			} else if (element.attachEvent) {
				this.unloaders.push([element, name, observer, useCapture]);
				element.attachEvent('on' + name, observer);
			}
		}
	},
	unloadCache: function() {
		if (Event.observers) {
			for (var i = 0; i < Event.observers.length; i++) {
				Event.stopObserving.apply(this, Event.observers[i]);
				Event.observers[i][0] = null;
			}
			Event.observers = false;
		}
		if (Event.unloaders) {
			for (var i = 0; i < Event.unloaders.length; i++) {
				Event.unloaders[i][2]();
				Event.stopObserving.apply(this, Event.unloaders[i]);
				Event.unloaders[i][0] = null;
			}
			Event.unloaders = false;
		}
	},
	observe: function(element, name, observer, useCapture) {
		var element = $(element);
		useCapture = useCapture || false;
		if (name == 'keypress' &&
				(navigator.appVersion.match(/Konqueror|Safari|KHTML/)
				|| element.attachEvent))
			name = 'keydown';
		this._observeAndCache(element, name, observer, useCapture);
	},
	stopObserving: function(element, name, observer, useCapture) {
		var element = $(element);
		useCapture = useCapture || false;
		if (name == 'keypress' &&
				(navigator.appVersion.match(/Konqueror|Safari|KHTML/)
				|| element.detachEvent))
			name = 'keydown';
		if (element.removeEventListener) {
			element.removeEventListener(name, observer, useCapture);
		} else if (element.detachEvent) {
			element.detachEvent('on' + name, observer);
		}
	}
});
/* prevent memory leaks in IE */
Event.observe(window, 'load', function() {
	if (typeof window.onunload == 'function') {
		Event.observe(window, 'unload', window.onunload);
	}
	window.onunload = Event.unloadCache;
});
function $() {
  var elements = new Array();
  for (var i = 0; i < arguments.length; i++) {
    var element = arguments[i];
    if (typeof element == 'string')
      element = document.getElementById(element);
    if (arguments.length == 1)
      return element;
    elements.push(element);
  }
  return elements;
}
var $A = Array.from = function(iterable) {
  if (!iterable) return [];
  if (iterable.toArray) {
    return iterable.toArray();
  } else {
    var results = [];
    for (var i = 0; i < iterable.length; i++)
      results.push(iterable[i]);
    return results;
  }
}
//*** END Prototype 1.4.0 SUBSET ***//

//*** BEGIN Dojo Toolkit SUBSET ***//
if(typeof dojo == "undefined")
	var dojo = {};
dojo.render = {
	html: {
		ie: document.all && !(navigator.userAgent.indexOf("Opera") >= 0)
	}
};
dojo._ie_clobber = new function(){
	this.clobberNodes = [];
	function nukeProp(node, prop){
		try{ node[prop] = null; 			}catch(e){ /* squelch */ }
		try{ delete node[prop]; 			}catch(e){ /* squelch */ }
		try{ node.removeAttribute(prop);	}catch(e){ /* squelch */ }
	}
	this.clobber = function(nodeRef){
		var na;
		var tna;
		if(nodeRef){
			tna = nodeRef.all || nodeRef.getElementsByTagName("*");
			na = [nodeRef];
			for(var x=0; x<tna.length; x++){
				if(tna[x]["__doClobber__"]){
					na.push(tna[x]);
				}
			}
		}else{
			try{ window.onload = null; }catch(e){}
			na = (this.clobberNodes.length) ? this.clobberNodes : document.all;
		}
		tna = null;
		var basis = {};
		for(var i = na.length-1; i>=0; i=i-1){
			var el = na[i];
			try{
				if(el && el["__clobberAttrs__"]){
					for(var j=0; j<el.__clobberAttrs__.length; j++){
						nukeProp(el, el.__clobberAttrs__[j]);
					}
					nukeProp(el, "__clobberAttrs__");
					nukeProp(el, "__doClobber__");
				}
			}catch(e){ /* squelch! */};
		}
		na = null;
	}
}
if(dojo.render.html.ie){
	Event.observe(window, 'unload', (function(){
		dojo._ie_clobber.clobber();
		dojo._ie_clobber.clobberNodes = [];
		// CollectGarbage();
	}));
}
dojo.event = {};
dojo.event.browser = new function(){
	var clobberIdx = 0;
	
	this.clean = function(/*DOMNode*/node){
		if(dojo.render.html.ie){ 
			dojo._ie_clobber.clobber(node);
		}
	}
}
dojo.dom = {};
dojo.dom.replaceNode = function(/*Element*/node, /*Element*/newNode){
	return node.parentNode.replaceChild(newNode, node); // Node
}
dojo.dom.destroyNode = function(/*Node*/node){
	if(node.parentNode){
		node = dojo.dom.removeNode(node);
	}
	if(node.nodeType != 3){ // ingore TEXT_NODE
		//if(dojo.evalObjPath("dojo.event.browser.clean", false)){
			dojo.event.browser.clean(node); // We know that this method is available.
		//}
		if(dojo.render.html.ie){
			node.outerHTML=''; //prevent ugly IE mem leak associated with Node.removeChild (ticket #1727)
		}
	}
}
dojo.dom.removeNode = function(/*Node*/node){
	if(node && node.parentNode){
		// return a ref to the removed child
		return node.parentNode.removeChild(node); //Node
	}
}
//*** END Dojo Toolkit SUBSET ***//

// EventContainer
//  Listens to specific events and passes onto watchers to decrease number of listeners.
//  Currently supports: click, mouseover, mouseout.
//  Usage:
//		var container = new DataTable.EventContainer('container');
//		container.addWatchers(document.getElementsByTagName('p'));
//		container.addHandlers({
//			'click': function(e) {
//				container.watchers.each(function(el) {
//					el.style.backgroundColor = 'transparent';
//				});
//				this.style.backgroundColor = '#CCCCCC';
//			},
//			'mouseover': function(e) { this.style.color = '#00CC00'; },
//			'mouseout': function(e) { this.style.color = '#000000'; }
//		});
DataTable.EventContainer = function(el, options) {
	this.element = $(el);
	options = options || {};
	this.bubble = options.bubble || false;
	this.handlers = {};
	this.hovered = [];
	if (typeof this.hovered.indexOf != 'function') {
		this.hovered.indexOf = function(obj) {
			for (var i = 0; i < this.length; i++) {
				if (this[i] == obj)
					return i;
			}
			return -1;
		};
	}
	var _self = this;
	this.watchers = [];
	this.watchers.each = function(fn) {
		for (var i = 0; i < this.length; i++)
			fn.call(_self, this[i]);
	};
	this.offset = {
		x: (document.all ? 2 : 0),
		y: (document.all ? 2 : 0)
	};
	if (typeof options.x == 'number') this.offset.x += options.x;
	if (typeof options.y == 'number') this.offset.y += options.y;
	// Add event listeners.
	Event.observe(this.element, 'click', this.mouseEvent.bindAsEventListener(this));
	Event.observe(this.element, 'mousemove', this.mouseEvent.bindAsEventListener(this));
	Event.observe(this.element, 'mouseout', this.mouseEvent.bindAsEventListener(this));
	Event.observe(window, 'unload', function() { if (this) this.unload(); }.bindAsEventListener(this));
};
// Add functionality to EventContainer.
Object.extend(DataTable.EventContainer.prototype, {
	// Binary search to determine element which is under the mouse coordinates.
	find: function(arr, value, min, max) {
		min = typeof min == 'undefined' ? 0 : min;
		max = typeof max == 'undefined' ? arr.length - 1 : max;
		if (max < min)
			return false;
		var mid = Math.floor((min + max) / 2);
		var cpos = this.pos(arr[mid]);
		if (value.y > cpos.bottom)
			return this.find(arr, value, mid + 1, max);
		else if (value.y < cpos.top)
			return this.find(arr, value, min, mid - 1);
		else
			return arr[mid];
	},
	// Determine absolute position of an element.
	pos: function(el) {
		var pos = { left: 0, top: 0, right: el.offsetWidth - 1, bottom: el.offsetHeight - 1 };
		do {
			pos.left += el.offsetLeft || 0;
			pos.top += el.offsetTop || 0;
			el = el.offsetParent;
		} while (el);
		pos.right += pos.left;
		pos.bottom += pos.top;
		return pos;
	},
	// Adds event handlers. Accepts an object literal of functions.
	addHandlers: function(handlers) {
		for (var name in handlers)
			this.handlers[name.toLowerCase()] = handlers[name];
	},
	// Adds element watchers. Accepts an array of elements. The watchers must be vertically (y-coordinate) sorted.
	addWatchers: function(watchers) {
		for (var i = 0; i < watchers.length; i++)
			this.watchers.push(watchers[i]);
	},
	// Handles mouse events internally.
	mouseEvent: function(e) {
		if (!this.bubble)
			e.cancelBubble = true;
		var el = false;
		// Find mouse coordinates and underlying element if possible.
		if (e.type.match(/^(click|mousemove)$/)) {
			var mouse = { x: e.clientX - this.offset.x, y: e.clientY + this.element.scrollTop + document.documentElement.scrollTop - this.offset.y };
			el = this.find(this.watchers, mouse);
			if (el) {
				// Determine click.
				if (e.type == 'click' && typeof this.handlers['click'] == 'function') {
					var links = DataTable.findElements('a', el);
					var link_clicked = false;
					for (var i = 0; i < links.length; i++) {
						var link_pos = this.pos(links[i]);
						if (link_pos.left <= mouse.x && link_pos.right >= mouse.x 
						&& link_pos.top <= mouse.y && link_pos.bottom >= mouse.y) {
							link_clicked = true;
							break;
						}
					}
					if (!link_clicked)
						this.handlers['click'].apply(el, arguments);
				}
				// Determine mouseover.
				else if (e.type == 'mousemove' && typeof this.handlers['mouseover'] == 'function' && this.hovered.indexOf(el) == -1)
					this.handlers['mouseover'].apply(el, arguments);
			}
		}
		// Determine mouseout.
		if (typeof this.handlers['mouseout'] == 'function' && this.hovered.length && (this.hovered.indexOf(el) == -1 || e.type == 'mouseout')) {
			while (this.hovered.length > 0)
				this.handlers['mouseout'].apply(this.hovered.pop(), arguments);
		}
		// Update last processed element.
		if (e.type != 'mouseout' && el)
			this.hovered.push(el);
	},
	// Remove event listeners and watchers.
	unload: function() {
		this.element = null;
		this.hovered = [];
		this.watchers = [];
		this.watchers.each = function(fn) {
			for (var i = 0; i < this.length; i++)
				fn.call(_self, this[i]);
		};
		for (var i = (Event.observers.length - 1); i >= 0; i--)
		{
			var event = Event.observers[i];
			if (event[0] == this.element)
			{
				Event.stopObserving(event[0], event[1], event[2], event[3]);
				Event.observers.splice(i, 1);
			}
		}
	}
});

// Benchmarking (requires xfn.js).
//~ for (var prop in DataTable) {
	//~ if (typeof DataTable[prop] == 'function' && !/^(getData|mouseUp|execMouseUp|createElement|findElements|alterElement|EventContainer|compare|style|removeEvent|removeAllEvents)$/.test(prop)) {
		//~ (function(obj, objname, p) {
			//~ obj[p] = $xfn(obj[p]);
			//~ obj[p].pre.add(function() {
				//~ if (p == 'addData') console.profile();
				//~ console.time(objname + p);
				//~ console.info("STARTING ", objname + p);
				//~ return arguments;
			//~ });
			//~ obj[p].post.add(function(result) {
				//~ console.timeEnd(objname + p);
				//~ if (p == 'addData') console.profileEnd(objname + p);
				//~ return result;
			//~ });
			//~ return;
		//~ }(DataTable, "DataTable.", prop));
	//~ }
//~ }

// Set up window events.
Event.observe(window, "load", DataTable.doLoad);
Event.observe(window, "resize", DataTable.resize);
Event.observe(document, "mouseup", DataTable.mouseUp);
Event.observe(window, "unload", DataTable.unload, false);