#!/bin/sh

. `dirname $0`/common.sh

printf "%s,%s,%s\n" user src_host latest_time
PRINTF='{printf "%s,%s,%s\n", username, from, latest}'

CMD='last -n 999'
FILTER='{if ($0 == "") exit; if ($1 ~ /reboot|shutdown/ || $1 in users) next; users[$1]=1}'
FORMAT='{username = $1; from = (NF==10) ? $3 : "<console>"; latest = $(NF-6) " " $(NF-5) " " $(NF-4) " " $(NF-3)}'

$CMD | tee $TEE_DEST | $AWK "$FILTER $FORMAT $PRINTF" 
#echo Cmd = [$CMD];  | $AWK '$FILTER $FORMAT $PRINTF'" >> $TEE_DEST
