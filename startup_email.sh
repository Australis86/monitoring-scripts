#! /bin/bash

# Copyright 2018 Joshua White
# Licensed under GNU Lesser GPL v3

# Originally written for Cygwin and bash
# Some functionality dependent on smartmontools

# TO DO: Rewrite to improve platform support

LOCALDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LOGFILE="${LOCALDIR}/startup_email.log" # Log file
ECONTENTS="${LOCALDIR}/startup_email.contents" # Temporary file for email contents
RECIPIENT=$1 # Email address for the recipient (default is command line argument)
HOSTNAME=`hostname -f` # Get the FQDN (alternatively, enter a hostname)
SUBJECT=`echo "${HOSTNAME} has started up"` # Email subject - change as required
ROUTE_TARGET="google.com" # Traceroute target - change as required

date >> ${LOGFILE}

# Email header
echo '<html>
<body>' >> ${ECONTENTS}

# Get the external IP address
echo "Fetching external IP..." >> ${LOGFILE}
wget -q http://checkip.dyndns.org -O checkip_results.html

# Add the external IP address to the email contents
echo '<p style="font-size: 12pt;"><b>External IP: ' >> ${ECONTENTS}
host=`tail checkip_results.html | sed 's/</ /g' | sed 's/>//g' | awk '{print substr($11,1)}'`
echo $host >> ${ECONTENTS}
echo $host >> ${LOGFILE}
rm -f checkip_results.html

#if [ -x "$(command -v whois)" ]; then
#	whois $host >> attachment.txt
#fi

# Check the local network interfaces
echo '</b></p><br /><pre style="font-size: 10pt;"><hr /><b>Network Interfaces:</b><hr />' >> ${ECONTENTS}

if [ -x "$(command -v ipconfig)" ]; then
	# Windows/Cygwin
	ipconfig /all | grep -E 'Ethernet|Wireless|IP|Gateway' | grep -v 'Description' >> ${ECONTENTS}
elif [ -x "$(command -v ifconfig)" ]; then
	# Linux
	ifconfig | grep -E 'flags|inet|ether|loop' >> ${ECONTENTS}
elif [ -x "$(command -v /sbin/ifconfig)" ]; then
	# Linux
	/sbin/ifconfig | grep -E 'flags|inet|ether|loop' >> ${ECONTENTS}
else
	echo "No tool for querying network interfaces available." >> ${LOGFILE}
fi

# Check the route to a nearby network
echo '<br /><br /><hr /><b>Local Gateway and ISP Routers:</b><hr />' >> ${ECONTENTS}

# Check the path to a nearby network
echo "Checking network..." >> ${LOGFILE}

if [ -x "$(command -v tracert)" ]; then
	# Windows/Cygwin
	tracert -h 5 -d ${ROUTE_TARGET} | grep -v 'Trace' | grep -v 'hops' | grep -v "^$" >> ${ECONTENTS}
elif [ -x "$(command -v traceroute)" ]; then
	# Linux
	traceroute -m 5 -d ${ROUTE_TARGET} | grep -v 'Trace' | grep -v 'hops' | grep -v "^$" >> ${ECONTENTS}
else
	echo "No trace route programme available." >> ${LOGFILE}
fi

# Check local storage
echo '<br /><br /><hr /><b>Storage Space:</b><hr />' >> ${ECONTENTS}
df -h >> ${ECONTENTS}

# Check storage devices
if [ -x "$(command -v /usr/sbin/smartctl)" ]; then
	echo "Scanning storage devices..." >> ${LOGFILE}
	echo '<br /><br /><hr /><b>Storage Device Listing:</b><hr />' >> ${ECONTENTS}

	/usr/sbin/smartctl --scan-open >> ${ECONTENTS}
	for d in /dev/sd[a-z]
	do
		echo "<br /><b>"$d"</b><br />" >> ${ECONTENTS}
		/usr/sbin/smartctl -i $d | grep -E "Model|Capacity" | awk '{sub(/^/, "\t")};1' >> ${ECONTENTS}
		echo " " >> ${ECONTENTS}
		/usr/sbin/smartctl -H $d | grep -v "cygwin" | grep -v "==" | grep -v "Copyright" | grep -v "^$" | awk '{sub(/^/, "\t")};1' >> ${ECONTENTS}
		/usr/sbin/smartctl -a $d | grep -E "Retired_Block|Reallocated_Sector|Power_|Temperature|Pending|Uncorrectable" | awk '{print "\t" $10 "\t " $2}' | sed 's/_/ /g' | sed 's/Ct/Count/g' >> ${ECONTENTS}
	done
fi

# Footer of email
echo '</pre></font>
</body>
</html>' >> ${ECONTENTS}

# Prepare the email
echo "Sending email..." >> ${LOGFILE}

# This line could be modified to use a different email script or utility
python ${LOCALDIR}/mailutils/mail.py -s "${SUBJECT}" -r ${RECIPIENT} -l ${ECONTENTS} >> ${LOGFILE}
mailresult=$?

if [ $mailresult -eq 0 ]; then
	# Remove the email contents
	rm -f ${ECONTENTS}

	echo "Successfully sent email to ${RECIPIENT}" >> ${LOGFILE}
else
	echo "Error sending email to  ${RECIPIENT}" >> ${LOGFILE}
fi

# Add a blank line at the end of the log file entry
echo >> ${LOGFILE}
