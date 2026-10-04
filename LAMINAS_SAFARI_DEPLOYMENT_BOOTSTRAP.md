# Laminas Safari Deployment Bootstrap Instructions

This document is a handoff for starting the separate `laminas-safari-deployment`
project after leaving the shared `ec2-instances` laboratory.

The new project should focus on building, publishing, pulling, and running the
Laminas application image. It should not contain the generic EC2 compatibility
laboratory, WordPress files, or unrelated Terraform and Ansible experiments.

## New project location

Create or select a fresh project directory, for example:

```text
/Users/jeffa/CODE/BridgeTechDynamics/laminas-safari-deployment
```

Initialize it as a new Git repository or connect it to its new GitHub repository.
The old `ec2-instances` repository remains the historical EC2 laboratory and should
not be deleted from GitHub.

## Recommended initial layout

Create these directories and files:

```text
laminas-safari-deployment/
├── README.md
├── Dockerfile
├── compose.yaml
├── compose.build.yaml
├── .env.example
├── .gitignore
├── app/                         # ignored; extracted application source
├── input/                       # ignored; source and database payloads
│   ├── laminas-app.tar.gz
│   └── horsesns_safari-dev.sql.gz
├── runtime-config/
│   └── local.php
├── apache-vhost.conf
├── bin/
│   ├── extract-source.sh
│   ├── build-image.sh
│   ├── publish-image.sh
│   ├── pull-image.sh
│   ├── restore-database.sh
│   └── run-local.sh
├── docs/
│   ├── DOCKER.md
│   ├── ENVIRONMENT.md
│   ├── SECRETS.md
│   └── PRODUCTION_ROADMAP.md
└── .github/
    └── workflows/
        └── build-image.yml
```

The exact scripts can be created incrementally. The directory structure is the
important initial boundary.

## Files to bring from the existing project

Copy or adapt only the Laminas-specific files from the old repository:

```text
laminas-dev/Dockerfile             → Dockerfile
laminas-dev/compose.yaml           → compose.yaml baseline
laminas-dev/.env.example           → .env.example
laminas-dev/runtime-config/local.php → runtime-config/local.php
laminas-dev/apache-vhost.conf      → apache-vhost.conf
```

The existing Laminas documentation can be copied into `docs/` from:

```text
projects/laminas-safari/
```

The old EC2-specific scripts under `bin/laminas-dev/remote/` should not be copied
as the primary workflow. Their responsibilities will be replaced by image pull,
Compose startup, and database initialization scripts. Keep the old scripts in the
EC2 laboratory repository as a fallback until the new workflow is proven.

## Payload placement

The payload directory must remain outside Git history:

```text
laminas-safari-deployment/input/laminas-app.tar.gz
laminas-safari-deployment/input/horsesns_safari-dev.sql.gz
```

The source tarball should be extracted into:

```text
laminas-safari-deployment/app/
```

The `app/` directory must remain ignored. It contains the application source and
vendor data used to build the image, not the deployment configuration repository.

The database dump is development data and must also remain ignored. It is used to
initialize disposable local or integration databases and should not be committed.

## Initial `.gitignore`

The new project should at least ignore:

```gitignore
.env
input/
app/
vendor/
*.log
.db-restored
deploy.log
.DS_Store
```

Commit only an `.env.example` containing empty placeholders and safe defaults.

## Compose responsibilities

The new project should eventually have two Compose modes:

### Prebuilt image mode

`compose.yaml` should pull a tagged application image from Amazon ECR. This is the
normal developer and deployment workflow. Developers should not need to build the
image.

### Build mode

`compose.build.yaml` should be used by maintainers or CI when building the image
from the application source. It may add the `build:` configuration to the base
Compose model.

The application image should be published for both architectures:

```text
linux/amd64   # EC2 and Intel/AMD PCs
linux/arm64   # Apple Silicon Macs
```

The final image should be tagged with an immutable Git commit or release tag.

## First-session objectives

After the new workspace is available, the next session should work through these
objectives in order:

1. Create the directory structure and initial `.gitignore`.
2. Copy the Dockerfile, Compose baseline, runtime configuration, and Apache config.
3. Place the two ignored payloads under `input/`.
4. Extract the application into ignored `app/`.
5. Separate build-mode and prebuilt-image Compose configuration.
6. Run the stack locally on Apple Silicon without building if a prebuilt image is available.
7. Add a reproducible multi-architecture Buildx workflow.
8. Publish the image to a private ECR repository.
9. Update EC2 deployment to pull the same image rather than build it on the instance.

## Important constraints

- Do not copy Terraform or the generic Ansible playbooks into this project.
- Do not copy WordPress files.
- Do not commit the application source tarball or database dump.
- Do not commit `.env`, `local.php` containing secrets, or any credentials.
- Do not make developers build the image as part of normal use.
- Keep the first working EC2 deployment available in the old repository until the
  new image-publishing workflow has been tested.

## Handoff note for the next session

Begin by reading this file, listing the new directory, and confirming the two payload
files are present under `input/`. Then inspect the copied Dockerfile and Compose
configuration before making changes. The goal is a clean, prebuilt-image workflow
that supports EC2, Apple Silicon Macs, and Intel/AMD PCs from one tagged image.

