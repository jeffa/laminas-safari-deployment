# Developer Environment Project — Hand-off Specification

## Purpose

Create a separate project that gives each developer an isolated, repeatable
Laminas Safari development environment.

The developer environment must allow a developer to work on application code,
run the application locally, use a private local database, and recover from
failed experiments without affecting another developer, the shared DEV server,
Integration, or Production.

This project is intentionally separate from
`laminas-safari-deployment`. The deployment project builds and publishes
immutable application images. This project owns the editable developer
experience.

## Project boundary

### This project should own

- Developer Docker Desktop setup on macOS and Windows 11.
- A local editable application source checkout.
- Local PHP/Apache and MariaDB orchestration.
- Database reset and seed workflows.
- Developer-safe environment configuration.
- Local logs, debugging helpers, and common troubleshooting commands.
- Optional developer overrides for mounting source code into the container.
- Onboarding documentation for a new developer.

### `laminas-safari-deployment` continues to own

- The production application Dockerfile.
- The multi-architecture GitHub Actions workflow.
- Private ECR image publishing.
- Immutable deployment-project commit-SHA image tags.
- EC2, Integration, and Production deployment procedures.
- Deployment runtime configuration contracts.
- Release approval and rollback documentation.

The developer project may consume an approved ECR image, but editable source
development should not require modifying the production image project.

## Starting point

The deployment project has already demonstrated:

- Laminas running in Docker with a separate MariaDB container.
- Development database restoration.
- Multi-architecture images for `linux/amd64` and `linux/arm64`.
- Private ECR publishing and authorized image pulls.
- Docker Desktop operation on an Apple Silicon iMac.
- A successful password-reset email and login smoke test.

The deployment project also contains useful reference material:

- `docs/DEVELOPER_DOCKER_DESKTOP_SETUP.md`
- `docs/DEVELOPER_AWS_ACCESS_SETUP.md`
- `docs/SECRETS.md`
- `docs/ENVIRONMENT.md`
- `docs/OWNER_PROPOSAL.md`

Copy or link to those documents as appropriate. Do not copy secrets or ignored
payloads into the new repository.

## Required developer experience

A new developer should be able to:

1. Clone the developer-environment repository.
2. Install Docker Desktop and the required command-line tools.
3. Obtain approved access to the private ECR image if the workflow uses ECR.
4. Obtain the approved development source and database payload privately.
5. Copy a safe environment template.
6. Start the local stack with one documented command.
7. Open the application in a browser.
8. Edit application source on the host and see changes locally.
9. Inspect application and database logs.
10. Reset the database and local writable data safely.
11. Stop, remove, and recreate the environment without affecting anyone else.

The guide should distinguish clearly between commands run on the host and
commands run inside a container.

## Recommended local layout

Use a predictable project directory, such as:

```text
~/Projects/laminas-safari-dev/
```

The repository should keep local-only material outside Git or in ignored paths:

```text
laminas-safari-dev/
├── app/                  # editable application source, ignored if supplied locally
├── input/                # private database dump or approved fixtures
├── compose.yaml
├── compose.override.yaml # optional developer overrides
├── .env.example
└── docs/
```

The exact layout may change, but the source, database data, runtime values, and
generated files must have clear ownership.

## Source workflow decision

The new project should explicitly choose one of these supported workflows:

### Editable source workflow — recommended

The developer checks out or extracts application source and mounts it into the
runtime container. This is the correct workflow for writing and testing code.

The project must document:

- Composer dependency installation.
- File ownership and permissions.
- Configuration and cache clearing.
- Apache document root behavior.
- How source edits become visible without rebuilding the production image.

### Approved-image workflow — optional

The developer pulls a tagged image from private ECR. This is useful for
reproducing Integration or Production behavior, but it is not a substitute for
editable source development.

The image tag must be supplied explicitly. Do not use `latest` for a test that
needs to be reproducible.

## Database safety

The developer environment must use a private local database. It must never
connect to the Production database by default.

Document:

- How the approved development dump is obtained.
- How the database is restored.
- How the database is reset.
- Whether the dump contains personal or sensitive information.
- What sanitization is required before distribution.
- How database schema changes are tested and discarded.

The reset operation must require an explicit command and must clearly identify
the local container or volume it will affect.

## Secrets and configuration

Never commit:

- `.env` files containing values.
- SMTP passwords.
- CAPTCHA secrets.
- AWS access keys.
- Private keys.
- Production database credentials.
- Production application secrets.

Commit only safe templates and variable names. Development secrets should be
provided through an approved private channel or local secret-management
process.

The developer project should make it difficult to accidentally use Production
values. Prefer clearly named development variables and safe defaults.

## Suggested project milestones

### Developer milestone 1: Project scaffold

- Create the repository.
- Add Compose files and `.env.example`.
- Add `.gitignore` and secret-safety guidance.
- Document supported macOS and Windows 11 workflows.

### Developer milestone 2: Local editable application

- Mount application source into the runtime container.
- Install or verify Composer dependencies.
- Serve the Laminas application locally.
- Document cache clearing and file permissions.

### Developer milestone 3: Local database lifecycle

- Start MariaDB locally.
- Restore approved development data.
- Add reset and re-seed commands.
- Verify application/database connectivity.

### Developer milestone 4: Developer onboarding

- Add a short new-hire setup guide.
- Add common commands for start, stop, logs, shell access, and reset.
- Add troubleshooting for ports, permissions, disk space, and architecture.
- Verify the process on a clean developer computer.

### Developer milestone 5: Optional approved-image comparison

- Allow a developer to pull a specific ECR image tag.
- Run the approved image beside or instead of the editable source workflow.
- Document the difference between editing source and testing a packaged image.

## Definition of done

The developer-environment project is ready for team use when a new developer
can complete the workflow without administrator access to AWS infrastructure or
the shared DEV server, and can demonstrate:

- A working local application.
- A working local database.
- An editable source change visible in the browser.
- A safe database reset.
- Useful logs and shell access.
- No production credentials in the repository or image.
- A clean teardown and recreation.

## First task for the new repository

Begin by copying this hand-off document into the new repository as its initial
design document. Then answer these questions before implementing scripts:

1. Will application source be cloned from a private source repository, supplied
   as an archive, or both?
2. What development database data may be distributed to developers?
3. Which SMTP and third-party services may be called locally?
4. Will developers use ECR images, editable source containers, or both?
5. Which ports and local URLs should be standardized?
6. What is the approved process for resetting local data?

Do not begin by copying the Production `.env` or the entire deployment project.
Define the local developer contract first, then implement the smallest
repeatable workflow that satisfies it.

