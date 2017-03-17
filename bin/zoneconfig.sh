#!/usr/bin/bash
# ldconfig.sh: if we are a control domain, show guests configuration

. `dirname $0`/common.sh

GLOBAL=0
ZONES=0
if  [ ! -x /usr/sbin/zonename ]; then
	# no zones; we are global
	GLOBAL=1
else
	ZONES=1
	if [ `zonename` = global ]; then
		GLOBAL=1
	fi
fi

if [ "$ZONES" -eq 1 -a "$GLOBAL" -eq 1 ]; then
	zonelist=`zoneadm list -vc | egrep -v "NAME|global" |$AWK '{print $2}'`
	if [[ -n "$zonelist" ]]; then
		echo zone_name,zonepath,net_address,net_dev,def_router
		for z in $zonelist; do
			zonecfg -z $z info | $AWK '
				/zonename/ {printf "%s,", $2}
				/zonepath/ {printf "%s,", $2}
				/	address/ {printf "%s,", $2}
				/physical/ {printf "%s,", $2}
				/defrouter/ {printf "%s", $2}
			'
			echo
		done
	fi
fi
