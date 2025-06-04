FROM nickblah/lua:5.4-luarocks-alpine
RUN apk add --no-cache build-base
RUN apk add --no-cache sqlite 
RUN apk add --no-cache openssl
RUN apk add --no-cache words
RUN apk add --no-cache lua5.4-cqueues
RUN apk add --no-cache lua5.4-ossl
RUN apk add --no-cache lua5.4-lpeg
RUN apk add --no-cache lua5.4-lzlib
RUN apk add --no-cache lua5.4-dbi-sqlite3

RUN <<EOF
	wget https://zadzmo.org/downloads/nepenthes/file/nepenthes-1.2.tar.gz
	tar -xvzf nepenthes-1.2.tar.gz
	mv nepenthes-1.2 /usr/nepenthes
	rm nepenthes-1.2.tar.gz
EOF
COPY config.yaml /etc/nepenthes-config.yml

#
# Sadly this Lua C module isn't in apk. Only one missing to build the
# container without any calls to Luarocks at all.
#
# (Yes, I know about Luaposix. Switching to this eliminated a lot of
# fiddly problems I was having, especially on NetBSD.)
#
RUN luarocks install lunix

VOLUME /vol/nepenthes
RUN <<EOF
	adduser -D nepenthes
	chown nepenthes /var/run
	mkdir -p /vol/nepenthes
	chown nepenthes /vol/nepenthes
EOF

USER nepenthes
EXPOSE 8893
WORKDIR /usr/nepenthes

#
# Performance enhancement
#
RUN echo 'PRAGMA journal_mode = wal;' | sqlite3 /vol/nepenthes/corpus.sqlite.db

ENV NDIR="/usr/nepenthes"
CMD ["sh", "/usr/nepenthes/nepenthes", "/etc/nepenthes-config.yml", "/usr/nepenthes/docker/bootstrap.lua"]
