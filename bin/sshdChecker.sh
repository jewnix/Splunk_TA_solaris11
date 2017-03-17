#!/bin/sh

. `dirname $0`/common.sh

SSH_CONFIG_FILE=""
if [ \( "x$KERNEL" = "xLinux" -o "x$KERNEL" = "xSunOS" \) ] ; then
	SSH_CONFIG_FILE=/etc/ssh/sshd_config
elif [ "x$KERNEL" = "xDarwin" ] ; then
	SSH_CONFIG_FILE=/etc/sshd_config
else
	failUnsupportedScript
fi

FILL_BLANKS='END {
	if (SSHD_PROTOCOL == 0) {
		SSHD_PROTOCOL=SSHD_DEFAULT_PROTOCOL
	}'

printf "%s,%s,%s\n" APP FILEHASH SSHD_PROTOCOL
PRINTF='{printf "sshd,%s,%s\n", FILEHASH, SSHD_PROTOCOL}}'

if [ "$SOLARIS_11" -eq 0 ] ; then

	if [ -f "$SSH_CONFIG_FILE" -a -r "$SSH_CONFIG_FILE" ] ; then
	
		assertHaveCommand cat
	
		# Get file hash
		CMD='eval date ; eval LD_LIBRARY_PATH=$SPLUNK_HOME/lib $SPLUNK_HOME/bin/openssl sha1 $SSH_CONFIG_FILE ; cat $SSH_CONFIG_FILE'
	
		# Get the date.
		PARSE_0='NR==1 {DATE=$0}'
		
		# Try to use cross-platform case-insensitive matching for text. Note
		# that "match", "tolower", IGNORECASE and other common awk commands or
		# options are actually nawk/gawk extensions so avoid them if possible.
		PARSE_1='/^[Pp][Rr][Oo][Tt][Oo][Cc][Oo][Ll]/ { 
			split($0, arr)
			num = split(arr[2], protocols, ",")
			if (num == 2) {
				SSHD_PROTOCOL=protocols[1] "/" protocols[2]
			} else {
				SSHD_PROTOCOL=protocols[1]
			}
		}'
		PARSE_2='/^#[[:blank:]]*[Pp][Rr][Oo][Tt][Oo][Cc][Oo][Ll]/ { 
			num=split($0, arr)
			protonum = split(arr[num], protocols, ",")
			if (protonum == 2) {
				SSHD_DEFAULT_PROTOCOL=protocols[1] "/" protocols[2]
			} else {
				SSHD_DEFAULT_PROTOCOL=protocols[1]
			}
		}'
		PARSE_3='/^SHA1/ {FILEHASH=$2}'
	
		MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3"
		
	else
		echo "SSHD configuration (file: $SSHD_CONFIG_FILE) missing or unreadable." >> $TEE_DEST
		exit 1
	fi
	
else

	if [ -f "$SSH_CONFIG_FILE" -a -r "$SSH_CONFIG_FILE" ] ; then

		# Solaris 11 only supports SSH protocol 2.		
		assertHaveCommand cat
	
		# Get file hash
		CMD='eval date ; eval LD_LIBRARY_PATH=$SPLUNK_HOME/lib $SPLUNK_HOME/bin/openssl sha1 $SSH_CONFIG_FILE'
	
		PARSE_0='NR==1 {DATE=$0 ; SSHD_PROTOCOL=2}'
		PARSE_1='/^SHA1/ {FILEHASH=$2}'
	
		MASSAGE="$PARSE_0 $PARSE_1"
	
	else
		echo "SSHD configuration (file: $SSHD_CONFIG_FILE) missing or unreadable." >> $TEE_DEST
		exit 1
	fi
	
fi
	
$CMD | tee $TEE_DEST | $AWK "$MASSAGE $FILL_BLANKS $PRINTF"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $FILL_BLANKS $PRINTF'" >> $TEE_DEST
