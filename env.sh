
# gets directory of this script
# see http://stackoverflow.com/a/246128/2922612
base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function pym() {
  (cd $base/yunity-core && env/bin/python manage.py "$@")
}

function ymake() {
  make -C $base "$@"
}

function ypm2() {
  (cd $base && pm2 "$@")
}
