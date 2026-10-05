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

## Console orientation

This guide uses **IAM Identity Center**. Do not use the separate **IAM** service
menus for this setup. In particular, do not create an ordinary IAM user and do
not select an option named **Provide user access to the AWS Management Console**.
That is a different credential model.

The workflow has three separate objects:

1. An IAM Identity Center user, which is the person who signs in.
2. A permission set, which describes what that person may do.
3. An assignment connecting the user and permission set to AWS account
   `767397722370`.

AWS presents several policy and access choices on these screens. Use only the
choices explicitly identified below; leave the other choices empty.

## Enable IAM Identity Center

1. Sign in to the AWS Console with an administrator identity.
2. Open **IAM Identity Center** in the AWS region used by the project,
   preferably `us-east-1` for this setup.
3. Choose **Enable**.
4. If AWS asks which type of instance to create, choose an **organization
   instance**. We need permission sets so the developer can sign in to the AWS
   account and pull from ECR with the AWS CLI. An account instance is not the
   correct choice for this workflow.
5. If AWS asks for an instance name, use:

   ```text
   BridgeTechDynamics AWS
   ```

   This is only a display label and is not a password or credential.
6. Wait for the service to finish enabling.
7. On the IAM Identity Center dashboard, copy the **AWS access portal URL**.

The URL normally resembles:

```text
https://d-xxxxxxxxxx.awsapps.com/start
```

Record that URL in the project data file
`docs/aws/developer-access-settings.json` under `sso_start_url`. The URL
is an identifier, not a password, but do not place invitation links or temporary
activation tokens in the repository.

AWS documents IAM Identity Center instance choices here:

<https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-instances.html>

## Create or select the developer user

If you are testing this yourself, you can create an IAM Identity Center user
for your own business email address. Your AWS administrator identity and your
developer sign-in are separate roles; do not use the AWS root account for this
test.

1. In IAM Identity Center, open **Users**.
2. If your developer user already exists, select it. Otherwise choose **Add
   user**.
3. Enter the developer’s business email address and display name.
4. Leave group membership empty for this single-user setup. Groups are useful
   later when several developers need identical access.
5. Send the invitation email when prompted.
6. The developer must accept the invitation and set their own password through
   the AWS access portal.
7. Complete MFA enrollment when AWS requests it. An existing phone
   authenticator application is an acceptable **Authenticator app** choice.

Do not share administrator passwords or create a shared developer account.

## Create the ECR pull permission set

1. Open **Permission sets**.
2. Choose **Create permission set**.
3. Choose a custom permission set.
4. Name it:

   ```text
   LaminasDeveloperEcrPull
   ```

5. On the permissions screen, use **Inline policy** and add the policy from:

   ```text
   docs/aws/ecr-puller-permissions-policy.json
   ```

   Leave **AWS managed policies**, **Customer managed policies**, and
   **Permissions boundary** empty.
6. Choose **Create** to finish creating the permission set. Confirm it appears
   under **Permission sets** before continuing.

This permission set permits authentication and image pulls only from the
project’s private ECR repository.

## Assign the permission set

1. Open **AWS accounts** in IAM Identity Center.
2. Select account `767397722370`.
3. Choose **Assign users or groups**.
4. Select the developer user.
5. Choose **Next**. The permission-set screen appears after the user-selection
   screen; selecting the user alone does not complete the assignment.
6. Select `LaminasDeveloperEcrPull`.
7. Choose **Next** or **Submit**, depending on the button shown.

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
