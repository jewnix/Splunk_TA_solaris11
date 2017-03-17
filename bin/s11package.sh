#!/usr/bin/bash

. `dirname $0`/common.sh
LD_LIBRARY_PATH=
LD_LIBRARY_PATH_64=
PYTHONPATH=

ARCH=`uname -m`
HEADER='NAME,VERSION,RELEASE,ARCH,VENDOR,GROUP'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "\"%s\",%s,%s,%s,%s,%s\n", name, version, release, arch, vendor, group}'
CMD='pkg info'
FORMAT='/Name:/ {name=$2 ":"} /Summary:/ {for (i=2;i<=NF;i++) name = name " " $i} /Category:/ {group=$2} /Version:/ {split($2,a,"("); version=a[1]}; /Branch:/ {release=$2}; /Publisher:/ {vendor=$2; for(i=3;i<=NF;i++) vendor = vendor " " $i}'
SEPARATE_RECORDS='!/^$/ {next} {release = release ? release : "?"}'
assertHaveCommand $CMD
$CMD | tee $TEE_DEST | $AWK -v arch=$ARCH "$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
