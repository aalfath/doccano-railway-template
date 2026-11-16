# Doccano for Railway: the official all-in-one image (Django + gunicorn + Celery
# + the built Vue frontend), pinned by version and digest, plus a small start
# script for Railway volumes, Postgres SSL and HTTPS cookies.
FROM doccano/doccano:1.8.5@sha256:04ad3a60c76bca4e134d770119f5489f9cb33ef2c79ea875288e278d4373b872

USER root
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

# Uploaded files (images, audio, import files) live on the /data volume.
ENV MEDIA_ROOT=/data/media \
    PORT=8000

EXPOSE 8000
CMD ["/usr/local/bin/railway-start.sh"]
