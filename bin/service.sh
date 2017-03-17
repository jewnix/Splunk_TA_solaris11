#!/bin/sh

. `dirname $0`/common.sh

# In AWK scripts in this file, the following are true:
# 	FULLTEXT is used to capture the output for SHA1 checksum generation.
# 	SPLUNKD is used to determine Splunk service status.

if [ "x$KERNEL" = "xSunOS" ] ; then
	printf "%s,%s,%s,%s\n" APP STARTMODE STARTNAME STATE
	assertHaveCommand date
	assertHaveCommand svcs
	
	CMD='svcs -H -a -o STATE,FMRI'
	
	#PARSE_0='NR==1 {DATE=$0 ; FULLTEXT=""}'
	PARSE_1='NR>1 {
		STATE="\""$1"\""
		idx=index($2,":")
		STARTNAME="\""substr($2,0,idx-1)"\""
		APP="\""substr($2,idx+1)"\""
		FULLTEXT=FULLTEXT $0 "\n"
	}'
	PARSE_2='/^legacy_run/ {
		STARTMODE="\"Auto\""
	}'
	PARSE_3='/^online/ {
		STARTMODE="\"Auto\""
		STATE="\"Running\""
	}'
	PARSE_4='/^disabled/ {
		STARTMODE="\"Disabled\""
		STATE="\"Stopped\""
	}'
	
	INLINE_PRINT='NR>1 && APP!=0 {printf "%s,%s,%s,%s\n", APP, STARTMODE, STARTNAME, STATE}'

	MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3 $PARSE_4 $INLINE_PRINT"

	# Send the collected full text to openssl; this avoids any timing discrepancies 
	# between when the information is collected and when we process it.
	POSTPROCESS='END { 
		if (SPLUNKD==0) #{ printf "%s \"Splunk\" Disabled\n"}
		printf "%s", "file_hash="
		printf "%s", FULLTEXT | "LD_LIBRARY_PATH=$SPLUNK_HOME/lib $SPLUNK_HOME/bin/openssl sha1"
	}'

elif [ "x$KERNEL" = "xDarwin" ] ; then

	assertHaveCommand date
	assertHaveCommand defaults
	assertHaveCommand dscl
	assertHaveCommand find
	assertHaveCommand ls

	# Get startup items
	CMD='eval date ; ls -1 /System/Library/StartupItems/ /Library/StartupItems/'
	# Get per-user startup items
	for PLIST_FILE in `find /Users -name "loginwindow.plist"` ; do
		CMD=$CMD' ; echo '$PLIST_FILE': ; defaults read '$PLIST_FILE
	done

	PARSE_0='NR==1 {DATE=$0}'
	# Retrieve path for system startup items
	PARSE_1='/^\/(System|Library)/ {
		split($0, tmparr, ":")
		PATH="file_path=\""tmparr[1]
		USER=0
		START_MODE="StartMode=Auto"
		START_TYPE="StartType=startup"
	}'
	
	# Retrieve user information for user startup items. 
	PARSE_2='/^\/Users/ {
		split($0, tmparr, "/")
		USER="user=" tmparr[3]
		START_MODE="StartMode=Auto"
		START_TYPE="StartType=login"
	}'
	
	# Retrieve the path for user startup items.
	PARSE_3='/[[:blank:]]*Path/ {
		split($0, path_arr, "=")
		num=split(path_arr[2], app_arr, "/")
		split(app_arr[num], app_final, ".")
		split(path_arr[2], path_final, "\"")
		APP="app=\"" app_final[1] "\""
		FILE_PATH="file_path=\"" path_final[2] "\""
		
		# Only print if we find a path.
		printf "%s %s %s %s %s %s\n", DATE, APP, START_MODE, START_TYPE, FILE_PATH, USER
		
		# Note that we found splunkd if app matches
		if (APP ~ /[Ss][Pp][Ll][Uu][Nn][Kk]/) { SPLUNKD=1 }
	}'
	
	# Retrieve the system startup item name from the output of "ls -1"
	PARSE_4='/^[^\/]/ {
		if (NR>1 && USER==0 && NF > 0) {
			APP="app=\""$0"\""
			PATH=PATH$0"\""
			printf "%s %s %s %s %s\n", DATE, APP, START_MODE, START_TYPE, PATH
		}
		
		# Note that we found splunkd if app matches
		if (APP ~ /[Ss][Pp][Ll][Uu][Nn][Kk]/) { SPLUNKD=1 }

	}'
		
	MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3 $PARSE_4"

	POSTPROCESS='END { if (SPLUNKD==0) { printf "%s app=\"Splunk\" StartMode=Disabled\n", DATE } }'

else
	# Exits
	failUnsupportedScript
fi

$CMD | tee $TEE_DEST | $AWK "$MASSAGE $POSTPROCESS"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $POSTPROCESS'" >> $TEE_DEST
