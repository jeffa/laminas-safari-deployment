# Laminas application on Docker: disposable EC2 lab

This guide uses the existing EC2 laboratory to run a Laminas/PHP application and MariaDB for short-lived testing. Terraform creates the Ubuntu instance, Ansible installs Docker, and Docker Compose runs the application and database.

The intended flow is:

```text
Terraform → Ubuntu EC2 → Ansible installs Docker
                         ↓
              Docker Compose: app + MariaDB
                         ↓
              restore source tarball + database dump
```

This is a test environment, not a production deployment. Do not expose MariaDB publicly, do not commit secrets, and destroy the instance when the test is complete.

## Before starting

You need:

- a source-code tarball for the application
- a MariaDB/MySQL-compatible SQL dump
- the PHP version used by the application
- the MariaDB version used by the application, if known
- the application's required PHP extensions
- the Laminas document root, normally `public/`
- the application's database and environment-variable configuration

The EC2 security groups should allow TCP 22 only from your IP address and TCP 80 from wherever you will test the application. Do not open TCP 3306.

## Provisioning decisions from `composer.json`

The supplied application dependency file establishes the following starting configuration:

- use PHP 8.2; the application allows PHP 8.1, 8.2, and 8.3
- use the normal Laminas `public/` document root
- enable the `pdo_mysql` PHP extension for `laminas-db` and MariaDB access
- install production dependencies without the development/test packages
- allow Composer's post-install script to clear Laminas' merged configuration cache
- do not use the application's `serve` script for the EC2 deployment; it starts PHP's development server on port 8080

The dependency file does not identify the application's actual database configuration or credentials. Before starting the containers, locate the Laminas configuration files that define the database adapter and determine how environment-specific values are loaded. The container should receive those values through environment variables or an untracked local configuration file, not through source code or the Docker image.

## Create the EC2 host

Use the existing Terraform project with one Ubuntu server:

```bash
terraform init
terraform validate
terraform plan -var='servers=["ubuntu"]' -out=run.tfplan
terraform apply run.tfplan
terraform output
```

Install Docker using the existing Ansible playbook after Terraform has generated the inventory:

```bash
ansible all -i ansible-hosts -m ping
ansible-playbook -i ansible-hosts ansible/docker.yaml
```

SSH to the instance and verify Docker:

```bash
ssh ubuntu@YOUR_EC2_PUBLIC_IP
docker version
docker compose version
```

On Ubuntu images using the distribution Docker packages, the Compose v2 package is `docker-compose-v2`. The Ansible Docker playbook installs and verifies it automatically. Red Hat-family images are currently treated as Docker-only compatibility cases because their repositories do not consistently provide the required Compose package.

## Prepare the application directory

On the EC2 host:

```bash
mkdir -p ~/laminas-lab/app ~/laminas-lab/import
cd ~/laminas-lab
```

From the development computer, copy the source and database dump:

```bash
scp laminas-app.tar.gz ubuntu@YOUR_EC2_PUBLIC_IP:~/laminas-lab/import/
scp database-dump.sql.gz ubuntu@YOUR_EC2_PUBLIC_IP:~/laminas-lab/import/
```

Extract the source on the EC2 host. Adjust the archive name and strip level if the tarball has a top-level directory:

```bash
tar -xzf ~/laminas-lab/import/laminas-app.tar.gz -C ~/laminas-lab/app --strip-components=1
```

Do not include `.env` files, production credentials, cache directories, or local dependency directories in the tarball unless the application specifically requires them.

## Create the Docker image

Create `~/laminas-lab/app/Dockerfile`:

```dockerfile
FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN a2enmod rewrite \
    && sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf

# MariaDB access requires the PDO MySQL driver. Add any other extensions
# required by this application below, such as intl, mbstring, or opcache.
RUN docker-php-ext-install pdo_mysql
# RUN docker-php-ext-install intl mbstring opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY . .

RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
RUN chown -R www-data:www-data /var/www/html
```

