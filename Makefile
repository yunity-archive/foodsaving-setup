.PHONY: update setup git-pull npm-install bower-install webpack-build pip-install django-migrate

update: | git-pull npm-install bower-install webpack-build pip-install django-migrate

setup: | git-init update npm-deps npm-link

git-init:
	@echo $@
	@git submodule init
	@git submodule update --remote

git-pull:
	@echo $@
	@git submodule foreach git pull origin master

npm-install:
	@echo $@
	@npm install
	@cd yunity-webapp && npm install
	@cd yunity-webapp-mobile && npm install
	@cd yunity-webapp-common && npm install

bower-install: 
	@echo $@
	@cd yunity-webapp-mobile && bower install

pip-install: yunity-core/env
	@echo $@
	@cd yunity-core && env/bin/pip install -r requirements.pip

django-migrate: yunity-core/env
	@echo $@
	@cd yunity-core && env/bin/python manage.py migrate

yunity-core/env:
	@echo $@
	@virtualenv --python=python3 --no-site-packages yunity-core/env

npm-deps:
	@echo $@
	@sudo npm install -g bower webpack pm2

npm-link:
	@echo $@
	@cd yunity-webapp-common && sudo npm link
	@cd yunity-webapp && npm link yunity-webapp-common
	@cd yunity-webapp-mobile && npm link yunity-webapp-common

webpack-build:
	@echo $@
	@cd yunity-webapp && webpack
	@cd yunity-webapp-mobile && webpack
