#!/bin/bash

date


#############################################
# Some error handling
#############################################

# Check for parameter
if [ -z "$1" ]; then
    # No arguments supplied
	exit 1
fi

## Check environment
if [ ! -d $LBHOMEDIR ]; then
	# Cannot get LoxBerry environment variables.
	exit 1
fi

#############################################
## Get current hostname
#############################################

old=$(hostname -s)

#############################################
## Get new hostname
#############################################

new="$1"

# Make name lowercase
declare -l new
new=$new

# Get newup in uppercase
declare -u newup
newup=$newup

# Get newfirstup with first char uppercase
newfirstup="$(tr '[:lower:]' '[:upper:]' <<< ${new:0:1})${new:1}"

#############################################
## change Hostname (implicitely /etc/hostname
#############################################

hostnamectl --no-ask-password set-hostname $new

#############################################
## /etc/hosts
#############################################

cp -p -n -T /etc/hosts /etc/original.hosts
sed -i "/$old.*$/d" /etc/hosts
sed -i '/127\.0\.1\.1.*$/d' /etc/hosts

#############################################
## /etc/apache2/apache2.conf
#############################################

cp -p -n -T $LBHOMEDIR/system/apache2/apache2.conf $LBHOMEDIR/system/apache2/original.apache2.conf
sed -i "/ServerName /s/.*/ServerName $new.home.local/" $LBHOMEDIR/system/apache2/apache2.conf

#############################################
## /opt/loxberry/config/system/minidlna.conf
#############################################
## sed '/match/s/.*/replacement/' file

#cp -p -n -T /opt/loxberry/config/system/minidlna.conf /opt/loxberry/config/system/original.minidlna.conf
#sed -i "/friendly_name=/s/.*/friendly_name=Loxberry $newfirstup/" /opt/loxberry/config/system/minidlna.conf

#############################################
## /etc/mailname
#############################################

cp -p -n -T /etc/mailname /etc/original.mailname
echo $new > /etc/mailname

#############################################
#############################################
## Plugin Hostnames
#############################################
#############################################

#############################################
## /opt/loxberry/config/plugins/dnsmasq/DNSmasq_leases.cfg
#############################################
# cp -p -n -T /opt/loxberry/config/plugins/dnsmasq/DNSmasq_leases.cfg /opt/loxberry/config/plugins/dnsmasq/original.DNSmasq_leases.cfg
# sed -i "/ $old / s/ $old / $new /" /opt/loxberry/config/plugins/dnsmasq/DNSmasq_leases.cfg
