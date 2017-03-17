#!/usr/bin/bash

. `dirname $0`/common.sh

GLOBAL=0
if [ ! -x /usr/sbin/zonename ]; then
	# zones framework may not be installed; we are global
	GLOBAL=1
else
	if [ `zonename` = global ]; then
		GLOBAL=1
	fi
fi

printf "%s,%s,%s\n" link state device 

if [ "$GLOBAL" -eq 1 ]; then
	if [ "$SOLARIS_10" -eq 1 ]; then
		dladm show-dev | $AWK '{printf "%s,%s,%s\n", $1, $3, $1}'
	else
		dladm show-phys -p -o LINK,STATE,DEVICE | grep -v lo | $AWK -F: '{printf "%s,%s,%s\n", $1, $2, $3}'
	fi
else
	# no physical hardware
	echo "NA,NA,NA"
fi
