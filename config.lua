return {

	http_host = '::',
	http_port = 8893,
	prefix = '',
	templates = './templates',
	words = '/usr/share/dict/words',
	nochdir = true,
	pidfile = './pidfile',
	min_wait = 4,
	max_wait = 9,
	real_ip_header	= 'X-Forwarded-For',
	prefix_header = 'X-Prefix',
	forget_time = 86400,
	forget_hits = 10,
	persist_stats = './statsfile.json',
	seed_file = './seed.txt',
	markov = './markov.db',
	markov_min = 10,
	markov_max = 50

}
