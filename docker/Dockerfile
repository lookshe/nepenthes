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
RUN wget https://zadzmo.org/code/nepenthes/downloads/nepenthes-1.0.tar.gz
COPY config.lua /etc/nepenthes-config.lua

#
# Sadly this Lua C module isn't in apk. Only one missing to build the
# container without any calls to Luarocks at all.
#
# (Yes, I know about Luaposix. Switching to this eliminated a lot of
# fiddly problems I was having, especially on NetBSD.)
#
RUN luarocks install lunix

RUN adduser -D nepenthes
RUN chown nepenthes /var/run
USER nepenthes

VOLUME /vol/nepenthes
EXPOSE 8893
WORKDIR /usr/nepenthes

#
# Performance enhancement
#
RUN echo 'PRAGMA journal_mode = wal;' | sqlite3 /vol/nepenthes/corpus.sqlite.db

CMD ["lua", "/usr/nepenthes/microdyne.lua", "/usr/nepenthes/nepenthes.lua", "/etc/nepenthes-config.lua"]
