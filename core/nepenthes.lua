#!/usr/bin/env lua5.4

local perihelion = require 'perihelion'
local lustache = require 'lustache'
local digest = require 'openssl.digest'
local http_util = require 'http.util'
local output = require 'daemonparts.output'
local config = require 'components.config'
local cqueues = require 'cqueues'
local json = require 'dkjson'

local send = require 'components.send'
local seed = require 'components.seed'
local xorshiro = require 'components.xorshiro'
local markov = require 'components.markov'



--
-- Load Dictionary
--
local dict = {}
local dict_lookup = {}

local f = io.open( config.words, "r" )
for line in f:lines() do
	if not line:match("%'") then
		dict[ #dict + 1 ] = line
		dict_lookup[ line ] = true
	end
end


--
-- Train Markov corpus
--
local mk = markov.new()
mk:train_file( config.markov_corpus )


---
-- Pull a template code from disk.
--
local function load_template( path )

	local template_path = string.format(
		"%s/%s.lustache",
			config.templates,
			path
	)

	local template_file = assert(io.open(template_path, "r"))
	local ret = template_file:read("*all")
	template_file:close()

	return ret

end


---web.v
-- Render the page through a template engine.
--
local function render( template )

	--local iter = function( s, rate )
		----
		---- We have '#s' bytes to dispense through 'rate' seconds.
		---- How long do we delay and how much per? Let them have a
		---- taste of something every second, to keep them on the line.
		----
		--local chunk_size = #s
		--local delay = rate

		--repeat
			--chunk_size = chunk_size // 2
			--delay = delay / 2
		--until delay < 1

		--return function()
			--if #s <= 0 then
				--return nil
			--end

			--local ret = s:sub(1, chunk_size)
			--s = s:sub(chunk_size + 1, #s)
			--cqueues.sleep(delay)

			--return ret
		--end
	--end

	return function( web )

		local template_code = load_template( 'toplevel' )
		local prt = {}

		web.vars.app_path = config.prefix
		prt[ 'content' ] = load_template( template )

		rawset(lustache, 'partial_cache', {})
		local ret = lustache:render(template_code, web.vars, prt)
		if web.vars.sandbag_rate then
			local p = send.generate_pattern( web.vars.sandbag_rate, #ret )

			return '200 OK', web.headers, send.delay_iterator( ret, p )
		end

		return web:ok( ret )
	end

end


local app = perihelion.new()

app:get "/stats/markov" {
	function( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( markov.stats() )
		)
	end
}


local instance_seed = seed.get()

local function checkpoint( times, name )
	times[ #times + 1 ] = {
		name = name,
		at = cqueues.monotime()
	}
end

local function log_checkpoints( times, send_delay )

	local parts = {}

	for i, cp in ipairs( times ) do	-- luacheck: ignore 213
		if cp.name ~= 'start' then
			parts[ #parts + 1 ] = string.format("%s: %f", cp.name, cp.at - times[1].at)
		end
	end

	parts[ #parts + 1 ] = string.format("send_delay: %f", send_delay)
	output.info("req len: " .. table.concat( parts, ', ' ))

end

--
-- Some crawlers HEAD every url before GET. Since it will always
-- result in a document, don't do anything.
--
app:head "/(.*)" {
	function( web )
		web.headers['content-type'] = 'text/html; charset=UTF-8'
		return web:ok("")
	end
}

app:get "/(.*)" {
	function ( web )

		local timestats = {}
		checkpoint( timestats, 'start' )

		local dig = digest.new( 'sha256' )
		dig:update( instance_seed )
		local hash = dig:final( web.PATH_INFO )

		local rnd = xorshiro.new( string.unpack( "jjjj", hash ) )

		local function getword()
			return dict[ rnd:between( #dict, 1 ) ]
		end

		local function buildtab( size )
			local ret = {}

			for i = 1, size do
				ret[ i ] = getword()
			end

			return ret
		end

		local function make_url()
			return table.concat(buildtab( rnd:between( 5, 1 ) ), "/")
		end

		local ret = {
			header = getword(),
			prefix = config.prefix
		}


		--
		-- Allow attaching to multiple places via nginx configuration
		-- alone.
		--
		if web.HTTP_X_PREFIX then
			ret.prefix = web.HTTP_X_PREFIX
		end

		---
		-- I would like to thank the Slashdot commenter for his very
		-- clever idea for detecting tarpits. It's quite clever, I'll
		-- admit. It's also easy to defeat, which we do here.
		--
		-- Since the URLs are built from a known dictionary, it's not
		-- hard to sanity check them. If it's a new IP, we 301 them; and
		-- since we're using our deterministic random, the same bad URL
		-- will go to the same place. This lets the crawler 'bootstrap'
		-- itself into the tarpit if coming from an unexpected URL.
		--
		-- Afterwards, we throw 404, so it doesn't look like we're an
		-- infinite site.
		--
		local path = web.PATH_INFO:sub( #(ret.prefix) + 1 )
		local is_bogon = false
		for word in path:gmatch('/([^/]+)') do
			if not dict_lookup[ http_util.decodeURI(word) ] then
				is_bogon = true
			end
		end

		if is_bogon then
			output.notice("Bogon URL detected:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
			--
			-- Wait at least a little bit.
			--
			cqueues.sleep( rnd:between( 5, 1 ) )

			--if stats.check_ip( web.REMOTE_ADDR ) then
				--return web:notfound("Nothing exists at this URL")
			--else
				local send_to = ret.prefix .. '/' .. make_url()
				return web:redirect_permanent( send_to )
			--end
		end


		local len = rnd:between( 10, 5 )
		local links = {}
		for i = 1, len do
			links[ i ] = {
				description = getword(),
				link = make_url()
			}
		end

		ret.links = links
		checkpoint( timestats, 'words' )

		ret.content = mk:babble( rnd, config.markov_min, config.markov_max )
		ret.title = mk:babble( rnd, 5, 15 )

		checkpoint( timestats, 'markov' )

		--
		-- Oh you think this was supposed to be fast?
		--
		ret.sandbag_rate = rnd:between(config.max_wait or 10, config.min_wait or 1)
		checkpoint( timestats, 'total' )
		log_checkpoints( timestats, ret.sandbag_rate )

		return ret

	end,

	render( 'list' )
}

return app
