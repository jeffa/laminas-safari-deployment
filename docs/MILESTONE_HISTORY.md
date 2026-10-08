# Laminas Safari Deployment Milestone History

This document explains how the deployment project changed as each milestone was
completed. It is both a project record and a study guide: each section describes
the starting point, the resulting change, the benefit, and the concepts worth
learning more deeply.

The milestones are cumulative. Later stages depend on the boundaries and
repeatability established by the earlier ones.

## Starting point

Before this project was created, the Laminas application was being developed on
a shared server that combined several responsibilities:

- the web server;
- the database server;
- application files and configuration;
- deployment work performed manually over SSH or through cPanel.

The original `ec2-instances` project was a useful laboratory, but it also
contained general EC2, Terraform, Ansible, and unrelated application material.
This project was created to isolate the Laminas application image and its
deployment workflow.

The two important payloads were intentionally kept outside Git:

- the Laminas source archive;
- the development database dump.

That separation is important. The deployment repository contains the recipe for
building and running the application, while the payloads contain application
source and data that should not be committed casually.

## Milestone 1: Project scaffold and source extraction

### Before

The Laminas deployment instructions and files were mixed with the older EC2
laboratory. There was no clean project boundary for the application image, and
the source archive had to be handled manually.

### After

The new repository established a focused structure:

```text
laminas-safari-deployment/
├── Dockerfile
├── compose.yaml
├── compose.build.yaml
├── runtime-config/
├── patches/
├── bin/
├── docs/
└── input/                  # ignored payloads
```

The source archive is extracted into the ignored `app/` directory by:

```sh
bash bin/extract-source.sh
```

The repository also established the first security boundary:

- deployment configuration is committed;
- application source payloads are ignored;
- database dumps are ignored;
- `.env` is ignored;
- only safe examples and documentation belong in Git.

### Why this was better

This made the project portable and easier to reason about. A new checkout has a
known structure, while the sensitive or bulky inputs can be supplied separately.
It also prevents an accidental source archive, database dump, or environment
file from becoming part of Git history.

This was not yet a complete deployment platform. It was the foundation needed
to make later builds repeatable.

### Concepts to study

- Git repository boundaries and `.gitignore`.
- Build context versus source repository.
- Artifact, configuration, and secret separation.
- Shell scripts using `set -Eeuo pipefail`.
- Why archives and database dumps should be treated as deployment inputs.

### Relevant files

- [Bootstrap instructions](../LAMINAS_SAFARI_DEPLOYMENT_BOOTSTRAP.md)
- [Source extraction script](../bin/extract-source.sh)
- [Secrets guidance](SECRETS.md)

## Milestone 2: Local build, database restore, and run scripts

### Before

The application could be placed on a server, but the steps were mostly manual:

1. copy files;
2. build an image;
3. start a database;
4. import a database dump;
5. start the application;
6. clear caches and test the site.

Manual sequences are easy to perform differently on different machines. A
mistyped database hostname, an already-initialized database, or a missing cache
clear could produce confusing results.

### After

The workflow was divided into explicit Compose and shell-script responsibilities.

`compose.yaml` became the normal runtime definition for:

- the Laminas application container;
- the MariaDB container;
- the private database volume;
- service health checks;
- environment-variable wiring;
- the application port.

`compose.build.yaml` became a small build override. It adds the Docker build
context without changing the normal prebuilt-image Compose definition.

The scripts now cover the repeatable sequence:

| Script | Responsibility |
| --- | --- |
| `extract-source.sh` | Extract the ignored source archive into `app/` |
| `build-image.sh` | Build the application image through Compose |
| `restore-database.sh` | Start MariaDB and restore the dump when needed |
| `run-local.sh` | Orchestrate build, database, restore, app startup, and checks |

The resulting local command is:

```sh
bash bin/run-local.sh
```

The run script waits for services, clears the Laminas configuration cache,
checks HTTP readiness, and runs Composer platform checks. The database restore
also avoids repeating the import when the expected schema is already present,
unless `FORCE_DB_RESTORE=1` is requested.

### Why this was better

The setup became repeatable instead of being a collection of remembered shell
commands. Failures became easier to locate because each responsibility has a
named script and each service has a health check.

The database is still disposable development state. That is intentional at this
stage: it gives developers a known starting point without pretending that a
local MariaDB volume is production database infrastructure.

### Concepts to study

