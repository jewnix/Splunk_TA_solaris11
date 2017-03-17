#!/bin/bash  
. `dirname $0`/common.sh

FORMAT='{key = $1; if (NF == 1) {value = "<notAvailable>"} else {value = $2; for (i=3; i <= NF; i++) value = value " " $i}}'
PRINTF='{printf("%-20s  = \"%-s\"\n", key, value)}'

assertHaveCommandGivenPath /usr/sbin/prtdiag
assertHaveCommand mpstat
assertHaveCommand iostat
assertHaveCommand dmesg
assertHaveCommandGivenPath /usr/sbin/prtconf
assertHaveCommandGivenPath /usr/sbin/swap
assertHaveCommandGivenPath $GAWK
#PRODUCT=`uname -i | $AWK '{ n = split($0,a,","); if (n = 2) print a[2]; else print a[1]}'`
PRODUCT=`uname -i | $AWK '{ n = split($0,a,","); print a[n]}'`
if [ -z $PRODUCT ]; then # try another way; X86 perhaps?
	PRODUCT=`prtdiag | $AWK '/System Configuration:/ { FS=":"; print $2}'`
fi

# CPUs
# this won't be right if there is more than 1 CPU type. A couple of systems allow this e.g. M9000

if [ "$SOLARIS_10" -eq 1 ]; then
	CPU_INFO=`psrinfo -pv | nawk '/physical/{next}/x86/{mhz=$(NF-1);getline typ;print mhz ":" typ}!/x86/{mhz=$(NF-1); typ=$1;printf "%s:%s", mhz,typ;exit}'`
else
	CPU_INFO=`psrinfo -pv | nawk '/physical/{next}/virtual/{next}/x86/{mhz=$(NF-1);getline typ;print mhz ":" typ}!/x86/{mhz=$(NF-1); typ=$1;printf "%s:%s", mhz,typ;exit}'`
fi
cpu_mhz=`echo $CPU_INFO | $AWK '{split($0,a,":"); print a[1]}'`
CPU_TYPE=`echo $CPU_INFO | $AWK '{split($0,a,":"); print a[2]}'`

# may not be reported on all platforms
if [ "$SOLARIS_11" -eq 1 ]; then
	CPU_CACHE=`prtpicl -c cpu -v | grep cache-size | sort | uniq | $GAWK '{if ($2 ~ /0x/) {gsub($2, strtonum($2)); print $0;} else print $0}' | $AWK '/l1-dcache-size/ { L1=$2 } /l2-cache-size/ { L2=$2 } END { printf "L1:%s L2:%s", L1, L2}'`
else
	CPU_CACHE=`/usr/sbin/prtconf -v | $AWK 'function hexToDecKB (hex, digitsAll, idx, curDigit, dec) {sub("^value=", "", hex); for (idx=1; idx<=length(hex); idx++) {curDigit = index("0123456789abcdef", substr(hex,idx,1)); dec=(16*dec)+curDigit-1} if (debug) printf "hexToDec:%s->%d ", hex, dec; dec /= 1024; return dec} BEGIN {L2=L1i=L1d=0} (L2) {strL2=$1; L2=0} /l2-cache-size/ {L2=1} (L1i) {strL1i=$1; L1i=0} /l1-icache-size/ {L1i=1} (L1d) {strL1d=$1; L1d=0} /l1-dcache-size/ {L1d=1} END {if (debug) printf "strL2:%s strL1i:%s strL1d:%s ", strL2, strL1i, strL1d; nL2=hexToDecKB(strL2); nL1=hexToDecKB(strL1i)+hexToDecKB(strL1d); printf "L1:%dKB L2:%dKB", nL1, nL2}' debug=$DEBUG`
fi
CPU_COUNT=`mpstat -q | grep -cv CPU`
# # # that gives # of cores; `/usr/sbin/psrinfo -p` gives # of chips
# HDs
HARD_DRIVES=`echo | format | egrep c[0-9]+ | sed "s/<//"| $AWK '{ printf("%s:%s; ", $2, $3) }'`
# NICs
if [ "$SOLARIS_11" -eq 1 ]; then
	NIC_TYPE=`dladm show-phys -o LINK,DEVICE | egrep -v "DEVICE|vsw" | sort | $AWK '{printf "%s:%s; ", $1, $2}'`
else
	NIC_TYPE=`ifconfig -a | grep flags | grep -v lo | $AWK -F: '{nic_drv=substr($1,1,match($1,/[0-9]/)-1);printf "%s:%s\n", $1, nic_drv}'`
fi

NIC_COUNT=`echo $NIC_TYPE | wc -w`
# memory
MEMORY_REAL=`/usr/sbin/prtconf | awk '/^Memory size:/ {print $3 " MB"; exit}'`
MEMORY_SWAP=`/usr/sbin/swap -s | $AWK '{used=0+$(NF-3); free=0+$(NF-1); total=(used+free)/1024; print int(total) " MB"}'`

formatAndPrint ()
{
	echo $1 | awk "$FORMAT $PRINTF"
}

#formatAndPrint "KEY           VALUE"
formatAndPrint "PRODUCT       $PRODUCT" 
formatAndPrint "CPU_MHZ       $cpu_mhz" 
formatAndPrint "CPU_TYPE      $CPU_TYPE" 
formatAndPrint "CPU_CACHE     $CPU_CACHE" 
formatAndPrint "CPU_COUNT     $CPU_COUNT" 
formatAndPrint "HARD_DRIVES   $HARD_DRIVES"
formatAndPrint "NIC_TYPE      $NIC_TYPE"
formatAndPrint "NIC_COUNT     $NIC_COUNT"
formatAndPrint "MEMORY_REAL   $MEMORY_REAL" 
formatAndPrint "MEMORY_SWAP   $MEMORY_SWAP" 
