# Developer Docker Desktop Setup

This guide describes how a new developer can run the Laminas Safari application
from the prebuilt private ECR image on macOS or Windows 11 with Docker Desktop.

This is a developer onboarding workflow. It does not require the developer to
build or publish images, access EC2, or receive AWS credentials that can modify
infrastructure.

## Related AWS access guide

If AWS read-only ECR access has not yet been created, follow the [Developer AWS
Access Setup](DEVELOPER_AWS_ACCESS_SETUP.md) guide first. It explains how the
AWS administrator creates the developer’s sign-in and assigns permission to
pull the private image.

## Required access and files

Before beginning, request the following from the project maintainer or AWS
administrator:

1. AWS read-only access to the private ECR repository:

   ```text
   767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari
   ```

   The preferred organization setup is an AWS IAM Identity Center permission
   set or equivalent federated role with ECR pull permissions. Do not use the
   GitHub Actions publisher role or the EC2 instance role for local development.

2. The development database dump, transferred through the approved private
   channel:

   ```text
   input/horsesns_safari-dev.sql.gz
   ```

3. The current approved image tag, supplied by the project maintainer. Image
   tags are the full Git commit SHA of the deployment project. For example:

   ```text
   <deployment-project-commit-sha>
   ```

Do not request or copy production passwords, SMTP credentials, CAPTCHA secrets,
AWS access keys, or the production `.env` file.

## Choose a platform and install local tools

### macOS

Install Docker Desktop for Mac and start it. Apple Silicon Docker Desktop will
select the `linux/arm64` image from the multi-architecture ECR manifest.

Install AWS CLI version 2:

```sh
brew install awscli
aws --version
```

If Homebrew is not available, use the official AWS CLI installer instead:

<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

### Windows 11

Install Docker Desktop for Windows and enable the **WSL 2** backend. Install an
Ubuntu distribution through WSL 2 if it is not already available. Docker
Desktop’s WSL integration allows the Linux commands in this guide to work from
the Ubuntu terminal.

In Docker Desktop, open **Settings → Resources → WSL Integration** and enable
integration for the Ubuntu distribution you will use.

Install AWS CLI version 2 inside the Ubuntu/WSL terminal, using the Linux
installation instructions. Alternatively, install the official Windows AWS CLI
installer and run all AWS commands from PowerShell instead.

<https://docs.docker.com/desktop/setup/install/windows-install/>

<https://docs.docker.com/desktop/features/wsl/>

<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

For the most consistent experience, use the Ubuntu/WSL terminal for the rest of
this guide. Do not mix a Windows PowerShell AWS installation with an Ubuntu/WSL
AWS profile unless you deliberately configure both environments.

## Choose the local project directory

Choose one dedicated directory on the developer computer for this project. The
following uses `~/Projects` as an example; another directory is also fine.

On macOS, run these commands in Terminal. On Windows 11, run them in the
Ubuntu/WSL terminal:

If the repository is not already checked out:

```sh
mkdir -p ~/Projects
cd ~/Projects
git clone <repository-url> laminas-safari-deployment
cd laminas-safari-deployment
```

Replace `<repository-url>` with the repository URL supplied by the project
maintainer. If the repository is already checked out, change into its existing
directory instead.

All remaining commands in this guide should be run from the project root:

```text
~/Projects/laminas-safari-deployment
```

On Windows, this WSL path is separate from a normal Windows path such as
`C:\Users\YourName\Projects`. You can access the WSL files from Windows
Explorer through the WSL distribution, but keep the project in the WSL home
directory when following this guide.

## Configure AWS sign-in

The preferred sign-in method is AWS IAM Identity Center (AWS SSO), using the
profile supplied by the organization administrator:

```sh
aws configure sso --profile laminas-safari-dev
aws sso login --profile laminas-safari-dev
AWS_PROFILE=laminas-safari-dev aws sts get-caller-identity
```

The final command should identify the developer’s federated role and account.
It should not identify the GitHub Actions publisher role or an EC2 instance role.

If the organization has not enabled IAM Identity Center, stop and ask the AWS
administrator for the approved federated ECR-pull method. Do not create or store
long-lived AWS access keys just to pull this image.

## Authenticate Docker to ECR

From the project directory, log Docker into the private ECR registry:

```sh
AWS_PROFILE=laminas-safari-dev \
  aws ecr get-login-password --region us-east-1 |
  docker login \
    --username AWS \
    --password-stdin \
    767397722370.dkr.ecr.us-east-1.amazonaws.com
```

Pull the approved image:

```sh
docker pull \
  767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari:55489eae6729625304a3fb411226624c0fa0a5ab
```

Verify that Docker selected the image architecture appropriate for the computer:

```sh
docker image inspect \
  767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari:55489eae6729625304a3fb411226624c0fa0a5ab \
  --format '{{.Architecture}}'
```

The result should normally be `arm64` on an Apple Silicon Mac and `amd64` on a
standard x64 Windows 11 computer. Windows 11 on ARM may report `arm64`. The
published ECR image supports all of these listed platforms.

## Configure the local Compose environment

Copy the safe template and edit it:

```sh
cp .env.example .env
chmod 600 .env
vi .env
```

Set `APP_IMAGE` to the approved ECR image:

```dotenv
APP_IMAGE=767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari:55489eae6729625304a3fb411226624c0fa0a5ab
```

Set local development database values. These values must not be production
credentials. For email testing, use approved development SMTP credentials or
leave email configuration disabled according to the team’s local policy.

Confirm Compose resolves the intended image:

```sh
docker compose config --images
```

## Restore the development database and start the app

Place `horsesns_safari-dev.sql.gz` in the project’s `input/` directory, then run:

```sh
bash bin/restore-database.sh
docker compose up -d app
docker compose ps
curl --fail http://localhost/
```

Open <http://localhost/> in a browser. The database restore script starts the
MariaDB service and skips the restore if the schema is already present.

This prebuilt workflow does not use `run-local.sh`, `Dockerfile`, or Buildx.
Those are maintainer/CI tools for building images.

## Cleanup

After pulling, the Docker ECR token may remain in Docker’s local configuration.
Remove it when no more ECR pulls are needed:

```sh
docker logout 767397722370.dkr.ecr.us-east-1.amazonaws.com
```

The local image remains available after logout. Remove the development stack when
finished:

```sh
docker compose down
```

Use `docker compose down -v` only when intentionally deleting the local database
volume and all locally restored development data.

## Troubleshooting

- `aws: command not found`: install AWS CLI version 2.
- `Unable to locate credentials`: run `aws sso login --profile laminas-safari-dev`.
- `AccessDeniedException`: ask the AWS administrator to grant ECR pull access.
- `no basic auth credentials`: repeat the ECR `docker login` command.
- `no matching manifest`: verify Docker Desktop is running and the image tag is
  a published multi-architecture tag.
- `port is already allocated`: stop the process using port 80 or adjust the
  Compose port mapping for local use.
