#!/usr/bin/perl

# Input parameters from loxberryupdate.pl:
# 	release: the final version update is going to (not the version of the script)
#   logfilename: The filename of LoxBerry::Log where the script can append
#   updatedir: The directory where the update resides
#   cron: If 1, the update was triggered automatically by cron

use LoxBerry::Update;

init();

LOGINF "Deleting CloudDNS cache files to get rebuilt with https...";
unlink "$lbstmpfslogdir/clouddns_cache.json";

# Install additional apt sources e.g. if a server is down
LOGINF "Add additional servers for the apt repositories...";
open(FH, ">>", "/etc/apt/sources.list");
print FH "deb http://ftp.gwdg.de/pub/linux/debian/raspbian/raspbian/ buster main contrib non-free rpi\n";
print FH "deb http://ftp.agdsn.de/pub/mirrors/raspbian/raspbian/ buster main contrib non-free rpi\n";
close(FH);

LOGINF "Uniquify sources.list...";
my @sourceslist = split( /\n/, LoxBerry::System::read_file( "/etc/apt/sources.list" ) );

if ( scalar @sourceslist == 0 ) {
	LOGINF "/etc/apt/sources.list could not be uniquified.";
} else {
	my @unique_sourceslist = do { my %seen; grep { !$seen{$_}++ } @sourceslist };
	open(my $fh, ">", "/etc/apt/sources.list");
	print $fh join( "\n", @unique_sourceslist );
	close($fh);
	LOGOK "sources.list uniquified.";
}

LOGINF "We are migrating general.cfg to general.json ...";
LOGINF "Create backup of your general.cfg";
my ($exitcode, $output);
my $time = time;
($exitcode, $output) = execute( {
    command => "cp $lbsconfigdir/general.cfg $lbsconfigdir/general.backup_$time.cfg",
    log => $log
} );

LOGINF "Starting migration...";
($exitcode, $output) = execute( {
    command => "$lbhomedir/sbin/migrate_generalcfg.pl",
    log => $log
} );
LOGOK "Migration complete. The primary configuration of LoxBerry now is stored in general.json.";

# Remove CloudDNS cache
LOGINF "Deleting CloudDNS cache files to get rebuilt with https...";
unlink "$lbstmpfslogdir/clouddns_cache.json";

# Update Kernel and Firmware
if (-e "$lbhomedir/config/system/is_raspberry.cfg" && !-e "$lbhomedir/config/system/is_odroidxu3xu4.cfg") {
	LOGINF "Preparing Guru Meditation...";
	LOGINF "This will take some time now. We suggest getting a coffee or a second beer :-)";
	LOGINF "Upgrading system kernel and firmware. Takes up to 10 minutes or longer! Be patient and do NOT reboot!";

	unlink "/boot/.firmware_revision";
	if ( -d '/boot.tmp' ) {
		qx ( rm -r /boot.tmp ); 
	}
	qx { mkdir /boot.tmp };
	# print STDERR "Logfilename: ".$logfilename."\n";
	my ($rpiupdate_rc) = execute(" SKIP_WARNING=1 SKIP_BACKUP=1 BRANCH=stable WANT_PI4=1 SKIP_CHECK_PARTITION=1 BOOT_PATH=/boot.tmp ROOT_PATH=/ /usr/bin/rpi-update 2d76ecb08cbf7a4656ac102df32a5fe448c930b1 >> $logfilename 2>&1 ");
	if ($rpiupdate_rc != 0) {
        	LOGERR "Error upgrading kernel and firmware - Error $rpiupdate_rc";
        	$errors++;
	} else {
		my $md5_rc = 255;
		($md5_rc) = execute( "$lbsbindir/dirtree_md5.pl -path /boot.tmp/ -compare 002d45e8c6840957cb6717c1df782704" );
		if ( $md5_rc == 0 ) {
			# Delete beta 64Bit kernel (we have not enough space on /boot...)
			unlink "/boot.tmp/kernel8.img";
			unlink "/boot/kernel*.img";
			qx ( cp -r /boot.tmp/* /boot );
			qx ( rm -r /boot.tmp );
        	LOGOK "Upgrading kernel and firmware successfully.";
		} else {
			LOGERR "Error upgrading kernel and firmware (content of /boot.tmp seems to be wrong or incomplete)";
        	$errors++;
		}
	}
}

#
## If this script needs a reboot, a reboot.required file will be created or appended
LOGWARN "Update file $0 requests a reboot of LoxBerry. Please reboot your LoxBerry after the installation has finished.";
reboot_required("LoxBerry Update requests a reboot.");

LOGOK "Update script $0 finished." if ($errors == 0);
LOGERR "Update script $0 finished with errors." if ($errors != 0);

# End of script
exit($errors);
