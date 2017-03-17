#!/bin/bash                                                

. `dirname $0`/common.sh

HEADER='CPU    pctUser    pctNice  pctSystem  pctIowait    pctIdle'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-3s  %9s  %9s  %9s  %9s  %9s\n", cpu, pctUser, pctNice, pctSystem, pctIowait, pctIdle}'

if [ "$SOLARIS_11" -eq 1 ]; then
	CMD='eval mpstat -q -p 1 2|tail -1; mpstat -m -A 1 -q -p 1 2 |tail -1| sed "s/^[ ]*0/all/"'
else
	 CMD='eval mpstat -q -p 1 1; mpstat -aq -p 1 1 | tail -1 | sed "s/^[ ]*0/all/"'
fi
assertHaveCommand $CMD
FILTER='(NR<2) {next}'
FORMAT='{cpu=$1; pctUser=$(NF-4); pctNice="0"; pctSystem=$(NF-3); pctIowait=$(NF-2); pctIdle=$(NF-1)}'

$CMD | tee $TEE_DEST | $AWK "$HEADERIZE $FILTER $FORMAT $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
