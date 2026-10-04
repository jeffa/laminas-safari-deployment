# SMTP Deployment Patch

## Why this patch is needed

The Laminas application uses PHPMailer for password-reset messages. Its original
mailer configuration hard-coded SMTP port `25` and configured a separate SMTP
object without configuring PHPMailer’s main mail instance.

The EC2 deployment uses cPanel SMTP with these settings:

- Host: `mail.horses-n-stuff.com`
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
