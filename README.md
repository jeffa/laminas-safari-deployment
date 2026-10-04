# Laminas Safari Deployment

Container build and deployment configuration for the Laminas Safari application.

The normal Compose workflow uses a prebuilt image. Maintainers and CI can opt into
the source build with `compose.build.yaml`.

## First setup

```bash
cp .env.example .env
bash bin/extract-source.sh
```

Edit `.env` with local database credentials and an image reference. For the
source-build workflow, run:

```bash
bash bin/run-local.sh
```

The script extracts the ignored source payload when needed, builds the image,
starts MariaDB, restores the development dump when the schema is absent, starts
Apache, clears the Laminas config cache, and verifies HTTP plus PHP platform
requirements. The safe environment-driven Laminas runtime configuration is baked
into the image, so the prebuilt workflow does not require a host-side config-file
bind mount. To run a prebuilt image directly, use `docker compose up -d`.

See [docs/DOCKER.md](docs/DOCKER.md) for the local build and database restore
workflow. Payloads in `input/` and extracted source in `app/` are intentionally
ignored by Git.

For the temporary EC2 test workflow, set `EC2_USER` and `EC2_HOST`, then run
`bash bin/deploy-test.sh`. It copies the deployment files and ignored payloads,
but never copies `.env` or the extracted application source.
