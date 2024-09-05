#!C:\Perl\bin\perl

# This Perl Script will basically will read an XML file(default is platform.pl or user specified xml file with -f option). This is basically do 
# install and uninstall all the softwares needed for Insite2 platform. It is also having lot of command line options too(see usage function). For
# each software which will add to Insite2 platform, user has to explicitely write function to install and uninstall it.

# Author : Sunny Matson Date: October, 2005


use Getopt::Long;
use XML::Simple;
use Cwd;
use Cwd 'chdir';
use File::Basename;
use File::Copy; 

$httpd_config_file="";
$mod_config_file="";
$doc="";

$package_path="";
$install_path="";
$log_path="";
$action="";
$feature="";

$CKM_upgrade_id="{28EBEADC-3D8A-4DCE-B8F1-9F21DEA7FC12}";

#Questra Installer routine...
sub Questra{
	$log_path=$package_path;
	if($action=~/\binstall\b/i) {
		if(! $ENV{'INSITE2_ROOT_DIR'} eq "") {
			print "Questra Service Agent already installed ! Please Un-install to Re-install the same\n";
			return 1;
		}
		die "JAVA_HOME is not set. Install Qustra Service Agent again\n" if($ENV{JAVA_HOME} eq "");
		if(-d $install_path) {
			my $cpret=system("copy $package_path $install_path");
			print "Package is already copied to the install path\n" if( $cpret1 ne 0 );
		}
		else {
			$install_path_withQuote='"'.$install_path.'"';
			my $qsaret=system("mkdir $install_path_withQuote");
			die "Error in creating the install directory\n" if( $qsaret ne 0 );
			my $cpret=system("copy $package_path $install_path_withQuote");
			#system("copy GenericInstaller.xml $install_path");
		        #copy("GenericInstaller.xml",$install_path);
			die "Error in copying the package\n" if( $cpret ne 0 );
		}
	$log_path=$package_path;
	 #print("\n path = ");
	 #print($log_path);
 
	 $install_path1=$install_path;
	 #print("\n path = ");
	 #print($install_path1);
	 #print("\n \n\n");
	 copy("GenericInstaller.xml", $install_path) or die "Generic File cannot be copied.";



		my $curdir=getcwd;
		chdir $install_path;
		my $curdir1=getcwd;
		my $exeret=system("$package_path");
		die "Error in installing the QSA\n" if( $exeret ne 0 );
		print  "********************************************\n";
	   	print  "Questra Service Agent Successfully installed in the System\n";
		print  "*********************************************\n";
		chdir $curdir;
		my $backtosqdir=getcwd;
		return 1;
	}
	elsif($action=~/uninstall/i) {
		if($ENV{'INSITE2_ROOT_DIR'} eq "") {
	  		print "Questra Service Agent is not installed in the system.. Skipping!!!\n";
	  		return 1;
		}
		my $ird=$ENV{'INSITE2_ROOT_DIR'};
		$exe='"'.$ird."/_uninst/uninstaller.exe".'"';
		my $uninstret=system($exe);
		if($uninstret eq 0){
			print  "*********************************************\n";
			print "Questra Service Agent un-installed from the system.. \n";
			print  "*********************************************\n";
		}
		else {
			print "Error during un-install QSA\n" ;
		}
		return 1;
	}
}

sub CookieMonster{
	$log_path=$package_path;
	if($action=~/\binstall\b/i) {
		if(! $ENV{'WIP_HOME'} eq ""){
			print "CookieMonster is already installed!!! For Reinstalling First Uninstall CookieMonster\n";
			return 1;
		}
		die "JAVA_HOME is not setted. Install CookieMonster again\n" if($ENV{JAVA_HOME} eq "");
		die "Perl is not installed in the system. Install platform again\n" if($ENV{PERL_HOME} eq ""); 
		my $msi="msiexec /i ".'"'.$package_path.'"'." /L ".'"'.$log_path.'_install.txt"'." /qn AppDir=".'"'.$install_path.'"'; 
		$ret = system($msi);
		if($ret eq 0){
			print  "********************************************\n";
		   	print  "CookieMonster Successfully installed in the System\n";
			print  "*********************************************\n";
			@features=split(",", $feature);
			$install_path1=$install_path;
			$install_path1=~s/\\/\//;
			foreach $feature (@features) {
				if($feature=~/php/i){
					print "Enabling PHP in the CookieMonster platform\n";
					open CONFIG, ">>".$install_path1."/Apache/conf/httpd.conf";
					print CONFIG 'LoadModule php5_module "'.$install_path1.'/php/php5apache2.dll"'."\n";
					print CONFIG "AddType application/x-httpd-php .php"."\n";
					print CONFIG 'PHPIniDir "'.$install_path1.'/php'.'"'."\n";
					close CONFIG;
				}
				elsif($feature=~/service/i){
					print "Enabling Apache and Tomcat as Service\n";
					$service='"'.$install_path."\\service.bat".'" '.$install_path;
					`$service`;
					open SERVICE, ">".$install_path1."/Service.txt";
					print SERVICE "Enabled Service for Cookie Monster\n";
					close SERVICE;
				}
			}
		}
		else {
			print "Cookie Monster installation failed. Please check install log file\n";
		}
		return 1;
	}
	elsif($action=~/uninstall/i) {
		if($ENV{WIP_HOME} eq "") {
		  	print "Cookie Monster is not installed in the system.. Skipping!!!\n";
		  	return 1;
		  }
	  $install_path=$ENV{WIP_HOME};
	  $CKM_kill='"'.$install_path."\\CookieMonster.bat".'"'." stop";
	  `$CKM_kill`;
	  if(-f $install_path."/Service.txt"){
				$Apache_service='"'.$install_path."\\Apache\\bin\\Apache.exe".'"'." -k uninstall";
				$Tomcat_service='"'.$install_path."\\tomcat\\bin\\service.bat".'"'." remove";
				`$Apache_service`;
				`$Tomcat_service`;
				unlink($install_path."/Service.txt");
	  }
		my $msi="msiexec /x ".$CKM_upgrade_id.' /L "'.$install_path.'CookieMonster_Uninstall.txt"'." /qn";
	   	$ret = system($msi);
		if ($ret eq 0) {
			$remove_ckm="rmdir /Q /S ".'"'.$install_path.'"';
			$ret_rem=system($remove_ckm);
			print  "*********************************************\n";
			print  "Cookie Monster is Un-installed from the system\n";
			print  "*********************************************\n";
		}
		else {
			print "Uninstallation of Cookie monster failed. Please check Uninstall log file\n";
		}
		return 1;
	}
}

