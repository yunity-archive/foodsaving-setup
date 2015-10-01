# yunity

This is the entry point to the other repos, it has:
- git submodules for the individual projects
- some make tasks for doing some setup/update
- a pm2 configuration for running the services in development

## install system deps
```
Ubuntu / Debian
sudo apt-get install gcc libffi-dev redis-server elasticsearch python3 python-dev python-virtualenv
```

## Quick start

```
git clone git@github.com:yunity/yunity.git
cd yunity
make setup
make
```

(the second call to `make` should be temporary, for some reason webpack doesn't build correctly first time round)

To start all the services run:

```
pm2 start pm2.json
```

(You can stop individual services like `pm2 stop django`)

Please create an issue if this doesn't work out the box for you, this is only the first iteration :)

## Initial setup

To do initial setup run:

```
make setup
```

This will:
- checkout the git submodules
- install all the python/npm/bower dependencies
- run the django migrations

It expects all __system__ things to be already installed:
- postgresql
- redis
- elasticsearch

## Updating

If you just want to generally update everything, you can run:

```
make
```