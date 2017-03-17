#!/bin/sh 

. `dirname $0`/common.sh

# In AWK scripts in this file, the following are true:
# 	FULLTEXT is used to capture the output for SHA1 checksum generation.
# 	SPLUNKD is used to determine Splunk service status.

if [ "x$KERNEL" = "xSunOS" ] ; then

	printf "%s,%s,%s,%s\n" DESTIP DESTPORT IPVERSION TRANSPORT
	assertHaveCommand date
	assertHaveCommand netstat
	
	CMD='netstat -an -f inet -f inet6'
	
	#PARSE_0='NR==1 {DATE=$0 ; FULLTEXT=""}'
	PARSE_1='/^[Tt][Cc][Pp]|[Uu][Dd][Pp]/ {
                split($0, protoarr, ":")
                TRANSPORT=protoarr[1]
                IPVERSION=substr(protoarr[2],index(protoarr[2],"v")+1)
                next
        }'

	PARSE_3='NR>1 && $0 !~ /Local|^-|^$/ {
		FULLTEXT = FULLTEXT $0 "\n"
		split($0, arr)
		num = split(arr[1], hostarr, "\.")
		if ( TRANSPORT ~ /[Tt][Cc][Pp]/) {
			DESTIP=hostarr[1]
		} else {
			DESTIP=hostarr[1]
		}
		DESTPORT=hostarr[num]

		for (i=2; i<num; i++) {
			DESTIP=DESTIP"."hostarr[i]
		}
		if ( $0 !~ /[Uu][Nn][Bb][Oo][Uu][Nn][Dd]/ && DESTPORT != "*" ) {
			DESTPORT=DESTPORT
			printf "%s,%s,%s,%s \n", DESTIP, DESTPORT, IPVERSION, TRANSPORT
		}
	}'
	
	MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3"

	# Send the collected full text to openssl; this avoids any timing discrepancies
	# between when the information is collected and when we process it.
	POSTPROCESS='END {
		printf "%s %s", DATE, "file_hash="
		printf "%s", FULLTEXT | "LD_LIBRARY_PATH=$SPLUNK_HOME/lib $SPLUNK_HOME/bin/openssl sha1"
	}'

else
	# Exits
	failUnsupportedScript
fi

$CMD | tee $TEE_DEST | $AWK "$MASSAGE $POSTPROCESS"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $POSTPROCESS'" >> $TEE_DEST
