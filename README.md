# Laminas Safari Deployment

Container build and deployment configuration for the Laminas Safari application.

The normal Compose workflow uses a prebuilt image. Maintainers and CI can opt into
the source build with `compose.build.yaml`.

## First setup

```bash
cp .env.example .env
bash bin/extract-source.sh
```

Edit `.env` with local database credentials and an image reference, then start the
prebuilt stack with `docker compose up -d`.

See [docs/DOCKER.md](docs/DOCKER.md) for the local build and database restore
workflow. Payloads in `input/` and extracted source in `app/` are intentionally
ignored by Git.

