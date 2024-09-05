//**************************************************************** 
// You are free to copy the "Folder-Tree" script as long as you  
// keep this copyright notice: 
// Script found in: http://www.geocities.com/Paris/LeftBank/2178/ 
// Author: Marcelino Alves Martins (martins@hks.com) December '97. 
//**************************************************************** 
 
//Log of changes: 
//       17 Feb 98 - Fix initialization flashing problem with Netscape
//       
//       27 Jan 98 - Root folder starts open; support for USETEXTLINKS; 
//                   make the ftien4 a js file 
//       
 
 
// Definition of class Folder 
// ***************************************************************** 
// CTCge91021 Begin
function popitup(url,parmFrameDim)
{
     //   newwindow=window.open(url,'name','height=700,width=700,screenX=200,screenY=100');
          // newwindow=window.open(url,'name','screenX=200,screenY=100');
          newwindow=window.open(url,'name',parmFrameDim);
	 if (window.focus) {newwindow.focus()}

        return false;
}
// CTCge91021 End

 
function Folder(folderDescription, hreference ) //constructor 
{ 
  //constant data 
  this.desc = folderDescription 
	if(aceInd == 0)
	{	rootHolder = this.desc; rootHolderObject = this; aceInd = 1; uidCtr++;	}
  this.hreference = hreference
  this.image_dir = csd_image_dir
  this.id = -1   
  this.navObj = 0  
  this.iconImg = ""  
  this.nodeImg = ""  
  this.isLastNode = 0 
  //dynamic data 
  this.isOpen = true 
  this.iconSrc = this.image_dir + "/ftv2folderopen.png"   
  this.children = new Array 
  this.nChildren = 0 
 
  //methods 
  this.initialize = initializeFolder 
  this.setState = setStateFolder 
  this.addChild = addChild 
  this.createIndex = createEntryIndex 
  this.hide = hideFolder 
  this.display = display 
  this.renderOb = drawFolder 
  this.totalHeight = totalHeight 
  this.subEntries = folderSubEntries 
  this.outputLink = outputFolderLink 
} 
 
function setStateFolder(isOpen) 
{ 
  var subEntries 
  var totalHeight 
  var fIt = 0 
  var i=0
 
  if (isOpen == this.isOpen) 
    return 
 
  if (browserVersion == 2)  
  { 
    totalHeight = 0 
    for (i=0; i < this.nChildren; i++) 
      totalHeight = totalHeight + this.children[i].navObj.clip.height 
      subEntries = this.subEntries() 
    if (this.isOpen) 
      totalHeight = 0 - totalHeight 
    for (fIt = this.id + subEntries + 1; fIt < nEntries; fIt++) 
      indexOfEntries[fIt].navObj.moveBy(0, totalHeight) 
  }  
  this.isOpen = isOpen 
  propagateChangesInState(this) 
} 
 
function propagateChangesInState(folder) 
{   
  var i=0 
  if (folder.isOpen) 
  {
    if (folder.nodeImg) 
      if (folder.isLastNode) 
        folder.nodeImg.src = folder.image_dir + "/ftv2mlastnode.png"
      else 
	  folder.nodeImg.src = folder.image_dir + "/ftv2mnode.png" 
    folder.iconImg.src = folder.image_dir +  "/ftv2folderopen.png" 
    for (i=0; i<folder.nChildren; i++) 
      folder.children[i].display() 
  } 
  else 
  {
    if (folder.nodeImg)
     { 
      if (folder.isLastNode)
        { 
        folder.nodeImg.src = folder.image_dir +  "/ftv2plastnode.png"
        } 
      else
          { 
	  folder.nodeImg.src = folder.image_dir +   "/ftv2pnode.png"
         }
      } 
    folder.iconImg.src = folder.image_dir +  "/ftv2folderclosed.png" 
    for (i=0; i<folder.nChildren; i++) 
      folder.children[i].hide() 
  }  
} 
 
function hideFolder() 
{ 
  if (browserVersion == 1) { 
    if (this.navObj.style.display == "none") 
      return 
    this.navObj.style.display = "none" 
  } else { 
    if (this.navObj.visibility == "hiden") 
      return 
    this.navObj.visibility = "hiden" 
  } 
   
  this.setState(0) 
} 
 
