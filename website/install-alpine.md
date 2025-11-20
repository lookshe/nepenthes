Alpine Manual Install
=====================

This was tested with Nepenthes 2.3 on a fresh install of Alpine 3.22.2.

### prereqs

lua5.4-dev, luarocks5.4 are needed to get lunix to install from 
Luarocks. 

```shell
apk add lua5.4 lua5.4-dev luarocks5.4
apk add lua5.4-ossl lua5.4-lpeg lua5.4-cqueues lua5.4-lzlib
luarocks-5.4 install lunix
```

Alpine also doesn't include a dictionary file like many other OS's or 
distrubtions; it is provided by the words package.

```shell
apk add words
```

### setup user, code

Create the user, fetch the tarball, unpack. The --strip-components 
argument causes the files to drop directly into the working directory - 
in this case that's the nepenthes user home directory.

```shell
useradd -m nepenthes
cd ~/nepenthes
curl -o ./nepenthes-latest.tar.gz -L https://zadzmo.org/downloads/nepenthes/latest
tar --strip-components 1 -xvzf nepenthes-latest.tar.gz
```

Edit your configuration at this point. In particular, there is no 
/usr/share/dict/words on Alpine - after installing the words package, 
pick something more appropriate for your needs in /usr/share/dict.

### Launch

```shell
su - nepenthes
./nepenthes ./config.yml
```

Become the Nepenthes user, and run.
