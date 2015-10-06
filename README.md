# yunity-setup

This provides scripts to get the app up and running. The primary purpose is for developers to get up and running easily. Please create an issue if this doesn't work out the box for you, it's a work in progress :)

It helps you to:
- provide information on how to install system dependencies
- clone the seperate repos
- setup the application dependencies
- setup the database and run the migrations
- run/manage the application's processes using pm2

## Install system deps

You must first install:
- python3/virtualenv
- node/npm (should work with 0.12.x and 4.x)
- postgresql >9.4
- redis-server
- elasticsearch

You can check __some__ of the dependencies are present with:

```
make check-deps
```

### Ubuntu / Debian

```sh
sudo apt-get install gcc libffi-dev redis-server elasticsearch python3 python-dev python-virtualenv
```

#### postgresql 9.4 in Ubuntu >= 14.10

```sh
sudo apt-get install postgresql postgresql-server-dev-9.4
```

#### postgresql 9.4 in Ubuntu 14.04 and lower

```sh
deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update && sudo apt-get install postgresql-9.4 postgresql-server-dev-9.4
```

## Quick start

```sh
git clone git@github.com:yunity/yunity-setup.git yunity
cd yunity
make
```

To start all the services run:

```sh
pm2 start pm2.json
```

Then visit http://localhost:8090 to see the webapp and http://localhost:8091 for the mobile webapp.

## Endpoints

The proxy serves up the following endpoints you can visit:

URL                             | Purpose
--------------------------------|------------------------------------------------------------
http://localhost:8090/          | webapp served here
http://localhost:8090/api       | django api endpoint
http://localhost:8090/socket    | yunity-sockets socket.io endpoint
http://localhost:8090/socket.io | webapp webpack-dev-server socket.io endpoint
http://localhost:8091/          | mobile webapp served here
http://localhost:8091/api       | django api endpoint
http://localhost:8091/socket    | yunity-sockets socket.io endpoint
http://localhost:8091/socket.io | mobile webapp webpack-dev-server socket.io endpoint

This should be everything you need to hit, but for debugging you might want to hit endpoints directly (and also http://localhost:9080 to see which clients are connected to yunity-sockets)

You should end up with the following services running:

Name    | URL                                                                       | Purpose
--------|---------------------------------------------------------------------------|--------------------------------
proxy   | see table above | frontend server to serve for all endpoints (would be nginx in production)
web     | http://localhost:8083                                                     | webpack-dev-server serving up webapp  
mobile  | http://localhost:8084                                                     | webpack-dev-server serving up webapp mobile
sockets | http://localhost:8080 (socket.io) and http://localhost:9080 (admin api)   | nodejs/socket.io server managing socket.io connections from frontends
django  | http://localhost:8000                                                     | django application

You can view status of the processes:

```sh
pm2 list
```

... and control them by name, for example if you want to run django from your IDE, you can run:

```sh
pm2 stop django
```

## Updating

If you just want to generally update everything, you can run:

```sh
make
```

It runs idempotently and should always be safe to run.

This won't run any `git pull` commands, if you want this too, run:

```sh
make git-pull setup
```

## Add git hook to update common files automatically

```sh
cp ./yunity-webapp-common/scripts/post-merge ./.git/modules/yunity-webapp-common/hooks/
chmod +x ./.git/modules/yunity-webapp-common/hooks/post-merge
```

## Custom settings

The setup script is intended to work in many unix-y environments but you might have some setup differences, you can set some options in `local_settings.make`:

Name     | Meaning                                                                | Example
---------|------------------------------------------------------------------------|-----------------------------
pg_user  | Which postgres role to use (in commands like `psql -U <pg_user>`)     | pg_user=mycustomuser

## Custom virtualenv location

If you're using virtualenvwrapper or just want your virtualenv to be in a special location, first create a symlink and it will use that one, e.g.:

```
cd yunity-core
rm -rf env # if present
ln -s ~/.envs/yunity-core env
```

## Errors

You might have this error with django/python/crossbar:

```sh
crossbar-3 (err): pkg_resources.DistributionNotFound: The 'cryptography>=0.7' distribution was not found and is required by pyOpenSSL
```

if you get this kind of error message go into the yunity-core repository and force reinstall the requirements


```sh
cd yunity-core
./env/bin/pip install --force-reinstall --ignore-installed -r requirements.pip
pm2 restart all
```
