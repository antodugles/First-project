<HTML><HEAD><TITLE>
Common Service Desktop Java ServerPage </TITLE>
<% if ( request.getAttribute( "jsInclude" ) != null ) { %>
	<LINK rel = "stylesheet" href = '<%=request.getAttribute( "jsInclude" )%>/ftie4style.css'>
	<SCRIPT SRC = '<%=request.getAttribute( "jsInclude" )%>/ftiens4.js'>

<% } else { %>
	<LINK rel = "stylesheet" href = "/csd/java/ftie4style.css">
	<SCRIPT SRC = "/csd/java/ftiens4.js">
	<% } %>

</SCRIPT>

<% if ( request.getAttribute( "jsfile" ) != null ) { %>
<SCRIPT SRC = '<%= request.getAttribute( "jsfile" )%>' > </SCRIPT> <% } %>
<SCRIPT>
initializeDocument()
</SCRIPT>

</HEAD><BODY bgcolor = "#888888" ></BODY></HTML>
