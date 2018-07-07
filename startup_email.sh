#! /bin/bash

# Copyright 2018 Joshua White
# Licensed under GNU Lesser GPL v3

# Originally written for Cygwin and bash
# Requires smartmontools

# TO DO: Rewrite to improve platform support

LOCALDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LOGFILE="${LOCALDIR}/startup_email.log"
ECONTENTS="${LOCALDIR}/startup_email.contents"
RECIPIENT="" # Email address for the RECIPIENT
SUBJECT="[hostname] has started up" # Email subject - change as required
ROUTE_TARGET="google.com" # Traceroute target - change as required

date >> ${LOGFILE}

# Get the external IP address
echo "Fetching external IP..." >> ${LOGFILE}
rm -f *.htm*
wget -q http://checkip.dyndns.org
echo '<html>
<body>
<p style="font-size: 12pt;"><b>External IP: ' >> ${ECONTENTS}

for f in *.htm*
do
	host=`tail $f | sed 's/</ /g' | sed 's/>//g' | awk '{print substr($11,1)}'`
	rm -f $f
done

echo $host >> ${ECONTENTS}
echo $host >> ${LOGFILE}

#whois $host >> attachment.txt

# Check the local network interfaces
echo '</b></p><br /><pre style="font-size: 10pt;"><hr /><b>Network Interfaces:</b><hr />' >> ${ECONTENTS}
ipconfig /all | grep -E 'Ethernet|Wireless|IP|Gateway' | grep -v 'Description' >> ${ECONTENTS}
echo '<br /><br /><hr /><b>Local Gateway and ISP Routers:</b><hr />' >> ${ECONTENTS}

# Check the path to a nearby network
echo "Checking network..." >> ${LOGFILE}
tracert -h 5 -d ${ROUTE_TARGET} | grep -v 'Trace' | grep -v 'hops' | grep -v "^$" >> ${ECONTENTS}

# Check local storage
echo '<br /><br /><hr /><b>Storage Space:</b><hr />' >> ${ECONTENTS}
df -h >> ${ECONTENTS}

# Check storage devices
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
echo '</pre></font>
</body>
</html>' >> ${ECONTENTS}

# Prepare the email
echo "Sending email..." >> ${LOGFILE}

# This line could be modified to use a different email script or utility
python ${LOCALDIR}/mailutils/mail.py -s ${SUBJECT} -r ${RECIPIENT} -l ${ECONTENTS} >> ${LOGFILE}

# Remove the email contents
rm -f ${ECONTENTS}

echo "Done.
" >> ${LOGFILE}
