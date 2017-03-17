#!/usr/bin/bash

. `dirname $0`/common.sh
echo "Operation,inst_date,fromver,tover"

# Solaris 10: not really possible so fake a result
if [ "$SOLARIS_10" -eq 1 ]; then
	KERNEL_VER=`uname -v | sed "s/Generic_//"`
	if [ -f /var/sadm/patch/$KERNEL_VER ]; then
              PATCH_DATE=`ls -Ed /var/sadm/patch/$KERNEL_VER | awk '{print $6}'`
        else # not patched? eek!
              PATCH_DATE=`ls -Ed /var/sadm/system/logs/install_log| awk '{print $6}'`
        fi

	echo patch,$PATCH_DATE,None,$KERNEL_VER
	exit 0
fi

LD_LIBRARY_PATH=
LD_LIBRARY_PATH_64=
PYTHONPATH=

pkg history -l | nawk '
/Operation/ {FS=":"; OP=$2 }
/End Time/ {FS=" ";ETIME=$3; sub("T"," ",ETIME)}
/->/ {ARGS=$0; split(ARGS,a,"->"); fromver=a[1];sub(/pkg.*-/,"",fromver);sub(/:.*Z/,"",fromver); tover=a[2]; sub(/pkg.*-/,"",tover); sub(/:.*Z/,"",tover)}
{theline=OP ARGS; if (theline ~ /entire/) printf "%s,\"%s\",%s,%s\n", OP, ETIME,fromver,tover}
'| uniq
