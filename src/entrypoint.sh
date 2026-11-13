#!/bin/sh
# ===========================================================================
# Healthchecks entrypoint for a non-root container (TOS 7 requirement).
#
# The LinuxServer.io image runs its init script and uWSGI through s6 as root:
# s6 cannot start inside a container that already runs as uid 1000. This
# wrapper:
#   1. copies the Django app to /tmp/hc (the image directory is read-only),
#   2. seeds /config/local_settings.py on first start (SECRET_KEY, ALLOWED_HOSTS,
#      SITE_ROOT - the last one is user-editable),
#   3. links the local settings and the SQLite database into the copy,
#   4. runs the migrations and starts uWSGI directly as uid 1000.
# ===========================================================================
set -e
set -u

CONFIG=/config
APP=/tmp/hc

mkdir -p "$CONFIG" "$APP" 2>/dev/null || true
cp -a /app/healthchecks/. "$APP"/

if [ ! -s "$CONFIG/local_settings.py" ]; then
  SECRET=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
  cat > "$CONFIG/local_settings.py" <<EOF
SECRET_KEY = "$SECRET"
ALLOWED_HOSTS = ["*"]
# Absolute links in notification emails are built from this value.
# Change it to your NAS URL (e.g. http://192.168.1.10:8053) and restart.
SITE_ROOT = "http://localhost:8000"
EOF
  echo "healthchecks: seeded $CONFIG/local_settings.py"
fi

ln -sf "$CONFIG/local_settings.py" "$APP/hc/local_settings.py"
ln -sf "$CONFIG/hc.sqlite" "$APP/hc.sqlite"
cp -n /defaults/uwsgi.ini "$APP/uwsgi.ini" 2>/dev/null || true

cd "$APP"
python3 manage.py migrate --noinput

exec /usr/sbin/uwsgi --ini "$APP/uwsgi.ini"
