Debian Manual Install
=====================

This was tested with Nepenthes 2.3 on a fresh install of Debian 13.2 
(Trixie.) 

### prereqs

Luarocks (and thus liblua5.4-dev) need to be installed as lunix is not
available in Apt.

```shell
apt-get install lua5.4 liblua5.4-dev
apt-get install lua-cqueues lua-lpeg lua-zlib lua-luaossl
apt-get install luarocks
luarocks-5.4 install lunix
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

Edit your configuration at this point.

### Launch

```shell
su - nepenthes
./nepenthes ./config.yml
```

Become the Nepenthes user, and run.