function initializeFolder(level, lastNode, leftSide) 
{ 
  var i=0 
  var nc 
      
  nc = this.nChildren 
   
  this.createIndex() 
 
  var auxEv = "" 
  var initLabel = "";
  if(!this.id==0) 
  {	initLabel = rootHolder + ".";	}
  initLabel = this.desc;

  if (browserVersion > 0) 
  {
    auxEv = "<a href='javascript:clickOnNode("+this.id+",\""+initLabel+"\")'>" 
  }
  else 
  {
    auxEv = "<a>" 
  }
 
  if (level>0) 
    if (lastNode) //the last 'brother' in the children array 
    { 
      this.renderOb(leftSide + auxEv + "<img name='nodeIcon" + this.id + "' src='" + this.image_dir + "ftv2mlastnode.png' width=16 height=22 border=0></a>") 
      leftSide = leftSide + "<img src='" + this.image_dir + "ftv2blank.png' width=16 height=22>"  
      this.isLastNode = 1 
    } 
    else 
    { 
      this.renderOb(leftSide + auxEv + "<img name='nodeIcon" + this.id + "' src='" + this.image_dir + "ftv2mnode.png' width=16 height=22 border=0></a>") 

      leftSide = leftSide + "<img src='" + this.image_dir + "ftv2vertline.png' width=16 height=22>" 
      this.isLastNode = 0 
    } 
  else 
  {
    this.renderOb("") 
  }
   
  if (nc > 0) 
  { 
    level = level + 1 
    for (i=0 ; i < this.nChildren; i++)  
    { 
      if (i == this.nChildren-1) 
        this.children[i].initialize(level, 1, leftSide) 
      else 
        this.children[i].initialize(level, 0, leftSide) 
      } 
  } 
} 
 
function drawFolder(leftSide) 
{ 
  if (browserVersion == 2) { 
    if (!doc.yPos) 
      doc.yPos=8 

    if(!doc.yBottom)
      doc.yBottom=8

    if (!doc.yLeft)
      doc.yLeft=0

    if(!doc.yRight)
      doc.yRight=0

    doc.write("<layer id='folder" + this.id + "' top=" + doc.yPos + " visibility=hiden>") 
labelName = 'folder' + this.id;
  } 
   
  doc.write("<table ") 
  if (browserVersion == 1) 
    doc.write(" id='folder" + this.id + "' style='position:block;' ") 
  doc.write(" border=0 cellspacing=0 cellpadding=0>") 
  doc.write("<tr><td>") 
  doc.write(leftSide) 
  this.outputLink() 
  doc.write("<img name='folderIcon" + this.id + "' ") 
  doc.write("src='" + this.iconSrc+"' border=0></a>") 
  doc.write("</td><td valign=middle nowrap>") 
  if (USETEXTLINKS) 
  { 
    this.outputLink() 
    doc.write(this.desc + "</a>") 
  } 
  else 
    doc.write(this.desc) 


  doc.write("</td></tr>")  
  doc.write("</table>") 
   
  if (browserVersion == 2) 
  { 
    doc.write("</layer>") 
  } 
 
  if (browserVersion == 1) { 
    this.navObj = doc.getElementById("folder"+this.id)
    this.iconImg = document.images["folderIcon"+this.id] 
    this.nodeImg = document.images["nodeIcon"+this.id] 
  } else if (browserVersion == 2) { 
    this.navObj = doc.layers["folder"+this.id] 
    this.iconImg = this.navObj.document.images["folderIcon"+this.id] 
    this.nodeImg = this.navObj.document.images["nodeIcon"+this.id] 
    doc.yPos=doc.yPos+this.navObj.clip.height 
    doc.yBottom = doc.yBottom+this.navObj.clip.bottom
    doc.yLeft=this.navObj.clip.left
    doc.yRight=this.navObj.clip.right
  } 
} 
 
