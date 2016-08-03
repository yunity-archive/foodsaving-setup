
# settings

pg_user = postgres

db_user = yunity-user
db_name = yunity-database
db_test_name = test_yunity-database
db_password = yunity

# $(1) will be replaced with a postgres tool (psql|createuser|createdb)
# you can override this in local_settings.make so make it use "sudo -u ", etc....

pg = $(1) -U $(pg_user)

PSQL = $(call pg,psql)
CREATEDB = $(call pg,createdb)
CREATEUSER = $(call pg,createuser)
DROPDB= $(call pg,dropdb)
DROPUSER= $(call pg,dropuser)

git_url_base = https://github.com/yunity/

# override settings, optionally

-include local_settings.make

# commands we can run a check for

deps := wget git postgres redis-server virtualenv node npm

# all yunity-* projects

frontend_project_dirs = yunity-webapp-mobile yunity-angular
backend_project_dirs = yunity-core yunity-sockets
project_dirs = $(frontend_project_dirs) $(backend_project_dirs)

.PHONY: setup update setup-core setup-sockets setup-webapp-mobile git-pull-frontend git-pull-backend pip-install migrate-db init-db check-deps $(deps)

# setup
#
# ensures all the source code for the projects is available
#  (will check it out if not)
# ensures database and users are created
# runs all the npm/pip/django/migation steps
setup: setup-backend setup-frontend

setup-backend: setup-core setup-sockets
setup-frontend: setup-webapp-mobile setup-angular


$(deps):
	@(which $@ >/dev/null 2>&1 && echo -e "$@ \xE2\x9C\x93") || echo -e "$@ \xE2\x9C\x95"

check-deps: $(deps)

# update
#
# updates self this repo
# then reruns make to do the actual setup
#
update:
	@echo && echo "# $@" && echo
	@git pull
	@make git-pull-backend git-pull-frontend setup

# update-backend
#
# just update backend stuff so don't have to wait for npm...
update-backend:
	@echo && echo "# $@" && echo
	@git pull
	@make git-pull-backend setup-backend

update-frontend:
	@echo && echo "# $@" && echo
	@git pull
	@make git-pull-frontend setup-frontend

setup-core: | yunity-core init-db pip-install migrate-db

setup-sockets: | yunity-sockets npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-sockets && npm install

setup-webapp-mobile: | yunity-webapp-mobile npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-webapp-mobile && npm install

build-webapp-mobile:
	@cd yunity-webapp-mobile && $$(npm bin)/webpack

setup-angular: | yunity-angular npm-deps npm-system-deps
	@echo && echo "# $@" && echo
	@cd yunity-angular && npm install

build-angular:
	@cd yunity-angular && $$(npm bin)/gulp webpack

# ensure each project folder is available or check it out if not
$(project_dirs):
	@echo && echo "# $@" && echo
	@git clone $(git_url_base)$@.git

git-pull-frontend:
	@echo && echo "# $@" && echo
	@for dir in $(frontend_project_dirs); do \
		echo "git pulling $$dir"; \
		cd $$dir && git pull --rebase; cd -; \
  done;

git-pull-backend:
	@echo && echo "# $@" && echo
	@for dir in $(backend_project_dirs); do \
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
	@$(DROPDB) $(db_test_name) --if-exists
	@$(DROPUSER) $(db_user) --if-exists

disconnect-db-sessions:
	@$(PSQL) postgres -tAc \
		"SELECT pg_terminate_backend(pid) FROM pg_stat_activity where datname IN ('${db_name}', '${db_test_name}');"

# recreate-db
#
# drop, then create
recreate-db: | disconnect-db-sessions drop-db init-db
	@echo && echo "# $@" && echo

# migate-db
#
# run django migrations
migrate-db: yunity-core/env yunity-core/config/local_settings.py init-db
	@echo && echo "# $@" && echo
	@cd yunity-core && env/bin/python manage.py migrate

# copy default dev local_settings.py with db details for django
yunity-core/config/local_settings.py:
	@echo && echo "# $@" && echo
	@cp local_settings.py.dev-default yunity-core/config/local_settings.py

# pip install env
pip-install: yunity-core/env
	@echo && echo "# $@" && echo
	@cd yunity-core && env/bin/pip install -r requirements.txt

# virtualenv initialization
yunity-core/env:
	@echo && echo "# $@" && echo
	@virtualenv --python=python3 --no-site-packages yunity-core/env

# system-wide npm deps (TODO(ns) make nothing depend on global npm modules)
npm-system-deps:
	@echo && echo "# $@" && echo
	@which pm2 || sudo npm install -g pm2

# npm-deps
#
# install some npm stuff for the yunity-setup project
# mostly stuff for proxy.js...
npm-deps:
	@echo && echo "# $@" && echo
	@npm install
