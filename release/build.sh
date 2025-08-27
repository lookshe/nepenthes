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

version=$1; shift


if [ \! -d $scratch ]; then
	mkdir -p $scratch
fi

cd $scratch
svn export https://svn.zadzmo.org/repo/$PROJECT/tags/$version ./$PROJECT-$version || exit 1

mkdir -p ./$PROJECT-$PROJECT_VERSION/external/license

./$PROJECT-$PROJECT_VERSION/release/depends.lua | while read cmd; do
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
	rm -rf ./$PROJECT-$PROJECT_VERSION/$thing
done

tar -cvf $PROJECT-$version.tar $PROJECT-$version/ || exit 1
gzip $PROJECT-$version.tar || exit 1
