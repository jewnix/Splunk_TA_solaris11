#!/usr/bin/bash
# ldconfig.sh: if we are a control domain, show guests configuration

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

if [ x$KERNEL == "xSunOS" ]; then
	# check that running this makes any sense here
	# no message, we don't want to log anything if not
	if [ "$GLOBAL" -eq 0 -o "$SPARC" -eq 0 ]; then
		exit 0
	fi
	if [ -x /usr/sbin/virtinfo ]; then
		LDROLE=`/usr/sbin/virtinfo -a | $AWK '/name/ {print $3}'`
		#only primary knows about the other guests
		if [ $LDROLE == "primary" ]; then
			echo ldom_name,state,ncpu,mem,memunit
			ldm ls -p | $AWK '/DOMAIN/ {
				FS="|"; sub(/name=/,""); sub(/state=/,""); sub(/ncpu=/,""); sub(/mem=/,"") ;printf "%s,%s,%s,%s,b\n", $2,$3,$6,$7
			}'
		fi
	fi
fi
