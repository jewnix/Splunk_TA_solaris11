#!/usr/bin/bash

. `dirname $0`/common.sh

PASSWD_FILE=/etc/passwd

printf "%s,%s,%s,%s,%s\n" user uid gid home shell
if [ "x$KERNEL" = "xLinux" -o "x$KERNEL" = "xSunOS" -o "x$KERNEL" = "xAIX" -o "x$KERNEL" != "xHP-UX" -o "x$KERNEL" = "xDarwin" -o "x$KERNEL" = "xFreeBSD" ] ; then
    CMD='eval cat $PASSWD_FILE'

	# Note the inline print in the next PARSE statement.
	# Comments are eliminated from the output, but included in FILEHASH.
	PARSE_2='/^[^#]/ { split($0, arr, ":") ; printf "%s,%s,%s,%s,\"%s\"\n", arr[1], arr[3], arr[4], arr[6], arr[7]}'

	MASSAGE="$PARSE_2"

fi

$CMD | tee $TEE_DEST | $AWK "$MASSAGE $PRINTF"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $PRINTF'" >> $TEE_DEST
