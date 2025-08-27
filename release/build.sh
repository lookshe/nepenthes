#!/bin/sh

export PROJECT=nepenthes

if [ -z "$1" ]; then
	echo "Provide scratch directory"
	exit 1
fi

scratch=$1; shift

if [ -z "$1" ]; then
	echo "Provide Version Number"
	exit 1
fi

export VERSION=$1; shift


if [ \! -d $scratch ]; then
	mkdir -p $scratch
fi

deps=`pwd`/depends.lua
cd $scratch
svn export https://svn.zadzmo.org/repo/$PROJECT/tags/$VERSION ./$PROJECT-$VERSION || exit 1

mkdir -p ./$PROJECT-$VERSION/external/license

$deps | while read cmd; do
	$cmd || exit 1
done

cleanout="
	.luacov
	tests
	release
	run-tests.sh
"

echo $cleanout

for thing in $cleanout; do
	echo "Cleaning $thing"
	rm -rf ./$PROJECT-$VERSION/$thing
done

tar -cvf $PROJECT-$VERSION.tar $PROJECT-$VERSION/ || exit 1
gzip $PROJECT-$VERSION.tar || exit 1
