
# gets directory of this script
# see http://stackoverflow.com/a/246128/2922612
base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $base/yunity-core/env/bin/activate

function pym() {
  (cd $base/yunity-core && env/bin/python manage.py "$@")
}

function ymake() {
  make -C $base "$@"
}

function ypm2() {
  (cd $base && pm2 "$@")
}

function container-exists() {
  docker inspect $1 >/dev/null 2>&1
}

function wait-for-postgres() {
  while ! psql -h localhost -p 5432 -w -U postgres -c 'select 1' >/dev/null 2>&1; do
    echo -n .
    sleep 1
  done
  echo " connected!"
}

function docker-up() {

  if ! container-exists yunity-redis; then
    docker run -p 6379:6379 --name yunity-redis -d redis
  fi

  if ! container-exists yunity-postgres; then
    echo "initialing postgres!"
    docker run -p 5432:5432 --name yunity-postgres -e POSTGRES_PASSWORD= -d postgres
    echo -n "Waiting for postgres to start..."
    wait-for-postgres
  fi

  ymake migrate-db

}

function docker-start() {
  docker start yunity-postgres
  docker start yunity-redis
}

function docker-stop() {
  docker stop yunity-postgres
  docker stop yunity-redis
}

function docker-down() {
  if container-exists yunity-postgres; then
    docker rm -f yunity-postgres
  fi
  if container-exists yunity-redis; then
    docker rm -f yunity-redis
  fi
}

