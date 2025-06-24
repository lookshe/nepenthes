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
	prefix = '',
	templates = './templates',
	words = '/usr/share/dict/words',
	nochdir = false,
	daemonize = false,
	pidfile = cp.default_nil('string'), -- ./pidfile',
	min_wait = 4,
	max_wait = 9,
	real_ip_header	= 'X-Forwarded-For',
	prefix_header = 'X-Prefix',
	forget_time = 86400,
	forget_hits = 10,
	persist_stats = cp.default_nil('string'), -- './statsfile.json',
	seed_file = cp.default_nil('string'), -- './seed.txt',
	markov_corpus = cp.not_nil('string'), -- './markov.db',
	markov_min = 10,
	markov_max = 50,
	stats_remember_time = 1800

}
