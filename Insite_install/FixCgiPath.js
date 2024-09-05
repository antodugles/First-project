// FixCgiPath.js
//
// Usage:
//    cscript FixCgiPath.js -i InputFile -o OutputFile [-p ProductName] -d Directory
//     -InputFileList   This file contains a list of files to process
//     -OutputDir:      This is the ouput dirctory
//     -p  ProductName: This is the product name.  It is used to read in the property files
//     -d  Directory where the property files are  placed
//
//  This program will put a line of the form #!C:/PERL/bin/perl.exe at the beginning of a file.
//  This is based on ReplaceVars.bat.
//  It obtains the location of perl form the ReplaceVars.dat and ReplaceVars-PRODUCT.dat.
//  It uses the property  PERL_EXE for the path to the perl exe.
//
//  The properties are read in first from the file
//           Directory\ReplaceVars.dat
//  If the -p switch is present, an additional propery file is read in:
//           Directory\FixCgiPath-ProductName.dat
//  Any propeties in the ReplacesVars-ProductName.dat will overwrite any found
//  in the ReplacesVars.dat file.
//
//  Format of property file:
//   NAME=VALUE
//  note the NAME does not include the leading and trailing underscores.
//

/*****************************************
    Begin Globals
*****************************************/
{
    var DEBUGFLAG = true;  // set to false to disable debug logging
    var Wshell = WScript.CreateObject("Wscript.Shell");
    var SysEnv = Wshell.Environment("Process");
    var fs = new ActiveXObject("Scripting.FileSystemObject");

    var ForReading = 1, ForWriting = 2;

    WScript.Quit(mainApp());
}
/*****************************************
              End Globals
*****************************************/
function mainApp()
{
    var InputListFName
    var DirectoryName="";
    var ProductName="";
    debugger;
    WScript.Echo("FixCgiPath.js");
    
    if ( WScript.Arguments.length < 6 )
    {
        WScript.Echo("\tERROR:  Wrong number of options");
        return helpText();
    }
    var i;
    for( i=0; i< WScript.Arguments.length; i++)
    {
        var cSwitch = WScript.Arguments.item(i);
        if ( i+1 < WScript.Arguments.length )
            var cValue  = WScript.Arguments.item(i+1);
        switch (cSwitch)
        {
        case "-InputFileList":
            InputListFName = cValue;
            i++;
            break;
        case "-OutputDir":
            OutputDirName = cValue;
            i++;
            break;
        case "-d":
            DirectoryName = cValue
            i++;
            break;
        case "-p":
            ProductName = cValue;
            i++;
            break;
        case "-h":
            return helpText();
            break;
        default:
            WScript.Echo("\tERROR:  Unknown option: " + cSwitch);
            return helpText();
        }
    }
    if ( InputListFName == "" )
    {
        WScript.Echo("\tERROR:  -InputFileList switch is missing");
        return helpText();
    }
    if ( OutputDirName == "" )
    {
        WScript.Echo("\tERROR:  -OutputDir switch is missing");
        return helpText();
    }
    if ( DirectoryName == "" )
    {
        WScript.Echo("\tERROR:  -d switch is missing");
        return helpText();
    }
    var bError=false;
    if ( !fs.FileExists(InputListFName))
    {
        WScript.Echo("\tERROR:  Can't find file: " + InputListFName);
        bError=true;
    }
    OutputDirName = OutputDirName.replace(/\\$/, ""); // remove trailing backslash
    if ( !fs.FolderExists(OutputDirName))
    {
        WScript.Echo("\tERROR:  Can't find folder: " + OutputDirName);
        bError=true;
    }
    DirectoryName = DirectoryName.replace(/\\$/, ""); // remove trailing backslash
    if ( !fs.FolderExists(DirectoryName))
    {
        WScript.Echo("\tERROR:  Can't find folder: " + DirectoryName);
        bError=true;
    }
    var PropertiesFileName = DirectoryName + "\\ReplaceVars.dat";
    var PropertiesProductFileName = "";
    if ( "" != ProductName )
        PropertiesProductFileName = DirectoryName + "\\ReplaceVars-" + ProductName + ".dat";
    if ( !fs.FileExists(PropertiesFileName))
    {
        WScript.Echo("\tERROR:  Can't find file: " + PropertiesFileName);
        bError=true;
    }
    WScript.Echo(ItemToStr("Input List Name: ",  25) + InputListFName);
    WScript.Echo(ItemToStr("Output Directory: ", 25) + OutputDirName);
    WScript.Echo(ItemToStr("InputDirectory: ", 25) + DirectoryName);
    WScript.Echo(ItemToStr("ProductName: ",    25) + ProductName);
    WScript.Echo();
    if ( bError)
        return helpText();
    // create dictonary containing tokens from property file
    var dTokens = new ActiveXObject("Scripting.Dictionary");
    ReadInProperties(PropertiesFileName, dTokens);
    if (PropertiesProductFileName != "")
        ReadInProperties(PropertiesProductFileName, dTokens);

    // Read in input name file list
    var aInputFiles = new Array();
    var fin  = fs.OpenTextFile(InputListFName, ForReading);
    var buf;
    debugger;
    while( ! fin.AtEndOfStream )
    {
        buf = fin.ReadLine();
        if ( ! buf.match(/(\s|^$)/))  // do not process blank lines
             aInputFiles.push(buf);
    }
    fin.Close();
    if (0 == aInputFiles.length)
    {
        WScript.Echo("\tInput list is empty");
        return 1;
    }
    
    var i;
    var InputFileName;
    var OutputFileName;
    WScript.Echo("\tProcessing files Input > Output");
    debugger;
    for ( i=0; i < aInputFiles.length; i++)
    {
        InputFileName = aInputFiles[i];
        // remove input directory
        OutputFileName = OutputDirName + "//" + fs.GetFile(InputFileName).Name;
        WScript.Echo(ItemToStr(InputFileName, 40) + " > " + OutputFileName);
        fin  = fs.OpenTextFile(InputFileName, ForReading);
        var fout = fs.OpenTextFile(OutputFileName, ForWriting, true);
        // read in the file one line at a time
        buf = "#!" + dTokens("PERL_EXE");
        fout.WriteLine(buf);
        // special treatment for the first line
        buf=fin.ReadLine();
        if ( ! buf.match(/^\#\!/) )  //   match for line beginning #!
            fout.WriteLine(buf);
        // copy the rest of the file
        while( ! fin.AtEndOfStream )
        {
            buf = fin.ReadLine();
            fout.WriteLine(buf);
        }
        fout.Close();
        fin.Close();
    }
    return 0;
}

function helpText()
{
    WScript.Echo("  Usage:");
    WScript.Echo();
    WScript.Echo("\tcscript FixCgiPath.js -i InputFile -o OutputFile [-p ProductName] -d Directory");
    WScript.Echo("\t -InputFileList   This file contains a list of files to process");
    WScript.Echo("\t -OutputDir:      This is the ouput dirctory");
    WScript.Echo("\t -p  ProductName: This is the product name.  It is used to read in the property files");
    WScript.Echo("\t -d  Directory where the property files are  placed");
    WScript.Echo("\t -h  This help message");
    return 1;
}

function ReadInProperties( Fname, dDict)
{
    WScript.Echo("\tReading property file: " + Fname);
    var fin = fs.OpenTextFile(Fname, ForReading);
    while( ! fin.AtEndOfStream )
    {
        var buf;
        buf = fin.ReadLine();
        var tokens = buf.split("=");
        if ( tokens.length < 2 )
            continue;
        var key = tokens[0];
        var value = tokens[1];
        // remove leading and trailing whitespace
        key   =   key.replace(/(^\s*)|(\s*$)/g, "");
        value = value.replace(/(^\s*)|(\s*$)/g, "");
        if ( dDict.Exists(key))
             dDict.Item(key) = value;
        else
            dDict.Add(key, value);
    }
    fin.Close();
}

// ItemToStr takes a value and generates a string prefixed with fillChar
function ItemToStr(value, fieldSize, fillChar)
{ 
	if ( ! fillChar )
		fillChar =" ";
	var xStr=new String(value);
	var i;	
	var res = "";
	for( i = xStr.length; i< fieldSize; i++ )
		if (i == fieldSize -1)
			res += " ";
		else
			res += fillChar;
	res += xStr;
	return res;
}