The application may require additional system libraries, PHP extensions, or a different web-server configuration. Confirm those requirements from the application source and production environment before building the image. If the source includes `composer.lock`, keep it with the source tarball so Composer installs the tested dependency versions. The `--no-dev` flag excludes PHPUnit, Psalm, code-style tools, and other development-only packages from the runtime image.

The `public/` document root is the normal Laminas arrangement. If this application uses another document root, change `APACHE_DOCUMENT_ROOT` and the Apache configuration accordingly.

## Create Docker Compose configuration

Create `~/laminas-lab/compose.yaml`:

```yaml
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: ${DB_NAME}
      MARIADB_USER: ${DB_USER}
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 10

  app:
    build:
      context: ./app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "80:80"
    environment:
      APP_ENV: ${APP_ENV:-development}
      DB_HOST: db
      DB_PORT: 3306
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}

volumes:
  db-data:
```

The exact environment-variable names must match the Laminas application's configuration. The database hostname inside Compose is `db`, not `localhost` and not the EC2 public IP. The placeholder `DB_*` variables above are not automatically used by Laminas unless the application configuration reads those names; update either the Compose environment section or the application configuration as needed.

Create `~/laminas-lab/.env` with temporary values:

```dotenv
APP_ENV=development
DB_NAME=horsesns_safari
DB_USER=horsesns_safari
DB_PASSWORD=replace-with-a-temporary-password
DB_ROOT_PASSWORD=replace-with-a-different-temporary-password
```

Protect the file and keep it out of Git:

```bash
chmod 600 .env
```

## Build and start the application

From `~/laminas-lab`:

```bash
docker compose build
docker compose up -d
docker compose ps
docker compose logs -f app
```

Visit:

```text
http://YOUR_EC2_PUBLIC_IP/
```

Useful checks:

```bash
curl -I http://YOUR_EC2_PUBLIC_IP/
docker compose logs app
docker compose logs db
docker compose exec app php -v
docker compose exec app composer check-platform-reqs
```

## Restore the database dump

Start the database and wait until it is healthy:

```bash
docker compose up -d db
docker compose ps
```

Load the Compose variables into the current shell so the import commands can use them:

```bash
set -a
. ./.env
set +a
```

For an uncompressed SQL dump:

```bash
docker compose exec -T db mariadb \
  -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
  < ~/laminas-lab/import/database-dump.sql
```

For a gzip-compressed dump:

```bash
gzip -dc ~/laminas-lab/import/database-dump.sql.gz | \
  docker compose exec -T db mariadb \
    -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
```

If the dump contains `CREATE DATABASE`, `USE`, or users from the original environment, inspect it first and adapt the import command. Do not blindly restore production credentials or grants into the lab.

After importing, restart the application and clear any application cache using the command defined by the project:

```bash
docker compose restart app
docker compose exec app php bin/clear-config-cache.php
```

## Application-specific items to confirm

Before calling the environment complete, compare the lab with the real application:

- PHP minor version and required extensions
- Composer version and lock file
- MariaDB version and SQL modes
- database host, port, name, and character set
- Laminas environment configuration
- writable directories for cache, logs, uploads, and generated files
- Apache rewrite rules or the production web-server configuration
- background workers, cron jobs, queues, or external services
- filesystem paths referenced by uploaded files or application configuration

If the application requires writable directories, declare them explicitly in Compose rather than making the entire source tree writable. For example, add a named volume only for the required runtime directory.

## Cleanup

Stop the containers while preserving the database volume:

```bash
docker compose down
```

Remove the containers and database data too:

```bash
docker compose down -v
```

When the test is finished, destroy the Terraform-managed EC2 instance:

```bash
terraform destroy
```

The database volume and the copied source exist only on the EC2 instance. Export anything needed before destroying it.

## Troubleshooting

```bash
docker compose ps
docker compose logs --tail=100 app
docker compose logs --tail=100 db
docker compose exec app php -m
docker compose exec app ls -la public
docker compose exec db mariadb-admin ping -u"$DB_USER" -p"$DB_PASSWORD"
sudo ss -ltnp | grep ':80'
```

Common causes of failure are a PHP extension missing from the image, a document-root mismatch, database settings still pointing at `localhost`, an incompatible MariaDB version, or a missing writable directory.
