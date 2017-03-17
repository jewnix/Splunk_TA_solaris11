#!/usr/bin/bash
# ldoms.sh: if we are a control domain, show guests
# if we are a guest ldom, show parent

# tested on S11 CMT system, S11 LDOM, S11 VM, S11 zone

. `dirname $0`/common.sh

SPARC=0
GLOBAL=0

if [ `uname -p` = sparc ]; then
	SPARC=1
fi
if  [ ! -x /usr/sbin/zonename ]; then
	# no zones; we are global
	GLOBAL=1
else
	if [ `zonename` = global ]; then
		GLOBAL=1
	fi
fi

# check that running this makes any sense here
# no message, we don't want to log anything if not
if [ "$GLOBAL" -eq 0 -o "$SPARC" -eq 0 ]; then
	exit 0
fi

if [ -x /usr/sbin/virtinfo ];then

	print l_parent,l_name,l_control,l_io,l_service,l_root,l_guest,l_hostname,l_console,l_state

	l_hostname=`hostname`

	# get info for this node

	/usr/sbin/virtinfo -a | $AWK -F: -v control=0 -v io=0 -v service=0 -v root=0 -v guest=0 -v parent -v name -v host=$l_hostname '
	/Control domain/ {gsub(/ /,"", $2);parent=$2} 
	/name/ {gsub(/ /,"",$2); lname=$2} 
	/control/ {control=1} 
	/I\/O/ {io=1} 
	/service/ {service=1} 
	/root/ {root=1} 
	/guest/ {guest=1} 
	END { printf "%s,%s,%s,%s,%s,%s,%s,%s,console,active\n", parent,lname,control,io,service,root,guest,host}'

	# if primary, get info for guests
	# active guests will be reporting themselves as well

	LDROLE=`/usr/sbin/virtinfo -a | $AWK '/name/ {print $3}'`
	if [ $LDROLE == "primary" ]; then
		read -a guestinfo <<< $(ldm ls | egrep -v "NAME|primary"| $AWK '{printf "%s %s %s:", $1,$2,$4}')
		if [[ -n $guestinfo ]];then
		while read -ed: ldom_name state console ; do
			if [ "$state" = "active" ]; then
				script_path=`dirname $0`
				g_hostname=`$script_path/ldom_hostname.py $console`
				printf "%s,%s,0,0,0,0,1,%s,%s,%s\n" $l_hostname $ldom_name $g_hostname $console $state
			else
				printf "%s,%s,0,0,0,0,1,n/a,n/a,%s\n" $l_hostname $ldom_name $state
			fi
		done  <<< $(echo "${guestinfo[*]}" )
		fi
	fi
fi