function outputFolderLink() 
{ 
  var initLabel = "";
  if(!this.id==0)
  {       initLabel = rootHolder + ".";   }
  initLabel = this.desc;

  if (this.hreference) 
  { 
    doc.write("<a href='" + this.hreference + "' onClick=\"callLogApplet(\'" + this.desc + "\')\" TARGET=\"saa\" ")
     //change for 2.4
    //doc.write("<a href='" + this.hreference + "' TARGET=\"saa\" ")
    if (browserVersion > 0) 
      doc.write("onClick='javascript:clickOnFolder("+this.id+","+this.desc+")'") 
    doc.write(">") 
  } 
  else 
  {
    doc.write("<a href='javascript:clickOnNode("+this.id+",\""+initLabel+"\")'>")
  }
} 
 
function addChild(childNode) 
{ 
  this.children[this.nChildren] = childNode 
  this.nChildren++ 
  return childNode 
} 
 
function folderSubEntries() 
{ 
  var i = 0 
  var se = this.nChildren 
 
  for (i=0; i < this.nChildren; i++){ 
    if (this.children[i].children) //is a folder 
      se = se + this.children[i].subEntries() 
  } 
 
  return se 
} 
 
// Definition of class Item (a document or link inside a Folder) 
// ************************************************************* 
 
//function Item(itemDescription, itemLink, icon ) // Constructor 

// CTCge91021 Begin
function Item(itemframedim,itemDescription, itemLink, icon ) // Constructor 
{ 
  // constant data 
// CTCge91021 Begin
  this.framedim= itemframedim 
// CTCge91021 End
  this.desc = itemDescription 
  this.link = itemLink 
  this.id = -1 //initialized in initalize() 
  this.navObj = 0 //initialized in render() 
  this.iconImg = 0 //initialized in render() 
  this.image_dir = csd_image_dir
  this.iconSrc = this.image_dir + icon 

 
  // methods 
  this.initialize = initializeItem 
  this.createIndex = createEntryIndex 
  this.hide = hideItem 
  this.display = display 
  this.renderOb = drawItem 
  this.totalHeight = totalHeight 
} 
 
function hideItem() 
{ 
  if (browserVersion == 1) { 
    if (this.navObj.style.display == "none") 
      return 
    this.navObj.style.display = "none" 
  } else { 
    if (this.navObj.visibility == "hiden") 
      return 
    this.navObj.visibility = "hiden" 
  }     
} 
 
function initializeItem(level, lastNode, leftSide) 
{  
  this.createIndex() 
 
  if (level>0) 
    if (lastNode) //the last 'brother' in the children array 
    { 
      this.renderOb(leftSide + "<img src='" + this.image_dir + "/ftv2lastnode.png' width=16 height=22>") 
      leftSide = leftSide + "<img src='" + this.image_dir + "/ftv2blank.png' width=16 height=22>"  
    } 
    else 
    { 
      this.renderOb(leftSide + "<img src='" + this.image_dir + "/ftv2node.png' width=16 height=22>") 
      leftSide = leftSide + "<img src='" + this.image_dir + "/ftv2vertline.png' width=16 height=22>" 
    } 
  else 
    this.renderOb("")   

} 
 
