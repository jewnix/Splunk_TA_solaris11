#!/bin/sh  
. `dirname $0`/common.sh

LD_LIBRARY_PATH=
LD_LIBRARY_PATH_64=
PYTHONPATH=

PRINTF='END {printf "%s %s %s %s %s %s\n", MACH_HW_NAME, MACH_ARCH_NAME, OS_REL, OS_NAME, OS_VER, SRU}'

if [ "$SOLARIS_11" -eq 1 ]; then
	SRU=`pkg info entire | $AWK -F: '/Branch/ {print $2}'`
	PARSE_2='NR==2 {OS_REL="os_release=\"" $0 "\""}'
	PARSE_4='NR==4 {OS_VER="os_version=\"" $0 "\""}'
else
	SRU=`awk '{printf "%s\n", $5; exit}' /etc/release`
	PARSE_2='NR==2 {OS_REL="os_release=\"" $0 "\""}'
	PARSE_4='NR==4 {OS_VER="os_version=\"" $0 "\""}'
fi
CMD='eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v; eval uname -p; eval echo $SRU'

# Get the date.
PARSE_1='NR==1 {MACH_HW_NAME="machine_hardware_name=\"" $0 "\""}'
PARSE_3='NR==3 {OS_NAME="os_name=\"" $0 "\""}'
PARSE_5='NR==5 {MACH_ARCH_NAME="machine_architecture_name=\"" $0 "\""}'
PARSE_6='NR==6 {SRU="sru=\"" $0 "\""}'
MASSAGE="$PARSE_1 $PARSE_2 $PARSE_3 $PARSE_4 $PARSE_5 $PARSE_6"
$CMD | tee $TEE_DEST | $AWK "$MASSAGE $PRINTF"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $PRINTF'" >> $TEE_DEST
