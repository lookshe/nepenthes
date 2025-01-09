#!/usr/bin/env lua5.4

pcall(require, "luarocks.loader")

local cqueues = require 'cqueues'
local http_server = require 'http.server'
local http_headers = require 'http.headers'

local unix = require 'unix'

local daemonize = require 'daemonparts.daemonize'
local config = require 'config'
local signals = require 'daemonparts.signals'
local output = require 'daemonparts.output'


if not arg[1] then
	error("Provide application")
end

if not arg[2] then
	error("Provide config file")
end

local location = unix.getcwd()
package.path = package.path .. ';' .. location .. '/?.lua'

local cq
local app

local cf = assert(dofile( arg[2] ))
local app_f = assert(loadfile( arg[1] ))
for k, v in pairs(cf) do config[k] = v end


local function header_cleanup( var )
	return 'HTTP_' .. var:upper():gsub("%-", '_')
end


local function http_responder( server, stream )	-- luacheck: ignore 212

	local req_headers = stream:get_headers()
	local cl_family, cl_addr, cl_port = stream:peername()	-- luacheck: ignore 211
	local path = req_headers:get(':path')

	local request = {
		SERVER_NAME = req_headers:get(':authority'),
		SERVER_SOFTWARE = 'lua-http',
		SERVER_PROTOCOL = stream.connection.version,
		--SERVER_PORT = config.http_port,
		REQUEST_METHOD = req_headers:get(':method'),
		DOCUMENT_ROOT = "/",		-- XXX: Set correctly
		PATH_INFO = path,
		PATH_TRANSLATED = path,		-- XXX: Set Correctly
		APP_PATH = '/',				-- XXX: Set Correctly
		SCRIPT_NAME = '/',			-- XXX: what should this be?
		QUERY_STRING = "?",			-- XXX: Needs to be parsed
		REMOTE_ADDR = cl_addr,
		REMOTE_PORT = cl_port,
		REMOTE_USER = req_headers:get('authorization'),	-- XXX: parse this
		CONTENT_TYPE = req_headers:get('content-type'),
		CONTENT_LENGTH = req_headers:get('content-length'),
		HTTP_COOKIE = req_headers:get('cookie')
	}

	-- XXX: I'm sorry
	request[ header_cleanup('X_USER_AGENT') ] = req_headers:get('user-agent')

	-- import all nonstandard headers; they're important
	for name, val in req_headers:each() do
		--print(name, val)
		if name:match('^[Xx]%-') then
			request[ header_cleanup( name) ] = val
		end
	end

	-- X-forwarded-for or similar?
	if config.real_ip_header then
		local real_ip = request[header_cleanup(config.real_ip_header)]

		if real_ip then
			request.REMOTE_ADDR = real_ip
		end
	end

	request.input = stream:get_body_as_file()

	--
	-- Call WSAPI application here
	--
	local rawstatus, wsapi_headers, iter = app.run( request )

	local status
	if type(rawstatus) == 'string' then
		status = rawstatus:match("^(%d+)")
	else
		status = rawstatus
	end

	local res_headers = http_headers.new()
	res_headers:append("Server", config.server_software or 'nginx')
	res_headers:append(":status", status)

	for k, v in pairs(wsapi_headers) do
		res_headers:append(k, v)
	end

	stream:write_headers(res_headers, false)
	for chunk in iter do
		stream:write_chunk(chunk, false)
	end

	stream:write_chunk("", true)

	output.info(string.format("Web: %s [%s %s] %s",
		request.REMOTE_ADDR,
		request.REQUEST_METHOD,
		request.PATH_INFO,
		rawstatus
	))
end


local server

local function stop_notification()
	server:close()
	output.notice("Shutting down")

	if app.shutdown_hook then
		pcall(app.shutdown_hook)
	end
end

local function startup()

	if config.nochdir then
		unix.chdir(location)
	end

	if config.pidfile then
		daemonize.pidfile( config.pidfile )
	end

	cq = cqueues.new()
	app = app_f()

	server = assert(http_server.listen {
		host = config.http_host,
		port = math.floor(config.http_port),
		onstream = http_responder,
		tls = false,
		cq = cq
	})

	signals.set_callback( stop_notification )
	signals.start(cq)

	assert(server:listen())

end

if config.daemonize then
	daemonize.go( startup )
	output.switch('syslog', 'user', arg[1])
else
	output.info("Remaining in foreground")
	startup()
end

output.notice("Startup HTTP:", config.http_host, config.http_port)

repeat
	local res, err = cq:step(2)
	if not res then
		output.error(err)
		os.exit(1)
	end
until cq:count() == 0
