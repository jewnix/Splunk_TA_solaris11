#!/bin/sh

. `dirname $0`/common.sh

if [ -f    /etc/ntp.conf ] ; then         # Linux; FreeBSD; AIX; Mac OS X maybe
	CONFIG=/etc/ntp.conf
elif [ -f  /etc/inet/ntp.conf ] ; then    # Solaris
	CONFIG=/etc/inet/ntp.conf
elif [ -f  /private/etc/ntp.conf ] ; then # Mac OS X
	CONFIG=/private/etc/ntp.conf
else
	CONFIG=
fi

SERVER_DEFAULT='0.pool.ntp.org'
if [ "x$CONFIG" = "x" ] ; then
	SERVER=$SERVER_DEFAULT
else
	SERVER=`$AWK '/^server / {print $2; exit}' $CONFIG`
	SERVER=${SERVER:-$SERVER_DEFAULT}
fi

STATUS=`svcs -H ntp | $AWK '{print $1}'`
PEER=`xntpdc -l | $AWK '{print $2}'`
if [ -z $PEER ]; then 
	PEER="Communication Error"
fi

echo server,status,peer
echo $SERVER, $STATUS, $PEER

