# yunity

This provides scripts to get the app up and running. The primary purpose is for developers to get up and running easily.

It helps you to:
- clone the seperate repos
- install/configure the application dependencies
- create the db/user and run the migations
- run the application using pm2

## Install system deps

You must first install:
- python3/virtualenv
- node/npm (should work with 0.12.x and 4.x)
- postgresql >9.4
- redis-server
- elasticsearch

### Ubuntu / Debian

```sh
sudo apt-get install gcc libffi-dev redis-server elasticsearch python3 python-dev python-virtualenv
```

### postgresql 9.4 in Ubuntu >= 14.10

```sh
sudo apt-get install postgresql postgresql-server-dev-9.4
```

### postgresql 9.4 in Ubuntu 14.04 and lower

```sh
deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update && sudo apt-get install postgresql-9.4 postgresql-server-dev-9.4
```

## Quick start

```sh
git clone git@github.com:yunity/yunity-setup.git
cd yunity-setup
make
```

To start all the services run:

```sh
pm2 start pm2.json
```

(You can stop individual services like `pm2 stop django`)

You can view status of the processes:

```sh
pm2 list
```

... and control them by name, for example if you want to run django from your IDE, you can run:

```sh
pm2 stop django
```

Please create an issue if this doesn't work out the box for you, this is only the first iteration :)

## Updating

If you just want to generally update everything, you can run:

```sh
make
```

It is designed to run idempotently.

## add git hook for update common files automaticly

```sh
cp ./yunity-webapp-common/scripts/post-merge ./.git/modules/yunity-webapp-common/hooks/
chmod +x ./.git/modules/yunity-webapp-common/hooks/post-merge
```

## Custom settings

The setup script is intended to work in many unix-y environments but you might have some setup differences, you can set some options in `local_settings.make`:

||Name||Meaning||Example||
|pg_user|Which postgres role to use (in commands like `pgsql -U <pg_user>`)|pg_user=mycustomuser|

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
