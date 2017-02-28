#!/bin/sh /etc/rc.common
# Name: OpenWrt autonamer
# Description: set host and domainname of an OpenWrt AP from the assigned DHCP server
# Version: 1.0
# Copyright (c) 2016, Simen Strange Øya
# License: Modified BSD license
# https://github.com/dxlr8r/openwrt-autonamer/blob/master/LICENSE

START=99

start() {
	. /lib/functions/network.sh
	
	# Wait for network
	limit=60 # maximum tries
	timer=0
	while [ $(network_get_dnsserver dnsserver lan; echo $dnsserver | wc -w) != 1 ]
	do
		timer=$((timer+1))
		if [ $timer -ge $limit ]; then
			echo "Network not up after $limit tries, exiting"
			exit 1
		fi
		sleep 1
	done
	
	#echo $timer > /tmp/sethostname-timer # log how many tries it took before network was up
	
	network_get_ipaddr ipaddr lan
	network_get_dnsserver dnsserver lan
	network_get_dnssearch dnssearch lan
	
	fqdn=$(nslookup $ipaddr $dnsserver | grep -A1 "Name: " | grep "Address 1: " | awk '{print $4}')
	hostname=$(echo $fqdn | cut -d"." -f1)
	domainname=$(echo $fqdn | cut -d"." -f2-)
	
	uci set system.@system[0].hostname=$hostname
	uci commit system
	
	echo $hostname > /proc/sys/kernel/hostname
	echo $domainname > /proc/sys/kernel/domainname
	
	echo "search $dnssearch" > /tmp/resolv.conf
	echo "nameserver $dnsserver" >> /tmp/resolv.conf
}
