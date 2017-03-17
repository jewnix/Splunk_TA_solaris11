#!/usr/bin/bash                                                                                                
. `dirname $0`/common.sh

HEADER='NAME,VERSION,RELEASE,ARCH,VENDOR,GROUP'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "\"%s\",%s,%s,%s,%s,%s\n", name, version, release, arch, vendor, group}'

CMD="eval pkginfo -l `pkginfo | $AWK '{print $2}'`"
FORMAT='/PKGINST:/ {name=$2 ":"} /NAME:/ {for (i=2;i<=NF;i++) name = name " " $i} /CATEGORY:/ {group=$2} /ARCH:/ {arch=$2} /VERSION:/ {split($2,a,",REV="); version=a[1]; release=a[2]} /VENDOR:/ {vendor=$2; for(i=3;i<=NF;i++) vendor = vendor " " $i}'
SEPARATE_RECORDS='!/^$/ {next} {release = release ? release : "?"}'

assertHaveCommand $CMD
$CMD | tee $TEE_DEST | $AWK "$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
