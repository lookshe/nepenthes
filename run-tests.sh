#!/bin/sh

rm -rf luacov.*.out

luacheck --ignore 631 --codes --std +busted --no-cache tests/ || exit 1
luacheck --codes --no-cache components/ || exit 1
luacheck --codes --no-cache core/ || exit 1

ecode=0
failed=""

exec_tests()
{
	path=$1

	for file in `ls $path`; do
		echo "$file"
		$file
		if [ $? != 0 ]; then
			ecode=1
			failed="$failed $file"
		fi
	done
}

exec_tests "tests/*.lua"
luacov

echo "Status: $ecode"
if [ ! -z "$failed" ]; then
        echo "Failed tests: $failed"
fi

if [ $ecode != 0 ]; then
        exit $ecode
fi
