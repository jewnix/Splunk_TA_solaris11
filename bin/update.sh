#!/bin/sh                                                                                                

. `dirname $0`/common.sh

LD_LIBRARY_PATH=
LD_LIBRARY_PATH_64=
PYTHONPATH=

echo "pkg_date,pkg_command,pkg_action,pkg_oper,pkg_args,result" 

if [ "$SOLARIS_11" -eq 1 ] ; then
	assertHaveCommand pkg
	#solaris 11 pkg format
	CMD='eval pkg history -H -o finish,outcome,operation,command'
	
	PARSE_1='BEGIN {inst=0}
		/auto-install/{
		inst++
		if (inst == 1) {
		sub(/T/," ",$1)
		PKG_DATE=$1
		OUTCOME=$2
		ACTION="Initial Installation"
		COMMAND="auto-install"
		OPERATION="install"
		ARGS="n/a"
		printf "\"%s\",\"%s\",%s,%s,%s,%s\n", PKG_DATE, COMMAND, ACTION, OPERATION, ARGS,OUTCOME}
		else  next
		}'
	PARSE_0='!/auto-install/{
		sub(/T/," ",$1)
		PKG_DATE=$1
		OUTCOME=$2
		OPERATION=$3
		COMMAND=$4
		ACTION=$5
		ARGS=$6
		printf "\"%s\",%s,%s,%s,\"%s\",%s\n", PKG_DATE, COMMAND, ACTION,OPERATION, ARGS,OUTCOME
	}'


	MASSAGE="$PARSE_1 $PARSE_0"
	$CMD | tee $TEE_DEST | $AWK "$MASSAGE"
	echo "Cmd = [$CMD];  | $AWK '$MASSAGE'" >> $TEE_DEST

fi


#legacy packages 
CMD1="eval pkginfo -l `pkginfo | grep -v SUNW |$AWK '{print $2}'`"
FORMAT='/PKGINST:/ {ARGS=$2;COMMAND="legacy/pkgadd";ACTION="install";OPERATION="install"} /INSTDATE:/ {sub(/INSTDATE: */,"",$0);"gdate \"+%F %H:%M:%S\" -d \""$0"\""|getline PKG_DATE} /STATUS:/ {if ($0 ~ /completely/ ? OUTCOME="Succeeded":OUTCOME="Failed")}'
SEPARATE_RECORDS='!/^$/ {next} {release = release ? release : "?"}'
PRINTF='{printf "\"%s\",%s,%s,%s,\"%s\",%s\n", PKG_DATE, COMMAND, ACTION, OPERATION,ARGS,OUTCOME}'

$CMD1 | $AWK "$FORMAT $SEPARATE_RECORDS $PRINTF"
