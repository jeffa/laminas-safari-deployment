# Developer Docker Desktop Setup

This guide describes how a new developer can run the Laminas Safari application
from the prebuilt private ECR image on an Apple Silicon Mac with Docker Desktop.

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

3. The current approved image tag. The first known-good tag is:

   ```text
   55489eae6729625304a3fb411226624c0fa0a5ab
   ```

Do not request or copy production passwords, SMTP credentials, CAPTCHA secrets,
AWS access keys, or the production `.env` file.

## Install local tools

Install Docker Desktop for Mac and start it. Apple Silicon Docker Desktop will
select the `linux/arm64` image from the multi-architecture ECR manifest.

Install AWS CLI version 2:

```sh
brew install awscli
aws --version
```

If Homebrew is not available, use the official AWS CLI installer instead:

<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

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

Verify that Docker selected the Apple Silicon image:

```sh
docker image inspect \
  767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari:55489eae6729625304a3fb411226624c0fa0a5ab \
  --format '{{.Architecture}}'
```

The result should be `arm64`.

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
