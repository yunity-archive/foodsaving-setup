# foodsaving-setup

This provides scripts to get the app up and running. The primary purpose is for developers to get up and running easily. Please create an issue if this doesn't work out the box for you, it's a work in progress :)

It helps you to:
- understand how to install system dependencies (information only)
- clone the seperate repos
- setup the application dependencies
- setup the database and run the migrations
- run/manage the application's processes using pm2

The app is split into frontend and backend parts. You can run everything locally on your machine.

## Install system deps

In this section we will install the following dependencies:
- python3.5 or greater/virtualenv
- node/npm (should work with 0.12.x and 4.x)
- postgresql >=9.4
- redis-server

You can check __some__ of the dependencies are present with:

```
make check-deps
```

### Ubuntu / Debian
As the foodsaving tool requires relatively recent versions of some packages, using Ubuntu 15.10 or greater is recommended.

```sh
sudo apt-get install git redis-server python3 python3-dev python-virtualenv postgresql postgresql-server-dev-9.4 gcc build-essential g++ libffi-dev libncurses5-dev
```

Node.js has to be installed independently. See  [these instructions](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions).

#### Make elasticsearch bin accessable in Ubuntu / Debian

```sh
sudo ln -s /usr/share/elasticsearch/bin/elasticsearch /usr/local/bin/elasticsearch
```

#### postgresql 9.4 in Ubuntu 14.04 and lower

Add the following to your /etc/apt/sources.list (or a custom configuration)

```sh
deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main
```

then import the package signing key, update your package lists and install postgres:

```sh
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update && sudo apt-get install postgresql-9.4 postgresql-server-dev-9.4
```

### OpenSUSE Leap

All packages should be available in the default repositories `repo-oss` and `repo-non-oss`.

```sh
sudo zypper install python-virtualenv postgresql-devel postgresql python-redis redis npm
```

### Archlinux

All packages can be obtained from core, extra or community repositories. When queried, chose to install all packets out of base-devel.

```sh
sudo pacman -S base-devel python python-pip python-virtualenv postgresql python-redis redis npm
```

#### First-time postgres setup

```sh
sudo -i -u postgres
initdb --locale en_US.UTF-8 -E UTF8 -D '/var/lib/postgres/data'
```

#### Start necessary processes

By default, archlinux does not start the installed services.

```sh
sudo systemctl start postgresql.service
sudo systemctl start redis.service
```

You can add them to autostart as well:

```sh
sudo systemctl enable postgresql.service
sudo systemctl enable redis.service
```

### Relaxed postgres fsync behaviour
On a local setup, you may want to change fsync behaviour to speed up the test running process. You may want to make sure to understand the implications but on a dev machine this should be fine.

Edit /var/lib/postgres/data/postgresql.conf and add or edit

```
fsync = off
```

## Quick start (everything local)

```sh
git clone https://github.com/yunity/foodsaving-setup.git foodsaving-tool
cd foodsaving-tool
make
pm2 start pm2.json
```

Then visit [localhost:5000](http://localhost:5000) to access all the things.

To update everything later on, run:

```
make update
```

## Endpoints

The proxy serves up the following endpoints you can visit, these are the more useful ones:

URL                                                          | Purpose
-------------------------------------------------------------|----------------------------------------------
[localhost:5000](http://localhost:5000)                      | admin/dev server, shows you links to other sites...
[localhost:8091](http://localhost:8091/)                     | mobile webapp served here
[localhost:8091/api](http://localhost:8090/api/)             | django api endpoint
[localhost:8091/swagger](http://localhost:8090/swagger)      | swagger docs
[localhost:9080](http://localhost:9080)                      | see who is connected to the sockets app


... and some extra endpoints if you're interested:


URL                                                          | Purpose
-------------------------------------------------------------|----------------------------------------------
[localhost:8091/socket](http://localhost:8090/socket/)       | foodsaving-sockets socket.io endpoint
[localhost:8091/socket.io](http://localhost:8090/socket.io/) | webapp webpack-dev-server socket.io endpoint
[localhost:8091/swagger](http://localhost:8091/swagger)      | swagger docs
[localhost:8091/api](http://localhost:8091/api/)             | django api endpoint
[localhost:8091/socket](http://localhost:8091/socket/)       | foodsaving-sockets socket.io endpoint
[localhost:8091/socket.io](http://localhost:8091/socket.io/) | mobile webapp webpack-dev-server socket.io endpoint


You should end up with the following services running:

Name    | URL                                                                       | Purpose
--------|---------------------------------------------------------------------------|--------------------------------
proxy   | see table above | frontend server to serve for all endpoints (would be nginx in production)
sockets | [localhost:8080](http://localhost:8080) (socket.io) and [localhost:9080](http://localhost:9080) (admin api)   | nodejs/socket.io server managing socket.io connections from frontends
django  | [localhost:8000](http://localhost:8000)                                   | django application

You can view status of the processes:

```sh
pm2 list
```

... and control them by name, for example if you want to run django from your IDE, you can run:

```sh
pm2 stop django
```

## Custom settings

The setup script is intended to work in many unix-y environments but you might have some setup differences, you can set some options in `local_settings.make`:

Name     | Meaning                                                                               | Example
---------|---------------------------------------------------------------------------------------|-----------------------------
pg_user  | Which postgres role to use (in commands like `psql -U <pg_user>`)                     | `pg_user = mycustomuser`
pg       | How to run pg commands (psql,createdb,createuser) `$(1)` is replaced with the command | `pg = sudo -u $(pg_user) $(1)`

## postgres without sudo

Some OSes postgres package will require you to use `sudo` to become the `postgres` user. You can change this by modifying your `pg_hba.conf` file to include
an entry something like this:

```v
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
```

(this says: allow any local user on the machine to connect to any database)

## Custom virtualenv location

If you're using virtualenvwrapper or just want your virtualenv to be in a special location, first create a symlink and it will use that one, e.g.:

```
cd foodsaving-backend
rm -rf env # if present
ln -s ~/.envs/foodsaving-backend env
```
