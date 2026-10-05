# Developer AWS Access Setup

This guide creates a safe, read-only AWS sign-in for a developer who needs to
pull the Laminas Safari Docker image into Docker Desktop.

It is intended to be used with the [Developer Docker Desktop Setup](DEVELOPER_DOCKER_DESKTOP_SETUP.md)
guide. Developers do not need permission to
publish images, change EC2, modify databases, or administer AWS.

## What the administrator creates

The administrator enables AWS IAM Identity Center, creates a user, creates a
read-only ECR permission set, and assigns that permission set to the user for
the development AWS account.

Account-specific values are kept in:

```text
docs/aws/developer-access-settings.json
```

That file contains identifiers and configuration names only. It must not contain
passwords, access keys, invitation links, or secret values.

## Enable IAM Identity Center

1. Sign in to the AWS Console with an administrator identity.
2. Open **IAM Identity Center** in the same AWS region used by the project.
3. Choose **Enable**.
4. For this single-account development setup, choose **Enable an account
   instance** if AWS presents that choice.
5. Wait for the service to finish enabling.
6. On the IAM Identity Center dashboard, copy the **AWS access portal URL**.

The URL normally resembles:

```text
https://d-xxxxxxxxxx.awsapps.com/start
```

Record that URL in the local project data file under `sso_start_url`. The URL
is an identifier, not a password, but do not place invitation links or temporary
activation tokens in the repository.

AWS documents the account-instance setup here:

<https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html>

## Create or select the developer user

If you are testing this yourself, you can create an IAM Identity Center user
for your own business email address. Your AWS administrator identity and your
developer sign-in are separate roles; do not use the AWS root account for this
test.

1. In IAM Identity Center, open **Users**.
2. If your developer user already exists, select it. Otherwise choose **Add
   user**.
3. Enter the developer’s business email address and display name.
4. Send the invitation email when prompted.
5. The developer must accept the invitation and set their own password through
   the AWS access portal.

Do not share administrator passwords or create a shared developer account.

## Create the ECR pull permission set

1. Open **Permission sets**.
2. Choose **Create permission set**.
3. Choose a custom permission set.
4. Name it:

   ```text
   LaminasDeveloperEcrPull
   ```

5. Add the inline policy from:

   ```text
   docs/aws/ecr-puller-permissions-policy.json
   ```

6. Create the permission set.

This permission set permits authentication and image pulls only from the
project’s private ECR repository.

## Assign the permission set

1. Open **AWS accounts** in IAM Identity Center.
2. Select account `767397722370`.
3. Choose **Assign users or groups**.
4. Select the developer user.
5. Select `LaminasDeveloperEcrPull`.
6. Submit the assignment.

The developer can now use the AWS access portal and AWS CLI with temporary
credentials.

## Configure the developer’s iMac

Install AWS CLI version 2 if necessary:

```sh
brew install awscli
```

Configure the SSO profile:

```sh
aws configure sso --profile laminas-safari-dev
```

Use these values from `docs/aws/developer-access-settings.json`:

- SSO session name: `business-aws`
- SSO start URL: the IAM Identity Center access portal URL
- AWS account: `767397722370`
- Permission set: `LaminasDeveloperEcrPull`
- Profile name: `laminas-safari-dev`

Use the IAM Identity Center region shown in the AWS console for the SSO region.
It may be the same as the ECR region, but it should be copied from the actual
Identity Center configuration.

Sign in and verify the identity:

```sh
aws sso login --profile laminas-safari-dev
AWS_PROFILE=laminas-safari-dev aws sts get-caller-identity
```

Then continue with the ECR login and Docker Desktop instructions in the
[Developer Docker Desktop Setup](DEVELOPER_DOCKER_DESKTOP_SETUP.md) guide.

## What must never be committed

Do not commit any of the following:

- AWS passwords
- AWS access keys or secret access keys
- IAM Identity Center invitation links or activation tokens
- `.aws/credentials`
- Production `.env` files
- SMTP, database, CAPTCHA, or API secrets

The repository data file is safe only because it contains non-secret identifiers
and a placeholder for the portal URL.
