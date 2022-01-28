#!/bin/bash

TESTLIST="recv recvfrom recvmsg"

for t in $TESTLIST; do
	echo "RUNNING TEST [$t]"
	echo ""
	./$t
	echo ""
	echo "FINISH TEST [$t]"
	if [[ $? -ne 0 ]]; then
		echo ""
		echo "[$t] FAIL!!!"
		echo ""
		echo ""
	else
		echo ""
		echo "[$t] SUCC!!!"
		echo ""
		echo ""
	fi
done

