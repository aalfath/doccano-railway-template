# Doccano on Railway

This repo is the source of the **Doccano** template on Railway. It deploys
[Doccano](https://github.com/doccano/doccano) **1.8.5**, an open-source text
annotation tool for building labelled datasets (text classification, sequence
labelling, sequence-to-sequence, image and audio tasks).

## What the template deploys

| Service | Source | Purpose |
|---|---|---|
| `Doccano` | this repo (`Dockerfile`) | Official `doccano/doccano:1.8.5` image pinned by digest: Django API + web UI (gunicorn) and the Celery worker that runs imports and exports |
| `Postgres` | Railway Postgres | Projects, users, annotations, and the Celery task queue |

- Uploaded files (images, audio, import files) are stored on a volume mounted at `/data`.
- The public domain serves the UI on port 8000. Health check: `/v1/health/`
  (checks the database, Celery, file storage and migrations).
- No sign-up page: the admin creates further users in the Django admin at `/admin/`.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_USERNAME` | `admin` | Admin user created on the first start |
| `ADMIN_PASSWORD` | generated secret | Admin password. Read it in the service's **Variables** tab. Changing it later doesn't change the existing user's password (use **Settings** in the UI or `/admin/`) |
| `ADMIN_EMAIL` | empty (optional) | Admin's email address; falls back to `admin@example.com` |
| `SECRET_KEY` | generated secret | Django secret key |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Private-network connection to Postgres |
| `PORT` | `8000` | Port gunicorn listens on |

Optional, set them yourself if you need them: `WORKERS` and `CELERY_WORKERS`
(default 2 each), `MAX_UPLOAD_SIZE`, `EMAIL_HOST` / `EMAIL_PORT` /
`EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` / `EMAIL_USE_TLS`, and the OAuth
settings from the [Doccano docs](https://doccano.github.io/doccano/).

## What the wrapper does

`railway-start.sh` runs before the upstream `/doccano/tools/run.sh`:

1. creates `/data/media` and gives the volume to the image's `doccano` user, then drops root;
2. refuses to start with an empty or default (`password`) admin password;
3. adds `sslmode=prefer` to a Postgres `DATABASE_URL` (Doccano otherwise requires SSL);
4. trusts `https://$RAILWAY_PUBLIC_DOMAIN` for CSRF and turns on secure cookies.

## Updates

Services built from this repo get Railway's "update available" notice when a
change is merged to `main`. Each update bumps the pinned image in the
`Dockerfile` and is described in [CHANGELOG.md](CHANGELOG.md); read it before
you apply an update. Back up your Postgres data before applying a new Doccano
version.

## Run it locally

```sh
docker build -t doccano-railway .
docker run -p 8000:8000 -e ADMIN_PASSWORD=change-this-now -v doccano-data:/data doccano-railway
```

Without `DATABASE_URL` the image uses SQLite at `/data/doccano.db`.

## License

The wrapper files are MIT. Doccano is MIT-licensed by its authors.
