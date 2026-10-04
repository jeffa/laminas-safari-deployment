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

## Multi-architecture builds

After extracting the source into `app/`, maintainers can build both target
architectures locally:

```bash
bash bin/build-multiarch.sh
```

By default this validates the build into the BuildKit cache without publishing.
Set `BUILD_OUTPUT=/tmp/laminas-safari.oci.tar` if an OCI archive is needed. Set
`IMAGE_REPOSITORY` and `PUSH=1` after authenticating to a registry to publish a
multi-architecture image tagged with the full Git commit:

```bash
IMAGE_REPOSITORY=registry.example/laminas-safari PUSH=1 \
  bash bin/build-multiarch.sh
```

When running from a deployment copy without `.git`, provide the checked-in
revision explicitly with `GIT_COMMIT=<full-sha>`.

The GitHub Actions workflow is manually dispatched because the application source
and payloads are intentionally excluded from Git. It accepts a short-lived source
archive URL and its SHA-256 checksum, then performs the same amd64/arm64 build.

The workflow authenticates to the private Amazon ECR repository using GitHub
Actions OIDC and publishes only the immutable Git commit SHA tag:

```text
767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari:<commit-sha>
```

Before dispatching it, provide a short-lived URL for `input/laminas-app.tar.gz`
and its SHA-256 checksum. The workflow does not require AWS access keys in GitHub.
The IAM policy documents used to recreate the publisher role are in
`docs/aws/`.
