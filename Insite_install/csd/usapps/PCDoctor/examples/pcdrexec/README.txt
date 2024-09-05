--------------------------------------------------------------
Using The Scripting Module (pcdrexec)
--------------------------------------------------------------

  PC-Doctor has provided a module called pcdrexec which can be
  used to run user created scripts or programs from the 
  PC-Doctor architecture.  This module is configurable, and 
  can be setup to run against any device that is discovered
  by the PC-Doctor architecture.  The module allows for users 
  to run scripts and report back progress and final results
  to the PC-Doctor engine as well as report results to a  
  log file.
  

  Quick Start:

    To run the example script do the following:
    1) copy pcdrexec* ..\..\bin (copy pcdrexec* files to pcdoctor\bin 
    directory)
    2) copy *.bat ..\..\bin (copy test scripts to pcdoctor\bin directory)        
    3) cd ..\..\bin (Go to pcdoctor\bin directory)
    4) pcd list (This will show you a list of devices on
          the system and a list of tests that can be run on
          them. The pcdrexec test should be listed against the 
          System device.  Note the number of the System device
          and the number of the pcdrexec test.)
    5) To run the test script figure out the test number
          and the device number and then run the test by doing
          the following pcd run -t <testnum> -d <devicenum>
          e.g. 
            pcd run -t 1 -d 1
       
    By running this, you will be running the associated
    script and the result from the script will appear in the UI
    log file. 


  Running A Custom Script:

    To get your own custom script working you will need to do
    the following:

      1) Create a script.
      2) Update the pcdrexec.p5i

         The following entries can be updated in the pcdrexec.p5i
         file to rename the tests and script to be run.
         
         //The name of the first test:
         Test.1.Name=MyTest
         
         //The types of devices that this script will run on
         //The device type must be set to one of the following 
         //device types shown at the bottom.
         Test.MyTest.DeviceTypeToTest=HardDrive
         
         //The name of the script of program to run        
         Test.MyTest.ProgramOrScriptToRun=test.bat
         
         Now you can run the script as detailed above.


  Mapping Script Return Results To Error Strings:

    Pcdrexec reports a final result from the script or 
    program that it ran.  Pcdrexec reads the value returned
    from the program and uses this value to report the final 
    result.  A result from the script of 0 is a PASS 
    result.  Any other value will return a FAILED result.
    When a non 0 result is returned pcdrexec will also
    return an error message.  You can customize this 
    error message by adding key value pairs to the pcdrexec.p5i
    file.  
 
    Test.ErrorMessage.<ReturnResultNumber> = <Error string shown to
                                           user and logged>
       
    e.g.
      Test.ErrorMessage.23 = Error Reading Sector
       
    where <ReturnResultNumber> is the non zero result returned 
    by the test script. 
                                    

  Percent Done Reporting To The UI From Pcdrexec

    To get the UI to correctly update the percent done
    string simply print out from the script the string
    "PERCENT DONE <percent>%"  to stderr, where percent is the 
    value of percent done. 
    e.g. From a script file:
      echo PERCENT DONE 5% 1>&2
      
    This will update the UI with information about the progress
    of the test.
       

  Script StdOut Redirection To Stop Text UI Overwriting

      Any text that is output to stdout from a test script
      is now automatically redirected to a file.  The name of
      the file where stdout is redirected to is by default 
      pcdrexec.debug.txt.  This file name is specified in the
      pcdrexec.p5i file and can be changed there.  The key name
      for this setting is Test.MyTest.DebugOutputFile
                
      Mutiple such entries could be associated with different Tests.
      All the tests should be defined in p5p file as

     
  Device Types
    All
    SMART
    System
    TCPIP
    AGP
    AGP1X
    AGP2X
    AGP4X
    AGP8X
    ATA    
    Channel
    EHCI    
    IDE
    IEEE1394
    InfaredPort
    OHCI
    Other
    PCI
    PCIBridge
    PCICardBusBridge
    PCIEISABridge
    PCIExpress
    PCIHostBridge
    PCIISABridge
    PCIPCIBridge
    PCIPCMCIABridge
    PCIX
    ParallelPort
    Port
    SATA
    SCSI
    SerialPort
    UHCI
    USB
    USB2
    USBComposite
    AgpBus
    ComBus
    I2CBus
    IEEE1394Bus
    IdeBus
    IsaBus
    LptBus
    MemoryBus
    PS2Bus
    PciBus
    PcmciaBus
    SMBus
    ScsiBus
    SystemBus
    UsbBus
    3DNOW
    3DNOWEXT
    AMDSSEMMX
    AMDTEST
    AMISCSIRAID
    ATM
    AVI
    AdaptechScsiRAID
    BIOS
    CMOS
    CPU
    CableModem
    Camera
    CardReader
    Chassis
    DSLAdapter
    Default
    Digitizer
    DockingStation
    DrivePartition
    Ethernet
    FaxModem
    Firmware
    FloppyDrive
    GPS
    HID
    HT
    HUB
    HardDrive
    IEEE1394Controller
    ISDNAdapter
    InternalHub
    Joystick
    Keyboard
    LSDRIVE
    MIDI
    MMX
    MassStorageController
    Memory
    MemoryController
    MemoryController
    Microphone
    Modem
    Monitor
    Mouse
    NetworkCard
    Offline
    OnBoardDevice
    OperatingSystem
    PCCard
    PSE36
    PcmciaController
    PowerSupply
    Printer
    RAID
    RTC
    RemovableStorage
    SAS
    SMBusController
    SSE
    SSE2
    SSE3
    Scanner
    Slot
    Software
    SoundCard
    Speaker
    SystemBoard
    TapeDrive
    TempSensor
    TokenRing
    USBController
    UnitTester
    VideoCard
    VoltSensor
    WiKeyboard
    WiMouse
    ZipDrive
    Optical
    CDROM
    CDR
    CDRW
    DVD
    DVDMINUSRW
    DVDPLUSRW
    DVDRAM