- Docker images, containers, volumes, and networks.
- Compose service names, especially why the database hostname is `db` rather
  than `localhost`.
- Compose override files.
- Container health checks and startup ordering.
- Idempotent scripts: safely running the same operation more than once.
- Database dump restoration and disposable development data.
- Runtime configuration versus configuration baked into an image.

### Relevant files

- [Docker workflow](DOCKER.md)
- [Compose runtime definition](../compose.yaml)
- [Compose build override](../compose.build.yaml)
- [Local run script](../bin/run-local.sh)
- [Database restore script](../bin/restore-database.sh)

## Milestone 3: Multi-architecture Buildx workflow

### Before

The image could be built for the machine performing the build. That is not
enough when the deployment targets are different:

- AWS EC2 commonly runs `linux/amd64`;
- the developer iMac may run `linux/arm64`;
- other developer machines may use either architecture.

A single-architecture image can work perfectly on one machine and fail to pull
or run on another.

### After

`bin/build-multiarch.sh` was added to build a single image reference containing
both target platforms:

```text
linux/amd64
linux/arm64
```

The script uses Docker Buildx and a containerized BuildKit builder. It also:

- tags the image with a full Git commit SHA by default;
- supports an explicit `GIT_COMMIT` for source-only deployment copies;
- records OCI revision and source labels;
- supports SBOM and provenance metadata;
- can validate into the BuildKit cache without pushing;
- can optionally export an OCI archive;
- can publish when `PUSH=1` is supplied.

The GitHub Actions workflow uses the same essential build idea and adds QEMU
emulation so the runner can produce both architectures.

### Why this was better

One immutable image tag can now serve EC2 and Apple Silicon Docker Desktop. The
developer does not need to rebuild the application locally merely because their
computer has a different CPU architecture.

The commit-SHA tag also connects a running image to the exact deployment source
revision. That is substantially safer than relying on a mutable `latest` tag.

This milestone also exposed an operational lesson: Buildx is a separate Docker
capability. A Docker Engine installation may work while the `docker buildx`
plugin is absent or too old. The host provisioning process therefore needs to
install and verify Buildx where local or EC2 builds are expected.

### Concepts to study

- CPU architecture and platform-specific container images.
- Docker manifest lists and multi-platform image indexes.
- Buildx and BuildKit.
- QEMU emulation and why it can make builds slower.
- Immutable tags versus mutable tags.
- OCI image labels, provenance, and SBOMs.
- Build cache size and disk-space management.

### Relevant files

- [Multi-architecture build script](../bin/build-multiarch.sh)
- [GitHub image workflow](../.github/workflows/build-image.yml)
- [Docker documentation](DOCKER.md)

## Milestone 4: Private ECR publish/pull workflow

### Before

The multi-architecture image could be built, but there was no controlled image
registry workflow. An EC2 host would still need to build from source or receive
large deployment payloads directly.

That created several problems:

- building consumed significant EC2 disk space;
- the server was doing work better suited to CI;
- the image was not centrally versioned;
- developers and servers did not have one shared image artifact;
- access to the image was not yet separated into publishing and pulling.

### After

A private Amazon ECR repository was created:

```text
767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari
```

The GitHub Actions workflow now:

1. receives a short-lived source archive URL and SHA-256 checksum manually;
2. downloads and verifies the source archive;
3. authenticates to AWS using GitHub OIDC;
4. logs into ECR;
5. builds `linux/amd64` and `linux/arm64` images;
6. publishes the image under the full Git commit SHA.

The AWS permissions were separated by job:

- `GitHubActionsLaminasEcrPublisher` can publish images;
- `EC2LaminasEcrPuller` can pull images for an EC2 deployment;
- a developer permission set can pull images from ECR without administering
  AWS or publishing images.

The GitHub role does not use a long-lived AWS access key. Its trust policy
accepts a GitHub Actions OIDC token for the permitted repository and branch.
The EC2 host uses an instance role, so the host also avoids storing AWS keys.

The image was pulled into EC2 and passed a full browser smoke test, including:

- loading the application;
- submitting the password-reset form;
- receiving the reset email;
- changing the password;
- logging in with the new password.

The known-good image was published under a commit-SHA tag and verified on EC2.

### Why this was better

The build responsibility moved away from the small EC2 host. The host can pull
the exact image it needs instead of carrying the source archive, Composer build
work, and multi-architecture tooling.

