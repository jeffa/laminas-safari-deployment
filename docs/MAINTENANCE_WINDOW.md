# Application Maintenance Window

The application image includes a maintenance page and Apache rewrite rules.
During a maintenance window, requests are redirected internally to the
maintenance handler, which returns HTTP `503 Service Unavailable` and a
`Retry-After` header.

The container image uses `/var/www/html/public` as its document root. This is
different from the shared DEV server, whose `.htaccess` serves the project root.
The deployment image therefore places the maintenance handler inside the
container's public document root and does not use the DEV server's hard-coded
`/home/horsesns/public_html/safari2` path.

## Enable maintenance mode

From the deployment project directory on the host:

```bash
docker compose exec app sh -c 'touch /var/www/html/.maintenance'
```

Confirm that the application responds with HTTP 503:

```bash
curl -i http://localhost/
```

The response should include:

```text
HTTP/1.1 503 Service Unavailable
Retry-After: 300
```

The maintenance page remains available, and files under `/newsletter/` remain
available so the page can load its local assets.

## Disable maintenance mode

```bash
docker compose exec app sh -c 'rm -f /var/www/html/.maintenance'
```

Then verify normal application routing:

```bash
curl --fail http://localhost/
```

## Important operational notes

- The marker is inside the running application container.
- It is intentionally not stored in the source repository or image.
- Recreating the application container removes the marker and returns the
  application to normal mode.
- Do not use `docker compose down -v` for a maintenance window; that removes
  the local database volume.
- The maintenance rules are safe for the container's `/public` document-root
  layout and should not be copied unchanged to the shared DEV server.
