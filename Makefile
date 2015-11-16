
# settings

pg_user = postgres

db_user = yunity-user
db_name = yunity-database
db_password = yunity

# $(1) will be replaced with a postgres tool (psql|createuser|createdb)
# you can override this in local_settings.make so make it use "sudo -u ", etc....

pg = $(1) -U $(pg_user)

PSQL = $(call pg,psql)
CREATEDB = $(call pg,createdb)
CREATEUSER = $(call pg,createuser)
DROPDB= $(call pg,dropdb)
DROPUSER= $(call pg,dropuser)

git_url_base = git@github.com:yunity/

# override settings, optionally

-include local_settings.make

# all yunity-* projects

project_dirs = yunity-core yunity-sockets yunity-webapp-common yunity-webapp yunity-webapp-mobile

.PHONY: setup update setup-core setup-sockets setup-webapp-common setup-webapp setup-webapp-mobile git-pull pip-install django-migrate init-db check-deps

# setup
#
# ensures all the source code for the projects is available
#  (will check it out if not)
# ensures database and users are created
# runs all the npm/bower/pip/django/migation steps
setup: setup-core setup-sockets setup-webapp-common setup-webapp setup-webapp-mobile setup-swagger-ui

# update
#
# updates self this repo
# then reruns make to do the actual setup
#
update:
	@echo && echo "# $@" && echo
	@git pull
	@make git-pull setup

setup-core: | yunity-core init-db pip-install django-migrate

setup-sockets: | yunity-sockets npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-sockets && npm-cache install npm --unsafe-perm

setup-webapp-common: | yunity-webapp-common npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp-common && npm-cache install npm

setup-webapp: | yunity-webapp-common yunity-webapp npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp && npm-cache install npm --unsafe-perm
	@cd yunity-webapp && npm-cache install bower --allow-root
	@rm -rf yunity-webapp/node_modules/yunity-webapp-common
	@cd yunity-webapp/node_modules && ln -s ../../yunity-webapp-common .
	@cd yunity-webapp && $$(npm bin)/webpack

setup-webapp-mobile: | yunity-webapp-common yunity-webapp-mobile npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp-mobile && npm-cache install npm --unsafe-perm
	@cd yunity-webapp-mobile && npm-cache install bower --allow-root
	@rm -rf yunity-webapp-mobile/node_modules/yunity-webapp-common
	@cd yunity-webapp-mobile/node_modules && ln -s ../../yunity-webapp-common .
	@cd yunity-webapp-mobile && $$(npm bin)/webpack

# setup-swagger-ui
#
# we use a custom swagger html page which
#   1. prepopulates the url inside the page with the correct one
#   2. adds django csrf headers to xhr requests
setup-swagger-ui: swagger-ui
	@cp index-yunity.html swagger-ui/swagger/dist/

swagger.tar.gz:
	@wget https://github.com/swagger-api/swagger-ui/archive/v2.1.3.tar.gz -O swagger.tar.gz

swagger-ui: swagger.tar.gz
	@tar zxvf swagger.tar.gz
	@mkdir -p swagger-ui
	@mv swagger-ui-2.1.3 swagger-ui/swagger
	@cd swagger-ui/swagger/dist && patch -p0 < ../../../swagger-ui.patch

# check-deps
#
# rudimentary check to see if we have the system deps we need
# ... not very sophisticated for now
check-deps:
	@echo && echo "# $@" && echo
	@(which psql >/dev/null && echo 'postgres found') || echo 'postgres missing'
	@(which redis-server >/dev/null && echo 'redis-server found') || echo 'redis-server missing'
	@(which elasticsearch >/dev/null && echo 'elasticsearch found') || echo 'elasticsearch missing'

# ensure each project folder is available or check it out if not
$(project_dirs):
	@echo && echo "# $@" && echo
	@git clone $(git_url_base)$@.git

# git-pull
#
# pull each of the projects
# but not this repo itself
git-pull:
	@echo && echo "# $@" && echo
	@for dir in $(project_dirs); do \
		echo "git pulling $$dir"; \
		cd $$dir && git pull --rebase; cd -; \
  done;

# init-db
#
# create database and user if they don't exist
init-db:
	@echo && echo "# $@" && echo
	@$(PSQL) postgres -tAc \
		"SELECT 1 FROM pg_roles WHERE rolname='$(db_user)'" | grep -q 1 || \
		$(PSQL) -tAc "create user \"$(db_user)\" with CREATEDB password '$(db_password)'"  || \
		echo "--> failed to create db user $(db_user), please set pg_user or pg in local_settings.make or ensure the default 'postgres' db role is available"
	@$(PSQL) postgres -tAc \
		"SELECT 1 FROM pg_database WHERE datname = '$(db_name)'" | grep -q 1 || \
		$(CREATEDB) $(db_name) || \
		echo "--> failed to create db user $(db_user), please set pg_user or pg in local_settings.make or ensure the default 'postgres' db role is available"

# drop-db
#
# drop db and user if they exist
drop-db:
	@echo && echo "# $@" && echo
	@$(DROPDB) $(db_name) --if-exists
	@$(DROPUSER) $(db_user) --if-exists

# recreate-db
#
# drop, then create
recreate-db: | drop-db init-db
	@echo && echo "# $@" && echo

# copy default dev local_settings.py with db details for django
yunity-core/config/local_settings.py:
	@echo && echo "# $@" && echo
	@cp local_settings.py.dev-default yunity-core/config/local_settings.py

# pip install env
pip-install: yunity-core/env
	@echo && echo "# $@" && echo
	@cd yunity-core && env/bin/pip install -r requirements.pip

# migrate django
django-migrate: yunity-core/env yunity-core/config/local_settings.py init-db
	@echo && echo "# $@" && echo
	@cd yunity-core && env/bin/python manage.py migrate

# virtualenv initialization
yunity-core/env:
	@echo && echo "# $@" && echo
	@virtualenv --python=python3 --no-site-packages yunity-core/env

# system-wide npm deps (TODO(ns) make nothing depend on global npm modules)
npm-system-deps:
	@echo && echo "# $@" && echo
	@which npm-cache || sudo npm install -g npm-cache
	@which bower || sudo npm install -g bower
	@which pm2 || sudo npm install -g pm2

# npm-deps
#
# install some npm stuff for the yunity-setup project
# mostly stuff for proxy.js...
npm-deps:
	@echo && echo "# $@" && echo
	@npm-cache install npm --unsafe-perm
