#!/usr/bin/env lua5.4

local cp = require 'components.config_loader'

---
-- Default configuration
--
local config = {

	http_host = '::1',
	http_port = 8893,
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
	markov = cp.default_nil('string'), -- './markov.db',
	markov_min = 10,
	markov_max = 50

}

---
-- Make the default callable, calling the table loads the given YAML
-- file to overwrite defaults with error checking.
--
cp.prepare( config )


---
-- Return the original config object as a singleton. Every module
-- gets the same config, even after loading.
--
return config
