
# settings

pg_user = postgres

# $(1) will be replaced with a postgres tool (psql|createuser|createdb)
# you can override this in local_settings.make so make it use "sudo -u ", etc....

pg = $(1) -U $(pg_user)

PSQL = $(call pg,psql)
CREATEDB = $(call pg,createdb)
CREATEUSER = $(call pg,createuser)

git_url_base = git@github.com:yunity/

# override settings, optionally

-include local_settings.make

# all yunity-* projects

project_dirs = yunity-core yunity-sockets yunity-webapp-common yunity-webapp yunity-webapp-mobile

.PHONY: setup setup-core setup-sockets setup-webapp-common setup-webapp setup-webapp-mobile git-pull pip-install django-migrate init-db check-deps

setup: setup-core setup-sockets setup-webapp-common setup-webapp setup-webapp-mobile

setup-core: | yunity-core init-db pip-install django-migrate

setup-sockets: | yunity-sockets npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-sockets && npm-cache install npm

setup-webapp-common: | yunity-webapp-common npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp-common && npm-cache install npm

setup-webapp: | yunity-webapp-common yunity-webapp npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp && npm-cache install bower npm
	@rm -rf yunity-webapp/node_modules/yunity-webapp-common
	@cd yunity-webapp/node_modules && ln -s ../../yunity-webapp-common .
	@cd yunity-webapp && $$(npm bin)/webpack

setup-webapp-mobile: | yunity-webapp-common yunity-webapp-mobile npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp-mobile && npm-cache install bower npm
	@rm -rf yunity-webapp-mobile/node_modules/yunity-webapp-common
	@cd yunity-webapp-mobile/node_modules && ln -s ../../yunity-webapp-common .
	@cd yunity-webapp-mobile && $$(npm bin)/webpack

# check deps

check-deps:
	@echo && echo "# $@" && echo
	@(which psql >/dev/null && echo 'postgres found') || echo 'postgres missing'
	@(which redis-server >/dev/null && echo 'redis-server found') || echo 'redis-server missing'
	@(which elasticsearch >/dev/null && echo 'elasticsearch found') || echo 'elasticsearch missing'

# git clone for each project

$(project_dirs):
	@echo && echo "# $@" && echo
	@git clone $(git_url_base)$@.git

# git clone all projects

git-clone: $(project_dirs)
	@echo && echo "# $@" && echo

# git pull each project

git-pull:
	@echo && echo "# $@" && echo
	@git pull
	@for dir in $(project_dirs); do \
		echo "git pulling $$dir"; \
		cd $$dir && git pull; cd -; \
  done;

# create database and user if they don't exist

init-db:
	@echo && echo "# $@" && echo
	@$(PSQL) -U $(pg_user) postgres -tAc \
		"SELECT 1 FROM pg_roles WHERE rolname='yunity-user'" | grep -q 1 || \
		$(CREATEUSER) -U $(pg_user) -s yunity-user || \
		echo "--> failed to create db user yunity-user, please set a pg_user in local_settings.make or ensure the default 'postgres' db role is available"
	@$(PSQL) -U $(pg_user) postgres -tAc \
		"SELECT 1 FROM pg_database WHERE datname = 'yunity-database'" | grep -q 1 || \
		$(CREATEDB) -U $(pg_user) yunity-database || \
		echo "--> failed to create db user yunity-user, please set a pg_user in local_settings.make or ensure the default 'postgres' db role is available"

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

npm-deps:
	@echo && echo "# $@" && echo
	@npm-cache install npm
