# SMTP Deployment Patch

## Why this patch is needed

The Laminas application uses PHPMailer for password-reset messages. Its original
mailer configuration hard-coded SMTP port `25` and configured a separate SMTP
object without configuring PHPMailer’s main mail instance.

The EC2 deployment uses cPanel SMTP with these settings:

- Host: the environment-specific cPanel SMTP hostname
- Port: `465`
- Encryption: implicit SSL/TLS
- Authentication: the configured `EMAIL_ADDRESS` and `EMAIL_PASSWORD`

Without the patch, the application attempted to connect using PHPMailer’s
default connection settings and failed with `Connection refused`. A direct
SMTP test from the same container succeeded, proving that AWS networking,
security groups, credentials, and cPanel delivery were not the cause.

## What the patch changes

`patches/email-smtp.patch` currently:

1. Reads the SMTP host, port, and encryption mode from environment constants.
2. Supports port `465`/implicit SSL and STARTTLS configurations.
3. Applies the connection settings to PHPMailer’s main mail instance.
4. Propagates a PHPMailer send error into the existing application error path.

Verbose SMTP transcript logging was used during diagnosis and has been removed.
Do not enable it in a normal deployment because message bodies may contain reset
links and tokens.

## How the Docker build applies it

The Dockerfile copies the patch into the build context and applies it after the
application source is installed:

```sh
patch -p1 < /tmp/email-smtp.patch
```

The patch can be validated against the source archive without modifying the
working tree:

```sh
tmp_dir=$(mktemp -d /tmp/laminas-mail-verify.XXXXXX)
tar -xzf input/laminas-app.tar.gz -C "$tmp_dir" --strip-components=1
(cd "$tmp_dir" && patch --dry-run -p1 < "$OLDPWD/patches/email-smtp.patch")
```

To rebuild the Compose application image:

```sh
docker compose -f compose.yaml -f compose.build.yaml build app
docker compose up -d app
```

SMTP credentials must come from the environment or `.env`; they must not be
stored in this document, the patch, the Docker image, or source control.

## Follow-up work

This is a deployment-side patch on the experimental SMTP branch. The confirmed
connection fix should be applied and tested in the existing DEV application
source before the next production deployment cycle. Once the source contains
the fix, remove the corresponding hunk from `patches/email-smtp.patch` and keep
only any deployment-specific configuration that remains necessary.

## Applying the fix to the existing DEV source

This section is for the backend developer who maintains the existing DEV
application. Apply the change to a source checkout or protected copy first; do
not experiment directly against a live Production source directory.

### 1. Confirm the source version

The patch was created against the Laminas application source archive used by
this project. From the application source root, confirm these files exist:

```sh
test -f module/Application/src/Model/ModelPhpMailer.php
test -f module/Application/src/Model/ModelAccounts.php
```

If the DEV source is maintained in Git, create a feature branch and confirm the
working tree is clean:

```sh
git status --short
git switch -c fix/laminas-smtp-settings
```

If it is not maintained in Git, make a protected backup before continuing.

### 2. Transfer the patch

Copy `patches/email-smtp.patch` from this project to the DEV host or place it
beside the source checkout. It contains code only, not SMTP passwords.

For example:

```sh
scp patches/email-smtp.patch \
  DEV_USER@DEV_HOST:/temporary/private/email-smtp.patch
```

Use a protected temporary directory and remove the patch after applying it if
the DEV host is shared.

### 3. Dry-run before changing files

Change to the application source root—the directory containing `module/`—and
run:

```sh
patch --dry-run -p1 < /temporary/private/email-smtp.patch
```

The expected result is that all patch sections apply successfully. A dry-run
makes no source changes. If it reports failed hunks, stop and compare the DEV
source version with the source archive; do not force the patch.

### 4. Apply and inspect the patch

After a successful dry-run:

```sh
patch -p1 < /temporary/private/email-smtp.patch
```

If the source is in Git, inspect the changes immediately:

```sh
git diff -- module/Application/src/Model/ModelPhpMailer.php \
  module/Application/src/Model/ModelAccounts.php
```

The patch configures the SMTP host, port, encryption, and credentials on
PHPMailer’s main mail instance. It also propagates mail-send errors into the
existing application error path.

Do not apply the patch a second time. A source tree that already contains these
changes should reject the patch.

### 5. Verify PHP and runtime configuration

Run syntax checks:

```sh
php -l module/Application/src/Model/ModelPhpMailer.php
php -l module/Application/src/Model/ModelAccounts.php
```

Confirm the DEV runtime configuration supplies these values without displaying
the password:

```text
EMAIL_ADDRESS
EMAIL_PASSWORD
EMAIL_SERVER_HOST
EMAIL_SERVER_PORT=465
EMAIL_SERVER_ENCRYPTION=ssl
```

The password must remain in protected DEV configuration. Never put it in source
files, the patch, Git history, or chat.

### 6. Deploy and clear configuration cache

Use the existing DEV deployment procedure to publish the changed source. Then
clear the Laminas configuration cache. For this project’s container:

```sh
docker compose exec app php bin/clear-config-cache.php
```

If DEV is not containerized, use its normal cache-clearing procedure.

### 7. Test the complete workflow

Using a registered DEV account:

1. Submit the forgot-password form.
2. Confirm the reset email arrives.
3. Follow the reset link.
4. Set a new password.
5. Log in with the new password.
6. Check cPanel Track Delivery for the message.

Do not enable verbose SMTP transcript logging on a shared or Production server;
SMTP transcripts can contain reset links and tokens.

### 8. Commit the source fix and retire the duplicate hunk

After DEV validation, commit the application-source change through the normal
backend review process. Keep this deployment patch until the updated source is
included in a new image and verified.

After that, remove the duplicate application-source hunk from
`patches/email-smtp.patch`. Keep deployment-only configuration changes if the
application source does not own those settings. Re-run the patch dry-run against
the next source archive before publishing another image.
