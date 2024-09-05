@echo off

rem
rem  ApplyCfgDockables.bat
rem
rem  This batch script moves the applycfg XML command file to the proper INCP input
rem  directory and renames the file with a valid prefix.  The rename event is used
rem  by the INCP service to queue a command to the device handler utility.
rem	 


if not exist "%INSITE2_ROOT_DIR%\virtuals" (
   goto END
)

rem  perform the command file move and rename.
if not "%INCP_PROXY_DATA%" == "" (
   if not exist "%INCP_PROXY_DATA%\InCpProxyData\ToInSite\CF.REQ.0001.xml%" (
      copy /y "%INSITE2_HOME%\AgentConfig\data\applycfgcmd.xml" "%INCP_PROXY_DATA%\InCpProxyData\ToInSite"
      ren "%INCP_PROXY_DATA%\InCpProxyData\ToInSite\applycfgcmd.xml" CF.REQ.0001.xml
   )	
)


:END