sub configure_platform{
	my $count = 0;
	foreach my $key (keys (%{$doc->{software}})){
		next if ($key eq "none");
		if($action_user ne "none") {
			$action=$action_user;
		}
		else {
			$action=$doc->{software}->{$key}->{action} if($doc->{software}->{$key}->{action});
		}
		if($action=~/\binstall\b/i){
			if($doc->{software}->{$key}->{pkg}->{path}){
				$package_path=$doc->{software}->{$key}->{pkg}->{path};
   				-f $package_path or die("Package Path for $key $package_path is not existing!!!! Quiting\n"); 	
			}
			else {
   				die("Package Path for $key is not mentioned!!!! Quiting\n");
			}
			if($doc->{software}->{$key}->{pkg}->{install_path}) {
		    	$install_path= $doc->{software}->{$key}->{pkg}->{install_path};
			}			else {
		    	die("Install Path for $key software is not mentioned... Quiting\n");
			}
		}

		#Generic() if ($key=~/Generic/i);

		$feature=$doc->{software}->{$key}->{'enable-feature'} if ($doc->{software}->{$key}->{'enable-feature'});

		#Install CKM ...
		CookieMonster() if ($key=~/cookiemonster/i);

		#Install the questra service agent...
		Questra() if ($key=~/Questra/i);

	}
}

sub Generic {
 
 $log_path=$package_path;
 #print($log_path);
 
 #print("\n ");
 $install_path1=$install_path;
 #print($install_path1);
 #print("\n \n\n");
 copy($log_path, $install_path) or die "Generic File cannot be copied.";
 
 }


sub initialize{
	if($action_user=~/uninstall/i){
		$action=$action_user;
		Questra();
		CookieMonster();
		return;
	}
	if (! -f $_[0]) {
		die "Configuration File $_[0] : not existing\n";
	}
	my $software="<software name=".'"none"'.">\n</software>";
	open CONFIG, "$_[0]" or die "Not able to open $_[0] configuration file";
	$config_out=$_[0]."_out";
	open CONFIG_OUT, ">".$config_out or die "Not able to open configuration file";
	while(<CONFIG>){
		if(/<Insite2>/i){
			print CONFIG_OUT $_;
			print CONFIG_OUT $software."\n";
		}
		else {
			print CONFIG_OUT $_;
		}
	}
	close CONFIG_OUT;
	my $xs1 = XML::Simple->new();
	$doc = $xs1->XMLin($config_out);
	configure_platform();
	unlink($config_out) if (-f $config_out);
}

#Help to execute the prograqm
sub Usage(){
	print "\nHelp for the Platform.pl\n";
	print "platform.pl will execute with default platform.xml in the current directory\n";
	print "platform.pl -f <filename> will execute with the given file\n";
	print "platform.pl -h will give the Usage()\n";
	print "platform.pl -a <install/uninstall> -f <filename or default will go>";
	exit;
}

$platform_cfg="none";
$help="none";
$action_user="none";
GetOptions ('f|file:s' => \$platform_cfg, 'h|help|?:s' => \$help, 'a|action:s' => \$action_user);
die "PERL_HOME is not set. Please use correct version of perl\n" if($ENV{PERL_HOME} eq "");
if($help eq ""){
	Usage();
}
if ($platform_cfg eq "none" or $platform_cfg eq ""){
	$config="platform.xml";
}
else {
	$config=$platform_cfg;
}
initialize($config);
