#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local cqueues = require 'cqueues'
local util = require 'http.util'

local output = require 'daemonparts.output'

local config = require 'components.config'
local silo = require 'components.silo'

--
-- Monkey patch this to make it identical from test run to test run.
--
local seed = require 'components.seed'
seed.get = function()
	return 'ec708cffc8c154521ced80639449576ff8bd356060eeb20aecfc76e45ec80bbc'
end


local frontend = require 'components.frontend'


local function mock_request( req_type, uri, query, name, post_data )

	local ret = {}

	ret.GET = {}
	ret.POST = {}
	ret.REQUEST_METHOD = req_type
	ret.QUERY_STRING = query or ""
	ret.PATH_INFO = uri or "/"
	ret.SCRIPT_NAME = name or "nepenthes.lua"
	ret.CONTENT_TYPE = ""
	ret.CONTENT_LENGTH = ""
	ret.REMOTE_ADDR = "127.0.0.1"
	ret.SESSION = {}
	ret.input = nil
	ret.headers = {}
	ret.vars = {}

	function ret.notfound( web, body )
		return '404 Not Found', web.headers, body
	end

	function ret.ok( web, response_body )
		local out = ""

		if type(response_body) == 'string' then
			out = response_body
		elseif type(response_body) == 'table' then
			out = table.concat(response_body, " ")
		elseif type(response_body) == 'function' then
			repeat
				local x = response_body()
				out = out .. tostring(x)
			until not out
		else
			error("unknown returned type")
		end

		return '200 OK', web.headers, out
	end

	if post_data then
		ret.input = assert(io.open(post_data, "r"))
		ret.CONTENT_LENGTH = #(ret.input:read("*all"))
		ret.input:seek("set", 0)
	end

	return ret

end


require 'busted.runner'()
describe("Frontend Routes", function()

	local logged_lines = {}

	setup(function()
		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				min_wait = 1,
				max_wait = 5,
				header_min_wait = 1,
				header_max_wait = 1
			},
			{
				name = 'utf8',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/slowa-abridged.txt',
				template = 'default',
				min_wait = 1,
				max_wait = 5,
				header_min_wait = 1,
				header_max_wait = 1
			}
		}

		silo.setup()

		output.switch('table', logged_lines)
	end)

	before_each(function()
		logged_lines = {}
		output.switch('table', logged_lines)
	end)


	it("Handles GET", function()

		local test_start = cqueues.monotime()
		local web = mock_request( 'GET', '/' )

		local vars = frontend.preprocess( web )
		assert.is_table( vars )
		web.vars = vars

		local status, headers, out = frontend.GET( web )
		assert.is_function( out )
		assert.is_table( headers )
		assert.is_equal( '200 OK', status )

		local s = ''
		for val in out do
			s = s .. val
		end

		assert.is_string(s)
		assert.is_equal( 1647, #s )
		local test_end = cqueues.monotime()
		local duration = test_end - test_start

		-- 1 second more than config, allow some processing overhead
		assert.is_true( duration <= 6 )
		assert.is_true( duration >= 1 )

		assert.is_equal( 1, #logged_lines )

	end)


	it("Handles HEAD", function()

		local test_start = cqueues.monotime()
		local web = mock_request( 'HEAD', '/' )

		local vars = frontend.preprocess( web )
		assert.is_table( vars )
		web.vars = vars

		local status, headers, out = frontend.HEAD( web )
		assert.is_equal( '', out )
		assert.is_table( headers )
		assert.is_equal( '200 OK', status )

		local test_end = cqueues.monotime()
		local duration = test_end - test_start

		-- 1 second more than config, allow some processing overhead
		assert.is_true( duration <= 2 )
		assert.is_true( duration >= 1 )

	end)


	it("Accepts URL encoded URLs", function()

		local function run( web )
			local test_start = cqueues.monotime()

			web['HTTP_X_SILO'] = 'utf8'
			local vars = frontend.preprocess( web )
			assert.is_table( vars )
			web.vars = vars

			local status, headers, out = frontend.GET( web )
			assert.is_function( out )
			assert.is_table( headers )
			assert.is_equal( '200 OK', status )

			local s = ''
			for val in out do
				s = s .. val
			end

			assert.is_string(s)
			assert.is_equal( 1034, #s )
			local test_end = cqueues.monotime()
			local duration = test_end - test_start

			-- 1 second more than config, allow some processing overhead
			assert.is_true( duration <= 6 )
			assert.is_true( duration >= 1 )
		end

		local test_string = '/odbanujże/rozsłocisz'

		run( mock_request( 'GET', test_string ) )
		run( mock_request( 'GET', util.encodeURI( test_string ) ) )

		assert.is_equal( 2, #logged_lines )

	end)

	it("Filters bogons", function()
		pending("Not yet written")
	end)

	it("Switches silos", function()
		pending("Not yet written")
	end)


	it("Redirects", function()
		pending("Not yet written")
	end)


	it("Handles GET - zero delay", function()
		pending("Not yet written")
	end)


	it("Handles HEAD - zero delay", function()
		pending("Not yet written")
	end)


	it("Redirects - zero delay", function()
		pending("Not yet written")
	end)

end)
