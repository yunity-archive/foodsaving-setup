# yunity

This is the entry point to the other repos, it has:
- git submodules for the individual projects
- some make tasks for doing some setup/update
- a pm2 configuration for running the services in development

## install system deps
```sh
Ubuntu / Debian
sudo apt-get install gcc libffi-dev redis-server elasticsearch python3 python-dev python-virtualenv
```

## Quick start

```sh
git clone git@github.com:yunity/yunity.git
cd yunity
make setup
make
```

(the second call to `make` should be temporary, for some reason webpack doesn't build correctly first time round)

To start all the services run:

```sh
pm2 start pm2.json
```

(You can stop individual services like `pm2 stop django`)

Please create an issue if this doesn't work out the box for you, this is only the first iteration :)

## Initial setup

To do initial setup run:

```sh
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

```sh
make
```

## add git hook for update common files automaticly

```sh
cp ./yunity-webapp-common/scripts/post-merge ./.git/modules/yunity-webapp-common/hooks/
chmod +x ./.git/modules/yunity-webapp-common/hooks/post-merge
```

## maybe error
```sh
crossbar-3 (err): pkg_resources.DistributionNotFound: The 'cryptography>=0.7' distribution was not found and is required by pyOpenSSL
```
if you get this kind of error message go into the yunity-core repository and force reinstall the requirements

```sh
cd yunity-core
./env/bin/pip install --force-reinstall --ignore-installed -r requirements.pip
pm2 restart all
```