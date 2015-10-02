
# all yunity-* projects
project_dirs = yunity-core yunity-webapp-common yunity-webapp yunity-webapp-mobile

.PHONY: setup setup-core setup-webapp-common setup-webapp setup-webapp-mobile git-pull pip-install django-migrate init-db check-deps

setup: setup-core setup-webapp-common setup-webapp setup-webapp-mobile

setup-core: | yunity-core init-db pip-install django-migrate

setup-webapp-common: | yunity-webapp-common npm-deps
	@echo $@
	@cd yunity-webapp-common && npm-cache install npm
	@cd yunity-webapp-common && sudo npm link

setup-webapp: | yunity-webapp-common yunity-webapp npm-deps
	@echo $@
	@cd yunity-webapp && npm-cache install bower npm
	@cd yunity-webapp && npm link yunity-webapp-common
	@cd yunity-webapp && $$(npm bin)/webpack

setup-webapp-mobile: | yunity-webapp-common yunity-webapp-mobile npm-deps
	@echo $@
	@cd yunity-webapp-mobile && npm-cache install bower npm
	@cd yunity-webapp-mobile && npm link yunity-webapp-common
	@cd yunity-webapp-mobile && $$(npm bin)/webpack

# check deps

check-deps:
	@(which psql >/dev/null && echo 'postgres found') || echo 'postgres missing'
	@(which redis-server >/dev/null && echo 'redis-server found') || echo 'redis-server missing'
	@(which elasticsearch >/dev/null && echo 'elasticsearch found') || echo 'elasticsearch missing'

# git clone for each project

$(project_dirs):
	@echo $@
	@git clone git@github.com:yunity/$@.git

# git clone all projects

git-clone: $(project_dirs)

# git pull each project

git-pull:
	@for dir in $(project_dirs); do \
		echo "git pulling $$dir"; \
		cd $$dir && git pull; cd -; \
  done;

# create database and user if they don't exist

init-db:
	@echo $@
	@sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='yunity-user'" | grep -q 1 || sudo -u postgres createuser -s yunity-user
	@sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'yunity-database'" | grep -q 1 || sudo -u postgres createdb yunity-database

# copy default dev local_settings.py with db details for django

yunity-core/wuppdays/local_settings.py:
	@cp local_settings.py.dev-default yunity-core/wuppdays/local_settings.py

# pip install env

pip-install: yunity-core/env
	@echo $@
	@cd yunity-core && env/bin/pip install -r requirements.pip

# migrate django

django-migrate: yunity-core/env yunity-core/wuppdays/local_settings.py init-db
	@echo $@
	@cd yunity-core && env/bin/python manage.py migrate

# virtualenv initialization

yunity-core/env:
	@echo $@
	@virtualenv --python=python3 --no-site-packages yunity-core/env

# system-wide npm deps (TODO(ns) make nothing depend on global npm modules)

npm-deps:
	@echo $@
	@which npm-cache || sudo npm install -g npm-cache
	@which bower || sudo npm install -g bower
	@which pm2 || sudo npm install -g pm2