function drawItem(leftSide) 
{ 
  if (browserVersion == 2) 
  {
    doc.write("<layer id='item" + this.id + "' top=" + doc.yPos + " visibility=hiden>") 
  }

labelNameDiv = 'item' + this.id + 'Div';
labelName = 'item' + this.id;
     
  doc.write("<table ") 
  if (browserVersion == 1) 
    doc.write(" id='item" + this.id + "' style='position:block;' ") 
  doc.write(" border=0 cellspacing=0 cellpadding=0>") 
  doc.write("<tr><td>") 
  doc.write(leftSide) 
  // CTCge91021 Begin
  //doc.write("<a href=" + this.link + ">")
         // check if this.link has "target=_blank"
         fulllink = this.link;
         matchList =fulllink.split(" ");
         targetStr=matchList[matchList.length-1];
         targetStrPattern =/target=_blank/g;
         if (targetStr.match(targetStrPattern) )
         {
         // in that case extract the URL from  this.link
         myurl=matchList[0];
         // extract the framedim
         // pass these 2 params to  popitup
         // end if
         myLink1="\"#\"";
         myLink2 = myLink1 + " onClick=\"popitup(" + myurl + ", '" + this.framedim + "')\"";
         doc.write("<a href=" + myLink2 + ">")
         }
  // CTCge91021 End
  doc.write("<img id='itemIcon"+this.id+"' ") 
  doc.write("src='"+this.iconSrc+"' border=0>") 
  doc.write("</a>");
  doc.write("</td><td valign=middle nowrap>") 
  if (USETEXTLINKS) 
  {

     if(browserVersion == 1)
     {
         // CTCge91021 Begin
         //doc.write("<div id=" + labelNameDiv + ">" + "<a href=" + this.link + ">" + this.desc + "</a></div>");
         // check if this.link has "target=_blank"
         fulllink = this.link;
         matchList =fulllink.split(" ");
         targetStr=matchList[matchList.length-1];
         targetStrPattern =/target=_blank/g;
         if (targetStr.match(targetStrPattern) )
         {
         // in that case extract the URL from  this.link
         myurl=matchList[0];
         // extract the framedim
         // pass these 2 params to  popitup
         // end if
         myLink1="\"#\"";
         myLink2 = myLink1 + " onClick=\"popitup(" + myurl + ", '" + this.framedim + "')\"";
         doc.write("<div id=" + labelNameDiv + ">" + "<a href=" + myLink2 + ">" + this.desc + "</a></div>");
         }
         else
         {
           doc.write("<div id=" + labelNameDiv + ">" + "<a href=" + this.link + ">" + this.desc + "</a></div>");
         } 
         // CTCge91021 End
     }
     else
     {
	var leftLength = imgTagCtr(leftSide);
	var initDim=22;
	var leftDim = initDim + 17 * leftLength;
	doc.write("<layer id=" + labelNameDiv + " left=" + leftDim + ">");
	doc.write("<a href=" + this.link + ">" + this.desc + "</a>")
	doc.write("</layer>");
     }
  }
  else 
  {
    doc.write(this.desc) 
  }

  doc.write("</td></tr>");
  doc.write("</table>") 
   
  if (browserVersion == 2) 
  {
    doc.write("</layer>") 
  }
 
  if (browserVersion == 1) { 
    this.navObj = doc.getElementById("item"+this.id) 
    this.iconImg = doc.getElementById("itemIcon"+this.id) 
  } else if (browserVersion == 2) { 
    this.navObj = doc.layers["item"+this.id] 
    this.iconImg = this.navObj.document.images["itemIcon"+this.id] 
    doc.yPos=doc.yPos+this.navObj.clip.height 
    doc.yBottom=doc.yBottom+this.navObj.clip.bottom
  } 
} 
 
 
// Methods common to both objects (pseudo-inheritance) 
// ******************************************************** 
 
function display() 
{ 
  if (browserVersion == 1) 
    this.navObj.style.display = "block" 
  else 
    this.navObj.visibility = "show" 
} 
 
function createEntryIndex() 
{ 
  this.id = nEntries 
  indexOfEntries[nEntries] = this 
  nEntries++ 
} 
 
// total height of subEntries open 
function totalHeight() //used with browserVersion == 2 
{ 
  var h = this.navObj.clip.height 
  var i = 0 
   
  if (this.isOpen) //is a folder and _is_ open 
    for (i=0 ; i < this.nChildren; i++)  
      h = h + this.children[i].totalHeight() 
 
  return h 
} 
 
 
// Events 
// ********************************************************* 
 
function clickOnFolder(folderId) 
{ 
  var clicked = indexOfEntries[folderId] 
 
  if (!clicked.isOpen) 
  {
    clickOnNode(folderId, this.desc) 
  }
 
  return  
 
  if (clicked.isSelected) 
    return 
} 
 
function clickOnNode(folderId,folderLabel) 
{ 
  var x=0;
  var compId = folderId;
  var compLabel = folderLabel;
  var hString = folderLabel;
  mLen = mArray.length-1;
  for( x=mLen;x>=0;x--)
  {
	compArray = mArray[x];
	if(compId == compArray[3].id)
	{ 
		hString = compArray[0].desc + "." + hString;
		compId = compArray[0].id;
	}
  }

  folderLabel = hString;
  var clickedFolder = 0 
  var state = 0 
 
  clickedFolder = indexOfEntries[folderId] 
  state = clickedFolder.isOpen 
 
  clickedFolder.setState(!state) //open<->close  
  if(folderLabel != null) 
  {  
	callLogApplet(folderLabel);
  }
} 
 