--------------------------------------------------------------
Creating Your Own Testing Module Using PcdrExec
--------------------------------------------------------------

  PC-Doctor has provided a module called pcdrexec which can be
  used to run user-created scripts or programs through the 
  PC-Doctor architecture.  This module is configurable, and 
  can be setup to run against any device that is discovered
  by PC-Doctor.  The module allows for users 
  to run scripts and report back progress and final results
  to the PC-Doctor engine as well as report results to a  
  log file similar to other testing modules.

  Quick Start:

    We will create a simple test module called mymodule.p5x

    1) Change directories to the install directory.
		cd <install_path>

    2) Copy the file pcdrexec.p5x to pcdoctor\bin\mymodule.p5x
 		copy examples\pcdrexec\pcdrexec.p5x bin\mymodule.p5x

    3) Copy the file pcdrexec.p5i to pcdoctor\bin\mymodule.p5i
 		copy examples\pcdrexec\pcdrexec.p5i bin\mymodule.p5i

    4) Copy the file pcdrexec.p5p to pcdoctor\bin\mymodule.p5p
 		copy examples\pcdrexec\pcdrexec.p5p bin\mymodule.p5p 
 
    5) Copy the test scripts to the pcdoctor/bin directory
    		cp examples\pcdrexec\test* bin\
 
    6) Change directories to the pcdoctor\bin directory
		cd bin

    7) For this example we will use the existing settings in the p5i
       file but later you can refer to the PcdrExec Advanced Setup section 
       below for instructions on how to add and remove tests.

    8) Create the meta data file mymodule.p5m by doing the following:
		mymodule.p5x -m
    
    9) You now have a working module that will run through PC-Doctor.

    10) To See the available tests type: 
          pcd list 

          This will show you a list of devices on
          the system and a list of tests that can be run on
          them. The mymodule tests MyTest1, MyTest2 and MyTest3 should
          appear under the System device.  Make a note of the number in
          brackets of the System device.  This is its device number.
          Make a note of the number next to the bracket of the 
          MyTest's as this is each tests test number.

    11) To run the mymodule tests do the following:          
          pcd run -t <test_number> -d <device_number>
          e.g. 
            pcd run -t 1 -d 1


--------------------------------------------------------------
Setting Up A PcdrExec Module In The Network Factory Server
--------------------------------------------------------------

  To get a pcdrexec module running from the Network Factory Server 
  you need to do the following:

    1) Copy the mymodule.p5m file to the server from the UUT and put the file in 
       C:\Program Files\PC-Doctor Network Factory\Apache2\htdocs\src\p5ms\Windows

       If the directory Windows does not exist create it.       
       
    2) Start the server
          From the Start bar, in "All Programs" go to "PC-Doctor Network Factory" 
          and click on "Start Network Factory Server".

    3) Open the Network Factory Monitor.
          From the Start bar, in "All Programs" go to "PC-Doctor Network Factory" 
          and click on "View Network Factory"

    4) Create a script
         a) In the Network Factory Monitor click on the "Script Editor" tab
         b) Select OS "Windows" from the pull down
         c) Click on the "new" script button
         d) Enter a description for the script e.g. My Script
         e) Click on and check all of the tests of the left that you 
              want added to the script.  If you want them all then select
              the device category box.
         f) Click the "Add Tests" button to add them to the current script
         g) Save the script by clicking on the "Save New Tests" button  
         h) A dialog will pop up asking for the name of the script.
            Note: You must enter a file name ending in .xml
            e.g. myscript.xml

    5) Update configurations
         You can associate your new script with a group so that any UUT that
         is run under this group will run this script. 
         a) Click on the "Configuration" tab
         b) Click "Add New Mappings"
         c) In the field entry grid at the top fill in the first two fields as
            follows:
              Group     Config     Phase                 Value
             ---------------------------------------------------
              mygroup   *          *        bootstrap    bootstrap.bat
              mygroup   *          *        script       myscript.xml

            And click the "Add Entries" button.  This will associate the 
            default bootstrap script with the mygroup group and also associate
            your new script myscript.xml with the mygroup as well.

     6) Now click on the "Progress Monitor" tab as we are ready to run tests on 
          the UUT.

     7) Now go to the UUT machine.
          To run the myscript.xml on this machine you will need to go to the
          <install directory>/pcdoctor/bin directory and run the following command

	    pcd uut -ui -s <server-url>:<port> -id <some-system-id(MAC maybe)> -a <Human-Readable-System-Name>
			 -g <group>

          e.g. pcd uut -ui -s 192.168.10.10:8080 -id 12:34:56:78:90:12 -a MyUUT1 -g mygroup 

          Note: The -id must be specified and the -g must be mygroup for this example

     8) If you go back to the Network Factory Progress Monitor you will see in the "Progress Monitor"
        tab the UUT status and any further information about the test.
  

