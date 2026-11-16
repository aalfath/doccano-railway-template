#!/bin/sh
# Start wrapper for the Doccano Railway template.
# Runs as root only to fix volume ownership, then drops to the image's
# "doccano" user and hands over to the upstream /doccano/tools/run.sh.
set -eu

DATA_DIR=/data
mkdir -p "$DATA_DIR/media"
# Railway volumes are mounted root-owned; the app runs as "doccano".
if [ "$(stat -c %U "$DATA_DIR")" != "doccano" ] || [ "$(stat -c %U "$DATA_DIR/media")" != "doccano" ]; then
  chown -R doccano:doccano "$DATA_DIR"
fi

# Admin account (created on first start only).
export ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
if [ -z "${ADMIN_PASSWORD:-}" ] || [ "${ADMIN_PASSWORD}" = "password" ]; then
  echo "ADMIN_PASSWORD is empty or the upstream default; set a strong ADMIN_PASSWORD." >&2
  exit 1
fi

# Django secret key: use the template's generated value, otherwise keep a
# random one on the volume so sessions survive redeploys.
if [ -z "${SECRET_KEY:-}" ] || [ "${SECRET_KEY}" = "change-me-in-production" ]; then
  if [ ! -s "$DATA_DIR/.secret_key" ]; then
    python -c 'import secrets; print(secrets.token_urlsafe(50))' > "$DATA_DIR/.secret_key"
    chown doccano:doccano "$DATA_DIR/.secret_key"
    chmod 600 "$DATA_DIR/.secret_key"
  fi
  SECRET_KEY="$(cat "$DATA_DIR/.secret_key")"
  export SECRET_KEY
fi

# Postgres: Doccano requires SSL unless the URL says otherwise. Railway's
# private network doesn't need it, so prefer SSL instead of requiring it.
# Without DATABASE_URL the image falls back to SQLite on /data/doccano.db.
case "${DATABASE_URL:-}" in
  postgres://*|postgresql://*)
    case "$DATABASE_URL" in
      *sslmode=*) ;;
      *\?*) DATABASE_URL="${DATABASE_URL}&sslmode=prefer" ;;
      *) DATABASE_URL="${DATABASE_URL}?sslmode=prefer" ;;
    esac
    export DATABASE_URL
    ;;
esac

# Behind Railway's HTTPS proxy: trust the public origin and use secure cookies.
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export CSRF_TRUSTED_ORIGINS="${CSRF_TRUSTED_ORIGINS:-https://${RAILWAY_PUBLIC_DOMAIN}}"
  export SESSION_COOKIE_SECURE="${SESSION_COOKIE_SECURE:-True}"
  export CSRF_COOKIE_SECURE="${CSRF_COOKIE_SECURE:-True}"
fi

export PORT="${PORT:-8000}"
export WORKERS="${WORKERS:-2}"
export CELERY_WORKERS="${CELERY_WORKERS:-2}"
export HOME=/home/doccano

cd /doccano/backend
exec setpriv --reuid=doccano --regid=doccano --init-groups /doccano/tools/run.sh
