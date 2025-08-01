#!/bin/sh

PROJECT=nepenthes

DEPENDS=`cat <<EOF
	perihelion
	sqltable
	daemonparts 1.4
	lustache
	dkjson
	basexx
	binaryheap
	fifo
	lpeg_patterns
	http
	api7-lua-tinyyaml
EOF`

if [ -z "$1" ]; then
	echo "Provide scratch directory"
	exit 1
fi

scratch=$1; shift

if [ -z "$1" ]; then
	echo "Provide Version Number"
	exit 1
fi

version=$1; shift


if [ \! -d $scratch ]; then
	mkdir -p $scratch
fi

cd $scratch

#svn export https://svn.zadzmo.org/repo/$PROJECT/head ./$PROJECT-$version || exit 1
svn export https://svn.zadzmo.org/repo/$PROJECT/tags/$version ./$PROJECT-$version || exit 1

for dependency in $DEPENDS; do
	echo $dependency
	luarocks-5.4 --tree ./$PROJECT-$version/external install --deps-mode none --no-doc $dependency || exit 1
done

tar -cvf $PROJECT-$version.tar $PROJECT-$version/ || exit 1
gzip $PROJECT-$version.tar || exit 1
