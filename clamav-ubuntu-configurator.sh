#!/bin/bash
#
# This script is used to install and configure the required clamav antivirus software packages for the Ubuntu
# operating system. It is intended to be run on a fresh installation of Ubuntu 22.04 LTS.
#
# Usage: sudo bash clamav-ubuntu-configurator.sh
# ------------------------------------------------------------------------------

# Update the package list
sudo apt-get update

# Install the clamav antivirus software and the clamtk GUI
sudo apt-get install -y clamav clamav-daemon clamtk

echo "ClamAV packages has been installed successfully."

echo "Backing up the original configuration files..."
sudo cp /etc/clamav/clamd.conf /etc/clamav/clamd.conf.bak
sudo cp /etc/clamav/freshclam.conf /etc/clamav/freshclam.conf.bak


# Configure the clamav antivirus software
echo "Configuring the ClamAV antivirus software..."

sudo tee -a /etc/clamav/clamd.conf <<EOF
#Automatically Generated by clamav-daemon postinst
#To reconfigure clamd run #dpkg-reconfigure clamav-daemon
#Please read /usr/share/doc/clamav-daemon/README.Debian.gz for details
LocalSocket /var/run/clamav/clamd.ctl
FixStaleSocket true
LocalSocketGroup clamav
LocalSocketMode 666
# TemporaryDirectory is not set to its default /tmp here to make overriding
# the default with environment variables TMPDIR/TMP/TEMP possible
User clamav
ScanMail false
ScanArchive true
ArchiveBlockEncrypted false
MaxDirectoryRecursion 25
FollowDirectorySymlinks false
FollowFileSymlinks true
ReadTimeout 180
MaxThreads 24
MaxConnectionQueueLength 15
LogSyslog false
LogRotate true
LogFacility LOG_LOCAL6
LogClean false
LogVerbose false
PreludeEnable no
PreludeAnalyzerName ClamAV
DatabaseDirectory /var/lib/clamav
OfficialDatabaseOnly false
SelfCheck 3600
Foreground false
Debug false
ScanPE true
MaxEmbeddedPE 10M
ScanOLE2 true
ScanPDF true
ScanHTML true
MaxHTMLNormalize 10M
MaxHTMLNoTags 2M
MaxScriptNormalize 5M
MaxZipTypeRcg 1M
ScanSWF true
ExitOnOOM false
LeaveTemporaryFiles false
AlgorithmicDetection true
ScanELF true
IdleTimeout 30
CrossFilesystems true
PhishingSignatures true
PhishingScanURLs true
PhishingAlwaysBlockSSLMismatch false
PhishingAlwaysBlockCloak false
PartitionIntersection false
DetectPUA false
ScanPartialMessages false
HeuristicScanPrecedence false
StructuredDataDetection false
CommandReadTimeout 30
SendBufTimeout 200
MaxQueue 100
ExtendedDetectionInfo true
OLE2BlockMacros false
AllowAllMatchScan true
ForceToDisk false
DisableCertCheck false
DisableCache false
MaxScanTime 120000
MaxScanSize 100M
MaxFileSize 25M
MaxRecursion 16
MaxFiles 10000
MaxPartitions 50
MaxIconsPE 100
PCREMatchLimit 10000
PCRERecMatchLimit 5000
PCREMaxFileSize 25M
ScanXMLDOCS true
ScanHWP3 true
MaxRecHWP3 16
StreamMaxLength 250M
LogFile /var/log/clamav/clamav.log
LogTime true
LogFileUnlock false
LogFileMaxSize 0
Bytecode true
BytecodeSecurity TrustSigned
BytecodeTimeout 60000
OnAccessMaxFileSize 5M
EOF


sudo tee -a /etc/clamav/freshclam.conf <<EOF
# Automatically created by the clamav-freshclam postinst
# Comments will get lost when you reconfigure the clamav-freshclam package

DatabaseOwner clamav
UpdateLogFile /var/log/clamav/freshclam.log
LogVerbose false
LogSyslog false
LogFacility LOG_LOCAL6
LogFileMaxSize 0
LogRotate true
LogTime true
Foreground false
Debug false
MaxAttempts 5
DatabaseDirectory /var/lib/clamav
DNSDatabaseInfo current.cvd.clamav.net
ConnectTimeout 30
ReceiveTimeout 0
TestDatabases yes
ScriptedUpdates yes
CompressLocalDatabase no
Bytecode true
NotifyClamd /etc/clamav/clamd.conf
# Check for new database 1 times a day
Checks 1
DatabaseMirror db.local.clamav.net
DatabaseMirror database.clamav.net
EOF

# Update the virus definitions
sudo freshclam
#sleep 5
#sudo freshclam -d

# Start the clamav daemon
sudo systemctl enable --now clamav-daemon

echo "Creating the required directories..."
mkdir -p $HOME/.clamtk/{viruses,history}

# Add a cron job to scan the home directory every day at 12:10 PM
echo "Adding a cron job to scan the home directory every day at 12:10 PM..."

crontab -l | { cat; echo '10 12 * * * /usr/bin/clamscan --exclude-dir=$HOME/.clamtk/viruses --exclude-dir=smb4k --exclude-dir=/run/user/$(whoami)/gvfs --exclude-dir=$HOME/.gvfs --exclude-dir=.thunderbird --exclude-dir=.mozilla-thunderbird --exclude-dir=.evolution --exclude-dir=Mail --exclude-dir=kmail -i  --detect-pua -r /home/$(whoami) --log="$HOME/.clamtk/history/$(date +\%b-\%d-\%Y).log" 2>/dev/null'; } | crontab -

echo "Cron job has been added successfully. You can change its schedule by running 'crontab -e'."

echo "List of cronjobs:"
crontab -l

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------