The same image artifact can be used by CI, EC2, and developer Docker Desktop.
Private ECR also establishes an access boundary: publishing, server pulling,
and developer pulling are different permissions.

OIDC and instance roles reduce the number of long-lived credentials that could
be accidentally copied into GitHub, a laptop, or an EC2 filesystem.

### Concepts to study

- Amazon ECR repositories, image tags, and digests.
- IAM policies versus IAM trust policies.
- GitHub Actions OIDC and `AssumeRoleWithWebIdentity`.
- AWS IAM Identity Center and permission sets.
- EC2 instance profiles and temporary credentials.
- Least privilege: publish access versus pull access.
- Authentication to a private container registry.
- Why a successful image push does not prove a successful application deploy.

### Relevant files

- [GitHub Actions ECR workflow](../.github/workflows/build-image.yml)
- [ECR IAM documentation](aws/README.md)
- [Publisher policy](aws/ecr-publisher-permissions-policy.json)
- [Puller policy](aws/ecr-puller-permissions-policy.json)
- [Developer AWS access setup](DEVELOPER_AWS_ACCESS_SETUP.md)
- [Developer Docker Desktop setup](DEVELOPER_DOCKER_DESKTOP_SETUP.md)

## Milestone 5: Developer sandboxes and Integration environment

This is the next platform milestone. Milestone 4A was an enabling workstream,
not a replacement milestone. It covered repository ownership, developer AWS
access, Docker Desktop onboarding, secret handling, and application fixes that
needed to be resolved before the broader team workflow could begin.

### Target state

Each developer can run an isolated copy of the approved application image in
Docker Desktop with controlled development data. A separate Integration
environment can run an approved image and database snapshot for complete
workflow testing before Production.

### Planned workflow

```text
Developer sandbox
        |
        v
Code review and image build
        |
        v
Integration environment
        |
        v
Production release
```

The sandbox and Integration environment must use separate credentials from
Production. The Integration environment is the proving ground for database
changes, email, uploads, and complete browser workflows.

### Completion criteria

- A new developer can obtain read-only ECR access through IAM Identity Center.
- The Docker Desktop onboarding guide works on macOS and Windows 11.
- A developer can pull an approved multi-architecture image and start the
  local stack without building the application image.
- Controlled database data and local runtime configuration are supplied without
  committing secrets.
- An Integration server can pull a specific image tag and restore approved test
  data.
- The team has a documented smoke test and an owner-approved path from
  Integration to Production.

### Relevant files

- [Developer AWS access setup](DEVELOPER_AWS_ACCESS_SETUP.md)
- [Developer Docker Desktop setup](DEVELOPER_DOCKER_DESKTOP_SETUP.md)
- [Owner proposal](OWNER_PROPOSAL.md)
- [Environment questionnaire](ENVIRONMENT.md)

## What remains beyond milestone 5

Milestones 1 through 4 are complete, and milestone 5 is the current platform
focus. Even after milestone 5, this will not yet be a complete production
platform. Important later boundaries remain:

- MariaDB is still a Compose container for development and integration work.
- Secrets are still supplied through an ignored runtime `.env` during the
  current workflow.
- Writable application data has not yet been fully externalized.
- There is not yet an Application Load Balancer or autoscaling group.
- Production deployment approvals and rollback automation remain future work.

Those are not failures of the completed milestones. They are the next
architectural steps, documented in the [production roadmap](PRODUCTION_ROADMAP.md).

## Study path from here

The most useful learning sequence follows the project’s actual progression:

1. Docker fundamentals: images, containers, volumes, networks, and Compose.
2. Linux service troubleshooting: logs, health checks, permissions, and disk
   usage.
3. Docker Buildx, manifests, registries, and image reproducibility.
4. GitHub Actions workflow syntax, artifacts, caches, and manual dispatch.
5. AWS IAM: principals, policies, trust relationships, and temporary roles.
6. GitHub OIDC for AWS, including claims and branch restrictions.
7. ECR lifecycle policies, image retention, and vulnerability scanning.
8. Secret management with SSM Parameter Store or Secrets Manager.
9. RDS, shared application storage, load balancing, and rollback design.

The most important practical lesson is that the project became safer by making
each responsibility explicit: source input, image build, image registry, runtime
configuration, database state, and AWS access are now separate concerns. That
separation is what makes the next environment possible without repeating the
original shared-server workflow.
