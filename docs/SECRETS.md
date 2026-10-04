# Laminas configuration and secret handling

This guide explains how to remove database passwords and other environment-specific values from a Laminas application source package.

The goal is to keep reusable application code in the source archive while supplying credentials separately during deployment.

## Laminas configuration convention

Laminas MVC applications commonly load configuration files from `config/autoload/` in this order:

```text
global.php
*.global.php
local.php
*.local.php
```

Local files are loaded after global files, so they can override environment-specific values without changing shared application configuration.

Recommended layout:

```text
config/autoload/
├── global.php             # shared, non-secret defaults
├── local.php.dist         # safe example/template
└── local.php              # real local values; never package or commit
```

Laminas documents local configuration files as the appropriate place for credentials that should remain outside version control. See [Laminas default services](https://docs.laminas.dev/laminas-mvc/services/) and [advanced configuration](https://docs.laminas.dev/tutorials/advanced-config/).

## What belongs in each file

Shared configuration can go in `global.php`:

```php
<?php

return [
    'db' => [
        'driver' => 'Pdo',
    ],
];
```

Environment-specific values belong in `local.php` or another ignored local file:

```php
<?php

return [
    'db' => [
        'driver'   => 'Pdo',
        'dsn'      => 'mysql:dbname=horsesns_safari;host=db;charset=utf8mb4',
        'username' => getenv('DB_USER'),
        'password' => getenv('DB_PASSWORD'),
    ],
];
```

The exact configuration keys must match the application’s existing Laminas database adapter configuration. Do not replace the current structure blindly; first compare the redacted existing `local.php` with the application’s `global.php` and service configuration.

## Safe template

Create `config/autoload/local.php.dist` for developers and deployment documentation:

```php
<?php

return [
    'db' => [
        'driver'   => 'Pdo',
        'dsn'      => 'mysql:dbname=horsesns_safari;host=CHANGE_ME;charset=utf8mb4',
        'username' => 'CHANGE_ME',
        'password' => 'CHANGE_ME',
    ],
];
```

The template must contain placeholders only. Never put a real development, staging, or production password in it.

## Keep local configuration out of the source archive

Before creating the application tarball, exclude local configuration and other secret-bearing files:

```bash
tar \
  --exclude='config/autoload/local.php' \
  --exclude='.env' \
  --exclude='*.log' \
  -czf laminas-app.tar.gz .
```

Verify that the sensitive file is absent:

```bash
tar -tzf laminas-app.tar.gz | grep 'config/autoload/local.php'
```

The command should produce no output.

Also inspect the archive contents for likely secret files:

```bash
tar -tzf laminas-app.tar.gz | \
  grep -Ei '(^|/)(\.env|.*secret.*|.*credential.*|.*password.*|.*\.pem|.*\.key)$'
```

Do not include `vendor/`, caches, logs, database dumps, editor settings, or backups unless the application specifically requires them.

## Docker Compose deployment

The preferred container design is to keep credentials in an untracked `.env` file on the deployment host:

```dotenv
DB_HOST=db
DB_NAME=horsesns_safari
DB_USER=horsesns_safari
DB_PASSWORD=temporary-development-password
```

Protect the file:

```bash
chmod 600 .env
```

Supply the values to the application container:

```yaml
services:
  app:
    environment:
      DB_HOST: ${DB_HOST}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
```

Inside the Docker network, the database hostname is the Compose service name, such as `db`. It is not `localhost`, the EC2 public IP, or the database container’s changing private IP.

## Generating `local.php` at deployment time

If the application expects database settings in `config/autoload/local.php`, generate that file on the deployment host rather than putting it in the image or source tarball.

For example, create it from a deployment-controlled template or configuration-management task and mount it into the container:

```yaml
services:
  app:
    volumes:
      - ./runtime-config/local.php:/var/www/html/config/autoload/local.php:ro
```

The `runtime-config/local.php` file must be untracked and protected:

```bash
chmod 600 runtime-config/local.php
```

An alternative is to create the file during container startup from environment variables. A bind-mounted read-only file is simpler to inspect and avoids placing secrets in a Docker image layer.

## Configuration cache

Laminas applications may cache merged configuration. After creating or changing local configuration, clear the cache using the command defined by the application. For the supplied skeleton application:

```bash
docker compose exec app php bin/clear-config-cache.php
```

If the application uses development mode, confirm whether configuration caching is disabled there. Clear the cache whenever database configuration changes.

## Database dump handling

Database dumps are separate from application source and may contain sensitive data even when they come from development. Keep them outside Git and outside the source tarball:

```gitignore
*.sql
*.sql.gz
```

Before importing a dump, inspect for database-level credentials or grants:

```bash
gzip -dc database-dump.sql.gz | \
  grep -Ei 'CREATE USER|IDENTIFIED BY|GRANT |DEFINER='
```

Use temporary database credentials in the lab. Do not restore production users, grants, or passwords into a disposable environment.

## Secret-handling checklist

- [ ] The real `config/autoload/local.php` is excluded from Git.
- [ ] The real `config/autoload/local.php` is excluded from the source tarball.
- [ ] `local.php.dist` contains placeholders only.
- [ ] `.env` files are ignored and absent from the archive.
- [ ] Database dumps are stored separately from source code.
- [ ] Development credentials are different from production credentials.
- [ ] The Docker image contains no passwords or private keys.
- [ ] Runtime configuration files are permission-restricted.
- [ ] Configuration cache is cleared after changes.
- [ ] Logs and error output have been checked for credentials.
- [ ] Any credential that was previously committed has been rotated.

## Recommended handoff

The backend developer should provide:

1. A redacted copy of the current `config/autoload/local.php` structure.
2. The corresponding shared configuration from `global.php` if it affects the database adapter.
3. The names of the environment variables or configuration keys the application can consume.
4. The required PHP extensions and startup/cache commands.

They should not provide passwords or API keys in the repository, tarball, questionnaire, or chat.
