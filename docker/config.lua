return {

	http_host = '::',
	http_port = 8893,
	prefix = '',
	templates = '/usr/nepenthes/templates',
	words = '/usr/share/dict/usa',
	nochdir = true,
	max_wait = 10,
	real_ip_header	= 'X-Forwarded-For',
	prefix_header = 'X-Prefix',
	forget_time = 86400,
	forget_hits = 10,
	persist_stats = '/vol/nepenthes/statsfile.json'
}