function initializeDocument() 
{ 
  if (doc.layers) 
    browserVersion = 2 //IE4   
  else 
      browserVersion = 1 //NS4 
 
  foldersTree.initialize(0, 1, "") 
  foldersTree.display()
  
  if (browserVersion > 0) 
  { 
    doc.write("<layer top="+indexOfEntries[nEntries-1].navObj.top+">&nbsp;</layer>") 
 
    // close the whole tree 
    clickOnNode(0) 
    // open the root folder 
    clickOnNode(0) 
  } 
} 
 
// Auxiliary Functions for Folder-Treee backward compatibility 
// ********************************************************* 
 
//function gFld(description, hreference, image_dir ) 
//{
 // folder = new Folder(description, hreference, image_dir )
  //return folder
//}

function gFld(description, auxName, hreference, image_dir)
{ 
  folder = new Folder(description, hreference, image_dir ) 
  return folder 
}

function bldArray()
{
  var Instring = appendFolderString;
  if(Instring != "")
  {
    parseArray[fldCtr] = Instring;
    parseIdArray[fldCtr] = appendIdString;
    mArray[fldCtr] = new Array(
                                gParentFolder,
                                getParentFromArray(parseArray[fldCtr]),
                                getParentFromArray(parseIdArray[fldCtr]),
                                gChildFolder,
                                getChildFromArray(parseArray[fldCtr]),
                                getChildFromArray(parseIdArray[fldCtr])
                        );
    fldCtr++;
    //this uidCtr increment is to represent each folder, or each entry in the folder array
    uidCtr++;
  }

}
 
function gLnk(framedim, target, description, linkData, icon, folderName )
{
  fullLink = ""
  var hName = "";
  var gCtr = fldCtr;
  appendFolderString = "";
  var m = fldCtr;
  m = mArray.length-1;
  if(m > 0)
  {
    holdingArray = mArray[m];
  }
  firstString = "";
  firstString = folderName;

  //decrement back to find the previous folder
  if(firstString.id == -1)
  {
	hString = rootHolder;
  }
  else if(firstString.id == 0)
  {
	hString = firstString.desc;
  }
  else
  {
    var x=0;
    var hString = "";
    for( x=m;x>=0;x--)
    {
      dArray = mArray[x];      
      if(dArray != null)
      {
        var previousChild = dArray[3];
	var previousParent = dArray[0];
	if(firstString.id == previousChild.id)
	{
           firstString = previousParent;
	   if(hString == ""){ hString = firstString.desc + "." + previousChild.desc;       }
	   else{ 	
		hString = firstString.desc + "." + hString;       
           } 
         }
       }
    }
  }

  hName = hString + ".";
  hName += description;
nameSection = " NAME=\"linkInfo" + uidCtr + "\"";

  if (target==0)
  {
    targetString = "saa";
  }
  else
  {
    if (target==1)
    {
       targetString = "_blank";
    }
    else
    {
       targetString = "saa";
    }
  }


  clickEventString = nameSection + " onClick=\"callLogAppletLink('" + hName + "', '" + linkData + "')"
  //Change for 2.4
  //clickEventString = nameSection 
  clickEventString += ";hilight('item" + uidCtr + "', '" + linkData + "', '" + target + "')\"";
  uidCtr++;

  if (target==0)
  {
    fullLink = "'"+linkData+"' " + clickEventString + " target=\"saa\"";
  }
  else
  {
    if (target==1)
    {
       fullLink = "'"+linkData+"' " + clickEventString + " target=_blank";
       //fullLink = clickEventString;
    }
    else
    {
       fullLink = "'"+linkData+"' " + clickEventString + " target=\"saa\"";
    }
  }

  // CTCge91021 Begin
  linkItem = new Item(framedim, description, fullLink, icon )
  // CTCge91021 End
  return linkItem
}

