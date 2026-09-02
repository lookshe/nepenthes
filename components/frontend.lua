#!/usr/bin/env lua5.4

local http_util = require 'http.util'
local corewait = require 'daemonparts.corewait'
local output = require 'daemonparts.output'

local silo = require 'components.silo'
local stutter = require 'components.stutter'
local stats = require 'components.stats'


---
-- Code for logging
--
local function checkpoint( times, name )
	times[ #times + 1 ] = {
		name = name,
		at = corewait.monotime()
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


---
-- Code for converting logging into stats
--
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
	--logged:mark_complete()
	return logged

end

local function log_bogon( web, req, delay )
	return log_misc_hit( web, req, 404, delay )
end

local function log_redirect( web, req, delay )
	return log_misc_hit( web, req, 302, delay )
end

local function log_head( web, req, delay )
	return log_misc_hit( web, req, 200, delay )
end




local _M = {}


---
-- Common code for all requests: detect redirects and bogons.
--
function _M.preprocess( web )

	local path = http_util.decodeURI( web.PATH_INFO )

	local ts = {}
	checkpoint( ts, 'start' )

	local req = silo.new_request( web.HTTP_X_SILO, path )

	if req:is_bogon() then
		output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", path)
		local pause = req:header_wait()
		corewait.poll( pause )
		log_bogon( web, req, pause ):mark_complete()
		return web:notfound("Nothing exists at this URL")
	end

	local is_redirect, location = req:is_redirect()
	if is_redirect then
		local pause = req:header_wait()
		local logged = log_redirect( web, req, pause )
		local page = '< href="' .. location .. '">Moved Here</a>'

		web.headers['location'] = location
		return '302 Found', web.headers, stutter.delay_iterator (
			page, logged,
			stutter.generate_pattern( pause, #page )
		)
	end

	return {
		ts  = ts,
		path = path,
		req = req
	}

end


---
-- Actual tarpitting happens here.
--
function _M.GET( web )

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
		uri = web.vars.path,
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
		return '200 OK', web.headers,
			stutter.zero_delay_iterator( page, logged )
	end

	return '200 OK', web.headers, stutter.delay_iterator (
			page, logged,
			stutter.generate_pattern( wait, #page )
		)
end


---
-- Some crawlers HEAD every url before GET. Since it will always result
-- in a document (request has already cleared the bogon check during
-- setup), don't do anything.
--
function _M.HEAD( web )

	local req = web.vars.req

	local pause = req:header_wait()

	if not req.zero_delay then
		corewait.poll( pause )
	end

	log_head( web, req, pause )
	web.headers['content-type'] = 'text/html; charset=UTF-8'
	return web:ok("")

end

return _M
