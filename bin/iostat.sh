#!/bin/sh                                                                                                

. `dirname $0`/common.sh

HEADER='Device          rReq_PS      wReq_PS        rKB_PS        wKB_PS  avgWaitMillis   avgSvcMillis   bandwUtilPct'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-10s  %11s  %11s  %12s  %12s  %13s  %13s  %13s\n", device, rReq_PS, wReq_PS, rKB_PS, wKB_PS, avgWaitMillis, avgSvcMillis, bandwUtilPct}'

if [ "x$KERNEL" = "xSunOS" ] ; then
	CMD='iostat -xn 1 2'
	assertHaveCommand $CMD
	FILTER='/[)(]|device statistics/ {next} /device/ {reportOrd++; next} (reportOrd==1) {next}'
	FORMAT='{device=$NF; rReq_PS=$1; wReq_PS=$2; rKB_PS=$3; wKB_PS=$4; avgWaitMillis=$7; avgSvcMillis=$8; bandwUtilPct=$10}'
fi

$CMD | tee $TEE_DEST | awk "$HEADERIZE $FILTER $FORMAT $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | awk '$HEADERIZE $FILTER $FORMAT $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
