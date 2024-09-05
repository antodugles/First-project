// This JavaScript file contains functions that are used to add a status bar at the bottom of the page.
// Date Added: 09/07/06
// Written by: Jung Oh
  
var StatusBar = {	
	m_oStatusbar: false,
	m_bAnimateDots: false,
	m_bDisableRender: false,
	m_sQueueStatus: false,
	
	// Initialize the status bar only if an element called "statusbar" exists
	initStatusBar: function() {
		StatusBar.m_oStatusbar =  CSSpp.$("statusbar");
		if (StatusBar.m_oStatusbar)
		{
			// Add spacer at the bottom.
			var pre = document.createElement("PRE");
			pre.id = "statusbar_spacer";
			pre.style.height = StatusBar.m_oStatusbar.offsetHeight + "px";
			pre.style.margin = "0px";
			pre.style.padding = "0px";
			document.body.appendChild(pre);
			// Update the connection status
			StatusBar.updateConnectionStatus();
			StatusBar.positionStatusBar();
			// Add positionStatusBar() to events
			// CSSpp.addEvent(window, "resize", StatusBar.positionStatusBar);
			// CSSpp.addEvent(window, "scroll", StatusBar.positionStatusBar);
			setInterval(StatusBar.positionStatusBar, 25);
			// Render QueueStatus that was called before initializing
			if (StatusBar.m_sQueueStatus)
				StatusBar.updateQueueStatus(StatusBar.m_sQueueStatus);
		}
	},
	
	// Position the status bar at the bottom of the page
	positionStatusBar: function() {
		StatusBar.m_oStatusbar.style.top = document.documentElement.scrollTop + document.documentElement.clientHeight - StatusBar.m_oStatusbar.offsetHeight - StatusBar.m_oStatusbar.parentNode.offsetTop - 1 + "px";
	},
	
	// Update the connection status (left display)
	updateConnectionStatus: function() {
		if (StatusBar.m_oStatusbar && APICalls)
		{
			var status = APICalls.getConnectionStatus();
			var newInnerHTML = APICalls.getString("Connection") + ": <span class=\"";
			if (status == "Checked Out")
				newInnerHTML += "green";
			else
				newInnerHTML += "red";
			newInnerHTML += "\">" + APICalls.getString(status) + "<\/span>";
			
			CSSpp.$("connectionstatus").innerHTML = newInnerHTML;
			
			// Update again after 10 seconds
			window.setTimeout(StatusBar.updateConnectionStatus, 10000);
		}
	},
	
	// Update the Queue status (center display)
	updateQueueStatus: function(sQueueStatus) {
		if (StatusBar.m_oStatusbar)
			CSSpp.$("queuestatus").innerHTML = sQueueStatus;
		else
			StatusBar.m_sQueueStatus = sQueueStatus;  // To render later if initStatusBar() is not called yet
	},
	
	// Update the action status (right display)
	// If bAnimateDots is true, it will animate "..." to indicate progression.
	updateActionStatus: function(sActionStatus, bAnimateDots) {
		if (StatusBar.m_oStatusbar)
			CSSpp.$("actionstatus").innerHTML = sActionStatus;
			
		var bAnimateDotsOld = StatusBar.m_bAnimateDots;
		StatusBar.m_bAnimateDots = bAnimateDots || false;
		if (bAnimateDotsOld == false && StatusBar.m_bAnimateDots == true)  // Prevent from starting the animation again, resulting a faster rate than desired.
			StatusBar.animateActionStatus();
	},
	
	// Animate "..." to indicate progression until m_bAnimateDots is false
	animateActionStatus: function() {
		if (StatusBar.m_bAnimateDots)
		{
			var sTemp = CSSpp.$("actionstatus").innerHTML;
			// Parse the current innerHTML and update the dots
			var lastSpanIndex = sTemp.toLowerCase().lastIndexOf("<\/span>");
			var sLastSpan = "";
			if (lastSpanIndex != -1)
			{
				sLastSpan = sTemp.slice(lastSpanIndex);
				sTemp = sTemp.slice(0, lastSpanIndex);
			}
			
			var matchArray = sTemp.match(/(\.+$)/);
			var sDots = "";
			if (matchArray)
				sDots = matchArray[1];
			if (sDots.length < 3)
				sDots += ".";
			else
				sDots = ".";

			var sNewInnerHTML = sTemp.replace(/(\.+$)/, "") + sDots;
			sNewInnerHTML += sLastSpan;
			
			CSSpp.$("actionstatus").innerHTML = sNewInnerHTML;
				
			window.setTimeout(StatusBar.animateActionStatus, 500);
		}
	},
	
	// Hide the status bar
	hide: function() {
		if (StatusBar.m_oStatusbar)
		{
			StatusBar.m_oStatusbar.style.display = "none";
			CSSpp.$("statusbar_spacer").style.display = "none";
		}
	}
}

CSSpp.addEvent(window, "load", StatusBar.initStatusBar);
