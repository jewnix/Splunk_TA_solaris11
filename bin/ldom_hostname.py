#!/usr/bin/python
from subprocess import Popen, PIPE
import re
import telnetlib
import sys

def process_option(tsocket, command, option): 
	return


console = sys.argv[1]

tn = telnetlib.Telnet("127.0.0.1",console)
tn.set_option_negotiation_callback(process_option)
tn.write("\n\n\n")
mo = tn.expect([r' (\S*) console login',r'} (ok)'],2)
tn.close()
if mo[1]:
    ldom_hostname = mo[1].group(1)
    if ldom_hostname == 'ok':
        print "OBP"
    else:
        print "%s" % ldom_hostname