--------------------------------------------------------------
PcdrExec Advanced Setup
--------------------------------------------------------------

  Changing hardware testing:

    By default the pcdrexec.p5x module runs the shell script test.sh or test.bat
    which is where all of the hardware testing occurs.  You can change this file's contents
    to do whatever hardware testing you need.  Or, you can create your own script or
    program and change the name of the script to be run in the settings file. (mymodule.p5i)
    For more information see the "PcdrExec Settings(.p5i) file" section below.
       
  PcdrExec Settings(.p5i) file:   

    The following entries will be found in the pcdrexec.p5i
    which can be used to change how a test module is viewed from the PC-Doctor UI's
    and how it runs.       
      
        To create a test you need to add the following entries to the p5i file

        # This is the variable name of this test in thie file
        # from now on the test is refered to as MyTest
        Test.1.Name=MyTest
       
        # Your test can be run on any type of device.  But most of the time a test
        # is designed for a specific type of device. For example a harddrive test.
        # So if you want to test harddrives with this test you would
        # want to put that device type here.  You can OR together
        # device types if you want to test multiple device types. e.g.
        # HardDrive|CDROM.
        #
        # IMPORTANT: Note that if you are running in FreeBSD or in a system with no sysinfo 
        # support, you can only run against the System device as it is the only
        # device enumerated.  So you must have a DeviceTypeToTest of System or
        # your test will not be seen.
        Test.MyTest.DeviceTypeToTest=HardDrive
        
        # Your module will be running a script or program to do the hardware testing.
        # The Test.MyTest.ProgramOrScriptToRun key specifies the name of this program.
        # The script location is referenced from the pcdoctor/bin directory       
        Test.MyTest.ProgramOrScriptToRun=./test.sh
        
        # Sometimes it is useful to get the output from the script or program that is being run
        # so you may want to redirect this output to a file.  You can do this by specifying the
        # Test.MyTest.DebugOutputFile key with the name of the file to redirect to
        Test.MyTest.DebugOutputFile=./mymodule.log


    Mapping Script Return Results To Error Strings:

      Pcdrexec reports a final result from the script or 
      program that it ran.  Pcdrexec reads the value returned
      from the program and uses this value to report the final 
      result.  A result from the script of 0 is a PASS 
      result.  Any other value will return a FAILED result.
      When a non 0 result is returned pcdrexec will also
      return an error message.  You can customize this 
      error message by adding key value pairs to the pcdrexec.p5i
      file.  
 
      Test.ErrorMessage.<ReturnResultNumber> = <Error string shown to user and logged>
             
      e.g.
      Test.ErrorMessage.23 = Error Reading Sector
       
      where <ReturnResultNumber> is the non zero result returned 
      by the test script. So in this example if the shell script returned 
      a value of 23 the above error message would be reported to the PC-Doctor UI
      and subsequently the user.


  Changing The Localized Test Names:
 
      Each PC-Doctor module has a localized strings file (p5p file) where any string that is seen by the
      end user is placed.  Here you can view the strings in English or any other localized
      language that PC-Doctor supports.  So depending on the locale of the system under test,
      you will see the appropriately translated names of the tests and other strings in the UI.

      If you want to change the end user visible name of a test you will need to do so here.
      e.g.
        Test.MyTest.Name = My Hardware Test
        Test.MyTest.Description = This test tests a hardware device  

      Where MyTest is the variable name given to the test in the p5i file.  See the 
      "PcdrExec Settings(.p5i) file" section above.
                                    

  Percent Done Reporting To The UI From Pcdrexec:

    To get the UI to correctly update the percent done
    string simply print out from the shell script the string
    "PERCENT DONE <percent>%"  to stderr, where percent is the 
    value of percent done. 
    e.g. From a script file:
      echo PERCENT DONE 5% 1>&2
      
    This will update the UI with information about the progress
    of the test.

