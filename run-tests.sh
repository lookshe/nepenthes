#!/bin/sh

rm -rf luacov.*.out

luacheck --ignore 631 --codes --std +busted --no-cache tests/ || exit 1
luacheck --codes --no-cache components/ || exit 1
luacheck --codes --no-cache core/ || exit 1

ecode=0
exec_tests()
{
	path=$1

	for file in `ls $path`; do
		echo "$file"
		$file
		if [ $? != 0 ]; then
			ecode=1
		fi
	done
}

exec_tests "tests/*.lua"
luacov

echo "Status: $ecode"
if [ $ecode != 0 ]; then
	exit $ecode
fi

