#!/usr/bin/env lua5.4

if not os.getenv('PROJECT') then
	os.exit(1)
end

if not os.getenv('VERSION') then
	os.exit(1)
end


local depends = {
	{
		name = 'basexx',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/aiq/basexx/refs/heads/master/LICENSE'
	},
	{
		name = 'daemonparts',
		version = 'latest',
		license = 'https://svn.zadzmo.org/repo/daemonparts/head/LICENSE'
	},
	{
		name = 'lustache',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/Olivine-Labs/lustache/refs/heads/master/LICENSE',
	},
	{
		name = 'dkjson',
		version = 'latest',
		license = 'http://dkolf.de/dkjson-lua/readme-2.8.txt'
	},
	{
		name = 'api7-lua-tinyyaml',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/api7/lua-tinyyaml/refs/heads/master/LICENSE'
	},
	{
		name = 'binaryheap',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/Tieske/binaryheap.lua/refs/heads/master/LICENSE'
	},
	{
		name = 'fifo',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/daurnimator/fifo.lua/refs/heads/master/LICENSE'
	},
	{
		name = 'lpeg_patterns',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/daurnimator/lpeg_patterns/refs/heads/master/LICENSE.md'
	},
	{
		name = 'http',
		version = 'latest',
		license = 'https://raw.githubusercontent.com/daurnimator/lua-http/refs/heads/master/LICENSE.md'
	},
	{
		name = 'perihelion',
		version = 'latest',
		license = 'https://svn.zadzmo.org/repo/perihelion/head/LICENSE'
	}
}

local function install ( depend )

	local version = ''
	if depend.version ~= 'latest' then
		version = depend.version
	end

	local command = "luarocks-5.4 --tree ./%s-%s/external install --deps-mode none --no-doc %s %s"
	print( string.format(
		command,
			os.getenv('PROJECT'),
			os.getenv('VERSION'),
			depend.name,
			version
	))

end

local function license( depend )

	local command = "curl -o ./%s-%s/external/license/%s -s -S %s"
	print( string.format(
		command,
			os.getenv('PROJECT'),
			os.getenv('VERSION'),
			depend.name,
			depend.license
	))
	
end


for i, v in ipairs( depends ) do
	install( v )
	license( v )
end


