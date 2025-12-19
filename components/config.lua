#!/usr/bin/env lua5.4

local cp = require 'daemonparts.config_loader'
local yaml = require 'tinyyaml'

---
-- Default configuration
--
return cp.prepare {

	cp.parse_function( yaml.parse ),

	http_host = '::1',
	http_port = 8893,
	unix_socket = cp.default_nil('string'),
	templates = cp.array {
		'./templates'
	},
	nochdir = false,
	daemonize = false,
	pidfile = cp.default_nil('string'), -- ./pidfile',
	real_ip_header	= 'X-Forwarded-For',
	silo_header = 'X-Silo',
	seed_file = cp.default_nil('string'), -- './seed.txt',
	log_level = 'info',
	stats_remember_time = 3600,
	min_wait = 5,
	max_wait = 10,

	silos = cp.array {
		{
			bogon_filter = true,
			name = 'default',
			template = 'default',
			min_wait = 5,
			max_wait = 10,
			header_min_wait = 5,
			header_max_wait = 30,
			zero_delay = false,
			default = false,
			redirect_rate = 0,
			corpus = cp.not_nil('string'),
			wordlist = cp.not_nil('string'),
			prefixes = cp.array {
				cp.default_nil('string')
			}
		}
	}

}
