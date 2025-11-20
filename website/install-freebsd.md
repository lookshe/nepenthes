FreeBSD Manual Install
======================

This was tested with Nepenthes 2.3 on a fresh install of FreeBSD 
14.3-RELEASE.

### prereqs

FreeBSD has a lot fewer packages available for Lua modules. 
lua54-luarocks is needed to get lunix, luaossl, and lua-zlib to 
install.

```shell
pkg install lua5.4 lua54-luarocks
pkg install lua54-lpeg lua54-cqueues
luarocks install luaossl
luarocks install lunix
luarocks install lua-zlib
```

### setup user, code

The adduser utility will ask a lot of questions. Defaults are fine for 
most, though I would leave the password blank as it is not intended to 
be an interactive account.

```shell
adduser nepenthes
```

The --strip-components  argument causes the files to drop directly into 
the working directory - in this case that's the nepenthes user home 
directory.

```shell
cd ~/nepenthes
curl -o ./nepenthes-latest.tar.gz -L https://zadzmo.org/downloads/nepenthes/latest
tar --strip-components 1 -xvzf nepenthes-latest.tar.gz
```

Edit your configuration at this point.

By default FreeBSD uses 'lua54' instead of 'lua5.4', so, edit the 
startup script accordingly:

```shell
sed -I .save s/lua5.4/lua54/g nepenthes
```

### Launch

Become the Nepenthes user, and run.

```shell
su - nepenthes
./nepenthes ./config.yml
```

