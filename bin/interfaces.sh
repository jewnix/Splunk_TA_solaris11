#!/usr/bin/bash

. `dirname $0`/common.sh

if [ "$SOLARIS_10" -eq 1 ]; then
	. `dirname $0`/interfaces10.sh
	exit 0
fi

GLOBAL=0
if [ ! -x /usr/sbin/zonename ]; then
	# zone framework not installed; we must be global
	# therefore have access to dlstat
	GLOBAL=1
else
	if [ `zonename` = global ]; then
		GLOBAL=1
	fi
fi
	
CMD_LIST_INTERFACES="eval ipadm show-addr -p -o ADDROBJ | grep -v lo | $AWK -F: '{print $1}'"

#printf "%-20s %-17s  %-18s  %-39s %-10s  %-16s %-16s %-6s %-6s %-6s \n" Name MAC inetAddr inet6Addr Collisions RXbytes TXbytes Speed Duplex vlan_id
print Name,MAC,inetAddr,inet6Addr,Collisions,RXbytes,TXbytes,Speed,Duplex,vlan_id

for iface in `$CMD_LIST_INTERFACES`
do
	name=`echo $iface | sed -e 's/\/v.*//' -e 's/\/zone.*//' -e 's/\/\?//'`
	if [ "$GLOBAL" -eq 0 ]; then
		# can't run dladm in zone
		mac="n/a"
		SD="/n/a:n/a"
		vlan_id="n/a"
		IBOB="n/a:n/a"
		collisions="n/a"
		ADDRESS=`ipadm show-addr -p -o ADDR $name`
	else
		class=`dladm show-link -p -o CLASS $name`
		case $class in
			phys)
				mac=`dladm show-phys -p -m -o ADDRESS $name`
				SD=`dladm show-phys -p -o SPEED,DUPLEX $name`
				vlan_id=1
			;;
			vnic)
				mac=`dladm show-vnic -p -o MACADDRESS $name`
				SD=`dladm show-vnic -p -o SPEED $name`
				SD=`printf "%s%s" $SD ":n/a"`
				vlan_id=1
			;;
			aggr)
				mac=`dladm show-aggr -x -p -o ADDRESS $name | $AWK '{print $1;exit}'`
				SD=`dladm show-aggr -x -p -o SPEED,DUPLEX $name | $AWK '{print $1;exit}'`
				vlan_id=1
				;;
			vlan)
				mac="n/a"
				vlan_id=`dladm show-vlan -p -o VID $name | $AWK '{print $1;exit}'`
				SD="n/a:n/a"
				;;
			*)
				mac="n/a"
				SD="n/a:n/a"
				;;
		esac
		IBOB=`dlstat show-link -p -o  RBYTES,OBYTES $name`
		collisions=`netstat -faf:inet -i -I net0 | nawk '/Name/ {next} {print $9}'`
		ADDRESS=`ipadm show-addr -p -o ADDR $iface`
	fi
	if [[ $ADDRESS =~ .*:.* ]]; then # v6
		IPv4="n/a"
		IPv6=$ADDRESS
	else
		IPv4=$ADDRESS
		IPv6="n/a"
	fi
	speed=`echo $SD | $AWK -F: '{print $1}'`
	duplex=`echo $SD | $AWK -F: '{print $2}'`
	RXbytes=`echo $IBOB | $AWK -F: '{print $1}'`
	TXbytes=`echo $IBOB | $AWK -F: '{print $2}'`
	printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" $iface $mac $IPv4 $IPv6 $collisions,$RXbytes,$TXbytes,$speed $duplex $vlan_id 
done
