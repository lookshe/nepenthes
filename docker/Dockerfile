FROM nickblah/lua:5.4-luarocks-alpine
RUN apk add --no-cache build-base
RUN apk add --no-cache subversion
RUN apk add --no-cache sqlite sqlite-dev
RUN apk add --no-cache openssl-dev
RUN apk add --no-cache libbsd-dev
RUN apk add --no-cache m4
RUN apk add --no-cache words
RUN svn export https://svn.zadzmo.org/repo/nepenthes/head /usr/nepenthes
RUN luarocks install perihelion
RUN luarocks install sqltable
RUN luarocks install http
RUN luarocks install daemonparts
RUN luarocks install lustache
RUN luarocks install dkjson
RUN luarocks install luadbi-sqlite3
COPY config.lua /etc/nepenthes-config.lua

#
# Cleanup stuff to reduce image size
#
RUN apk del build-base m4 subversion


RUN adduser -D nepenthes
RUN chown nepenthes /var/run
USER nepenthes

VOLUME /vol/nepenthes
EXPOSE 8893

WORKDIR /usr/nepenthes
CMD ["lua", "/usr/nepenthes/microdyne.lua", "/usr/nepenthes/nepenthes.lua", "/etc/nepenthes-config.lua"]
