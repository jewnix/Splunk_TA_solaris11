#!/usr/bin/bash
# zones.sh: find out global and n-g zone information for Solaris
# zone: zonename, global or not global

# tested on S11 CMT system, S11 LDOM, S11 VM
# not tested on S11 bare metal x86 install. YMMV.

. `dirname $0`/common.sh

GLOBAL=0
ZONES=0
if [ ! -x /usr/sbin/zonename ]; then
        # zone framework not installed; we must be global
	GLOBAL=1
else
	ZONES=1
	if [ `zonename` = global ]; then
		GLOBAL=1
	fi
fi

# only run on global zone and when the zone framework is installed
if [ "$ZONES" -eq 1 ]; then
	if [ "$GLOBAL" -eq 1 ];then
		zoneparent=`hostname`
		zones=$(zoneadm list -vc | egrep -v "NAME|global"| $AWK '{printf "%s %s:" ,$2, $3}')
		if [[ -n $zones ]]; then
			echo z_parent,z_name,z_hostname,z_state
			while read -ed: zone_name zstate; do
				if [ "$zstate" = "running" ]; then
					# this contortion required by bad
					# behaviour of zlogin in loops
					coproc zlogin $zone_name uname -n
					read -u ${COPROC[0]} z_hostname
					echo $zoneparent,$zone_name,$z_hostname,$zstate
				else
					echo $zoneparent,$zone_name,N/A,$zstate
			fi
			done <<< $(echo $zones)
		fi
	fi
fi
