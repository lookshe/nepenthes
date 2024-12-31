#!/bin/sh

if [ -z "$1" ]; then
	echo "Provide corpus text name"
	exit 1
fi
text=$1; shift

if [ -z "$1" ]; then
	echo "Provide instance training url ( http://localhost:8893/train ?)"
	exit 1
fi
url=$1; shift

size_lines=`wc -l $text`
size_sent=0
skip=0

#
# Third argument: Skip ahead (x) lines, if training got interrupted
#
if [ \! -z "$1" ]; then
	skip=$1
fi

do_post()
{
	size_sent=`expr $size + $size_sent`
	echo -n "`date \"+%H:%m\"` sending $size_sent of $size_lines: "
	curl -XPOST -H'Content-type: text/plain' -d "$send" $url || exit 1
	
	echo "  done."
}

size=0
send=""
while read line; do

	if [ $skip -gt 0 ]; then
		skip=`expr $skip - 1`
		size_sent=`expr $size_sent + 1`
	else
		send="$send $line"
		size=`expr $size + 1`
		if [ $size -ge 10 ]; then
			do_post
			size=0
			body=""
		fi
	fi

done < $text

if [ $size -gt 0 ]; then
	do_post
fi
