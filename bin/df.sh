#!/bin/sh

. `dirname $0`/common.sh

HEADER='Filesystem                                          Type              Size        Used       Avail      UsePct    MountedOn'
HEADERIZE='{if (NR==1) {$0 = header}}'
PRINTF='{printf "%-50s  %-10s  %10.f  %10.f  %10.f  %10s    %s\n", $1, type, size, used, avail, usePct, mountedOn, $7}'

assertHaveCommandGivenPath /usr/bin/df
CMD='eval /usr/bin/df -n ; /usr/bin/df -k'
FILTER_PRE='/dev/ {next}'
MAP_FS_TO_TYPE='/: / {fsTypes[$1] = $2; next}'
HEADERIZE='/^Filesystem/ {print header; next}'
BEGIN='BEGIN { FS = "[ \t]*:?[ \t]+" }'
FORMAT='{size=$2/1024; used=$3/1024; avail=$4/1024; sub("%","",$5);usePct=$5; mountedOn=$6; type=fsTypes[mountedOn]}'
FILTER_POST='(type ~ /^(devfs|ctfs|proc|mntfs|objfs|lofs|fd|sharefs)$/) {next} ($1 == "/proc") {next}'

$CMD | tee $TEE_DEST | $AWK "$BEGIN $HEADERIZE $FILTER_PRE $MAP_FS_TO_TYPE $FORMAT $FILTER_POST $NORMALIZE $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$BEGIN $HEADERIZE $FILTER_PRE $MAP_FS_TO_TYPE $FORMAT $FILTER_POST $NORMALIZE $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