function getChildFromArray( _instring )
{
  var Sep = ";";
  var Count=0;
  var firstString = "";
  var secondString = "";
  var getString = "";
  getString = _instring;

  for( Count=1; Count < getString.length; Count++)
  {
        if( getString.charAt(Count) == Sep)
        {
                var mid = getString.charAt(Count);
                firstString = getString.substring(0, Count);
                secondString = getString.substring(Count+1, getString.length);
        }
  }
	return secondString;
}

function getParentFromArray( _instring )
{
  var Sep = ";";
  var Count=0;
  var firstString = "";
  var secondString = "";
  var getString = "";
  getString = _instring;

  for( Count=1; Count < getString.length; Count++)
  {
        if( getString.charAt(Count) == Sep)
        {
                var mid = getString.charAt(Count);
                firstString = getString.substring(0, Count);
                secondString = getString.substring(Count+1, getString.length);
        }
  }
        return firstString;
}

function callLogApplet(_description)
{
  if(navigator.javaEnabled())
	{
            //change for 2.4
	    //top.pna.document.ActivityLogApplet.LogIt("FOLDER SELECTION: " + _description + " Folder selected");  
	}

}
function callLogAppletLink(_description, _linkData)
{
   	if(navigator.javaEnabled())
	{
             //change for 2.4
	    //top.pna.document.ActivityLogApplet.LogIt("TASK EXECUTION: " + _description + " selected - executing " + _linkData);
	}

}

 
function insFld(parentFolder, childFolder) 
{ 
  if(gParentFolder.desc == null){ gParentFolder = parentFolder; parentFolder.id = fldCtr; }

  if(gParentFolder == parentFolder)
  {
	parentFolder.id = gParentFolder.id;	
  }
//  else
//  {	
//	parentFolder.id = fldCtr;
//  }
  gParentFolder = parentFolder;
  appendFolderString = parentFolder.desc + ";" + childFolder.desc;
  var parentId = parentFolder.id;
  childFolder.id = uidCtr;
  var childId = childFolder.id;
  gChildFolder = childFolder;
  appendIdString = parentFolder.id + ";" + childId;
  bldArray();

  return parentFolder.addChild(childFolder) 
} 

function insDoc(parentFolder, document) 
{ 
  parentFolder.addChild(document) 
  insDocFolder = parentFolder.desc;
} 

function hilight(i, linkData, target)
{
	if(browserVersion == 1)
	{
		divName = i + 'Div';
		if(currentOn != "")
		{
			document.getElementById(currentOn).className = 'c';
		}
		document.getElementById(divName).className='nc';
		currentOn = divName;
	}
	else
	{
		if(currentOn != "")
		{
			divroot = currentOn + 'Div';
			root = document.layers[currentOn].layers[divroot];
			root.bgColor="#C0C0C0";
		}
		layer = i + 'Div';
		x = document.layers[i].layers[layer];
		x.bgColor="yellow";
		currentOn = i;
	}
	//if(target==1)
	//{
	//	window.open(linkData);
	//}
	//else
	//{
	//top.frames[1].self.frames[1].location = linkData;
	//}
	//return false;
}

function imgTagCtr(leftSideHolder)
{
        var leftCtr=0;
        while(leftSideHolder.indexOf("<") != -1)
        {
                leftCtr++;
                var theRest = leftSideHolder.substring(leftSideHolder.indexOf("<")+1, leftSideHolder.length);
                leftSideHolder = theRest;
        }
return leftCtr;
}



// Global variables 
// **************** 
 
USETEXTLINKS = 1 
indexOfEntries = new Array 
parseArray = new Array
parseIdArray = new Array
mArray = new Array
nEntries = 0 
doc = document 
browserVersion = 0 
aceInd = 0
rootHolder = ""
selectedFolder=0
tCtr = 0
fldCtr = 0;
uidCtr = 0;
insDocFolder = "";
folderString = "";
appendFolderString = "";
appendIdString = "";
gParentFolder = "";
gChildFolder = "";
rootHolderObject = "";
linkTo="123.html";
csd_image_dir = "";
labelName="";
currentOn="";
