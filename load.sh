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

do_post()
{
	size_sent=`expr $size + $size_sent`
	echo -n "date \"+%H:%m\" sending $size_sent of $size_lines: "
	curl -XPOST -H'Content-type: text/plain' -d "$send" $url || exit 1
	
	echo "done."
}


size=0
send=""
while read line; do

	send="$send $line"
	size=`expr $size + 1`
	if [ $size -ge 100 ]; then
		do_post
		size=0
		body=""
	fi

done < $text

if [ $size -gt 0 ]; then
	do_post
fi
