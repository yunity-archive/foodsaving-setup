.PHONY: update setup git-pull npm-install bower-install webpack-build pip-install django-migrate

update: git-pull npm-install bower-install webpack-build pip-install django-migrate

setup: update npm-deps npm-link

git-pull:
	@git submodule foreach git pull origin master

npm-install:
	@npm install
	@cd yunity-webapp && npm install
	@cd yunity-webapp-mobile && npm install
	@cd yunity-webapp-common && npm install

bower-install:
	@cd yunity-webapp-mobile && bower install

pip-install: yunity-core/env
	@cd yunity-core && env/bin/pip install -r requirements.pip

django-migrate: yunity-core/env
	@cd yunity-core && env/bin/python manage.py migrate

yunity-core/env:
	@virtualenv --python=python3 --no-site-packages yunity-core/env

npm-deps:
	@sudo npm install -g bower webpack

npm-link:
	@cd yunity-webapp-common && sudo npm link
	@cd yunity-webapp && npm link yunity-webapp-common
	@cd yunity-webapp-mobile && npm link yunity-webapp-common

webpack-build:
	@cd yunity-webapp && webpack
	@cd yunity-webapp-mobile && webpack
