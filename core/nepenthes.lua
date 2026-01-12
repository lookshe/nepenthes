#!/usr/bin/env lua5.4

local cqueues = require 'cqueues'
local json = require 'dkjson'

local perihelion = require 'perihelion'
local output = require 'daemonparts.output'
local corewait = require 'daemonparts.corewait'

local stats = require 'components.stats'
local stutter = require 'components.stutter'
local silo = require 'components.silo'


silo.setup()

local app = perihelion.new()


app:get "/stats/silo/(%S+)/addresses" {
	function ( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.address_list( silo_filter ) )
		)
	end
}

app:get "/stats/silo/(%S+)/agents" {
	function ( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.agent_list( silo_filter ) )
		)
	end
}

app:get "/stats/silo/(%S+)" {
	function( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.compute( silo_filter ) )
		)
	end
}

app:get "/stats/agents" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.agent_list() )
		)
	end
}

app:get "/stats/addresses" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.address_list() )
		)
	end
}

app:get "/stats/buffer/from/(%d+%.%d+)" {
	function ( web, id )
		web.headers['Content-type'] = 'application/json'

		local stop_if_incomplete = false
		if web.HTTP_X_STOP_IF_INCOMPLETE then
			stop_if_incomplete = true
		end

		return web:ok(
			json.encode( stats.buffer( id, stop_if_incomplete ) )
		)
	end
}

app:get "/stats/buffer" {
	function ( web )
		web.headers['Content-type'] = 'application/json'

		local stop_if_incomplete = false
		if web.HTTP_X_STOP_IF_INCOMPLETE then
			stop_if_incomplete = true
		end

		return web:ok(
			json.encode( stats.buffer( nil, stop_if_incomplete ) )
		)
	end
}

app:get "/stats" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.compute() )
		)
	end
}



local function checkpoint( times, name )
	times[ #times + 1 ] = {
		name = name,
		at = cqueues.monotime()
	}
end

local function log_checkpoints( times, send_delay, logged_silo )

	local parts = {}

	for i, cp in ipairs( times ) do	-- luacheck: ignore 213
		if cp.name ~= 'start' then
			parts[ #parts + 1 ] = string.format('%s: %f', cp.name, cp.at - times[1].at)
		end
	end

	if send_delay then
		parts[ #parts + 1 ] = string.format('send_delay: %f', send_delay)
	end

	if logged_silo then
		parts[ #parts + 1 ] = string.format('silo: %s', logged_silo)
	end

	output.info("req len: " .. table.concat( parts, ', ' ))

end


local function log_misc_hit( web, req, code, delay )

	local logged = stats.new_entry {
		address = web.REMOTE_ADDR,
		uri = web.PATH_INFO,
		agent = web.HTTP_X_USER_AGENT,
		silo = req.silo,
		bytes_generated = 0,
		when = os.time(),
		response = code,
		planned_delay = delay,
		cpu = 0,
		complete = true
	}

	logged:record( 0, delay )
	logged:mark_complete()

end

local function log_bogon( web, req, delay )
	log_misc_hit( web, req, 404, delay )
end

local function log_redirect( web, req, delay )
	log_misc_hit( web, req, 302, delay )
end

local function log_head( web, req, delay )
	log_misc_hit( web, req, 200, delay )
end


---
-- Common code for both HEAD and GET requests.
--
local function request_preprocess( web )

	local ts = {}
	checkpoint( ts, 'start' )

	local req = silo.new_request( web.HTTP_X_SILO, web.PATH_INFO )

	if req:is_bogon() then
		output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
		local pause = req:header_wait()
		corewait.poll( pause )
		log_bogon( web, req, pause )
		return web:notfound("Nothing exists at this URL")
	end

	local is_redirect, location = req:is_redirect()
	if is_redirect then
		local pause = req:header_wait()
		corewait.poll( pause )
		log_redirect( web, req, pause )
		return web:redirect( location )
	end

	return {
		ts  = ts,
		req = req
	}

end


---
-- Some crawlers HEAD every url before GET. Since it will always result
-- in a document (request has already cleared the bogon check during
-- setup), don't do anything.
--
app:head "/(.*)" {
	request_preprocess,
	function( web )
		local req = web.vars.req

		local pause = req:header_wait()
		corewait.poll( pause )
		log_head( web, req, pause )
		web.headers['content-type'] = 'text/html; charset=UTF-8'
		return web:ok("")
	end
}

---
-- Actual tarpitting happens here.
--
app:get "/(.*)" {
	request_preprocess,
	function( web )

		local req = web.vars.req
		local ts = web.vars.ts

		checkpoint( ts, 'preprocess' )
		req:load_markov()
		req:set_booleans()
		checkpoint( ts, 'markov' )
		local page = req:render()
		local wait = req:send_delay()
		checkpoint( ts, 'rendering' )

		local siloname
		if silo.count() > 1 then
			siloname = req.silo
		end

		log_checkpoints( ts, wait, siloname )

		local time_spent = ts[ #ts ].at - ts[1].at
		local logged = stats.new_entry {
			address = web.REMOTE_ADDR,
			uri = web.PATH_INFO,
			agent = web.HTTP_X_USER_AGENT,
			silo = req.silo,
			bytes_generated = #page,
			when = os.time(),
			response = 200,
			planned_delay = wait,
			cpu = time_spent
		}

		web.statistic_log = logged
		web.headers['content-type'] = 'text/html; charset=UTF-8'

		if req.zero_delay then
			return '200 OK', web.headers, function()
				if not page then
					logged:mark_complete()
					return nil
				end

				local ret = page
				page = nil
				logged:record( #page, 0 )
				return ret
			end
		end

		return '200 OK', web.headers, stutter.delay_iterator (
				page, logged,
				stutter.generate_pattern( wait, #page )
			)
	end
}

return app
